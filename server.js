require('dotenv').config();
const express = require('express');
const path = require('path');
const { Pool } = require('pg');
const { runMigration, getConnectionString } = require('./migrate');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json({ limit: '1mb' }));
app.use(express.static(path.join(__dirname)));

const connectionString = getConnectionString();
let pool = null;

if (connectionString) {
    pool = new Pool({
        connectionString,
        ssl: connectionString.includes('localhost') || connectionString.includes('127.0.0.1')
            ? false
            : { rejectUnauthorized: false }
    });

    pool.on('error', (err) => {
        console.error('[DB] Error inesperado en el pool de PostgreSQL:', err);
    });
} else {
    console.warn('[DB] ⚠️ DATABASE_URL no encontrada. Configúrala en las variables de entorno de Railway o en un archivo .env.');
}

// Auto-verificación y migración al arrancar si la base de datos está conectada
async function initDatabase() {
    if (!pool) return;
    try {
        const client = await pool.connect();
        try {
            const tableCheck = await client.query(`
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' AND table_name = 'axes'
                ) as exists;
            `);

            if (!tableCheck.rows[0].exists) {
                console.log('[DB] La base de datos no contiene las tablas. Ejecutando migración inicial...');
                await runMigration(pool);
            } else {
                // Verificar si hay ejes cargados
                const countCheck = await client.query('SELECT COUNT(*) FROM axes;');
                if (parseInt(countCheck.rows[0].count, 10) === 0) {
                    console.log('[DB] Tablas detectadas pero vacías. Cargando datos iniciales...');
                    await runMigration(pool);
                } else {
                    console.log('[DB] ✅ Conexión a PostgreSQL establecida y datos listos.');
                }
            }
        } finally {
            client.release();
        }
    } catch (err) {
        console.error('[DB] ❌ No se pudo conectar a PostgreSQL al iniciar:', err.message);
    }
}

initDatabase();

// Middleware para verificar disponibilidad de DB
function checkDb(req, res, next) {
    if (!pool) {
        return res.status(503).json({
            error: 'Base de datos no configurada. Asegúrate de definir DATABASE_URL en Railway.'
        });
    }
    next();
}

// --- Endpoints API ---

// Healthcheck
app.get('/api/health', async (req, res) => {
    if (!pool) {
        return res.json({ status: 'ok', database: 'disconnected (missing DATABASE_URL)' });
    }
    try {
        await pool.query('SELECT 1;');
        res.json({ status: 'ok', database: 'connected' });
    } catch (err) {
        res.status(500).json({ status: 'error', database: err.message });
    }
});

// Endpoint principal: datos completos del quiz en una sola llamada
app.get('/api/quiz-data', checkDb, async (req, res) => {
    try {
        const [axesRes, questionsRes, candidatesRes] = await Promise.all([
            pool.query('SELECT id, name, pole_negative, pole_positive, weight FROM axes ORDER BY id;'),
            pool.query('SELECT id, axis_id, code, statement, pole_direction FROM questions ORDER BY id;'),
            pool.query(`
                SELECT 
                    c.id, c.name, c.party, c.profile, c.bio, c.campaign_url,
                    c.photo_url, c.party_logo_url, c.profile_pic_url,
                    COALESCE(
                        json_agg(
                            json_build_object('axis_id', cp.axis_id, 'score', cp.score)
                        ) FILTER (WHERE cp.axis_id IS NOT NULL),
                        '[]'
                    ) AS candidate_positions
                FROM candidates c
                LEFT JOIN candidate_positions cp ON c.id = cp.candidate_id
                GROUP BY c.id
                ORDER BY c.id;
            `)
        ]);

        const axes = axesRes.rows.reduce((acc, ax) => {
            acc[ax.id] = ax;
            return acc;
        }, {});

        const questions = questionsRes.rows.map(q => ({
            id: q.id,
            axis_id: q.axis_id,
            code: q.code,
            text: q.statement,
            pole_direction: q.pole_direction
        }));

        const candidates = candidatesRes.rows.map(c => ({
            id: c.id,
            name: c.name,
            party: c.party,
            profile: c.profile,
            description: c.bio,
            campaignUrl: c.campaign_url,
            photo: c.photo_url,
            partyLogo: c.party_logo_url,
            profilePic: c.profile_pic_url,
            positions: Object.fromEntries(
                (c.candidate_positions || []).map(p => [String(p.axis_id), p.score])
            )
        }));

        res.json({ axes, questions, candidates });
    } catch (err) {
        console.error('[API] Error al obtener datos del quiz:', err);
        res.status(500).json({ error: 'Error al consultar la base de datos' });
    }
});

// Endpoints individuales compatibles
app.get('/api/axes', checkDb, async (req, res) => {
    try {
        const result = await pool.query('SELECT id, name, pole_negative, pole_positive, weight FROM axes ORDER BY id;');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/questions', checkDb, async (req, res) => {
    try {
        const result = await pool.query('SELECT id, axis_id, code, statement, pole_direction FROM questions ORDER BY id;');
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/candidates', checkDb, async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                c.id, c.name, c.party, c.profile, c.bio, c.campaign_url,
                c.photo_url, c.party_logo_url, c.profile_pic_url,
                COALESCE(
                    json_agg(
                        json_build_object('axis_id', cp.axis_id, 'score', cp.score)
                    ) FILTER (WHERE cp.axis_id IS NOT NULL),
                    '[]'
                ) AS candidate_positions
            FROM candidates c
            LEFT JOIN candidate_positions cp ON c.id = cp.candidate_id
            GROUP BY c.id
            ORDER BY c.id;
        `);
        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Guardar sesión y respuestas del quiz
const handleSubmitQuiz = async (req, res) => {
    try {
        const {
            p_user_agent,
            p_location_hint,
            p_responses,
            p_user_scores,
            p_results
        } = req.body;

        const userAgent = p_user_agent || req.headers['user-agent'] || '';
        const locationHint = p_location_hint || 'Anónimo';

        const result = await pool.query(
            'SELECT submit_quiz_session($1, $2, $3::jsonb, $4::jsonb, $5::jsonb) AS session_id;',
            [
                userAgent,
                locationHint,
                JSON.stringify(p_responses || []),
                JSON.stringify(p_user_scores || []),
                JSON.stringify(p_results || [])
            ]
        );

        const sessionId = result.rows[0].session_id;
        res.json(sessionId);
    } catch (err) {
        console.error('[API] Error al guardar respuestas del quiz:', err);
        res.status(500).json({ error: 'Error al registrar la sesión en la base de datos' });
    }
};

app.post('/api/submit-quiz-session', checkDb, handleSubmitQuiz);
app.post('/api/rpc/submit_quiz_session', checkDb, handleSubmitQuiz);

// Guardar comentario vinculado a la sesión
const handleSaveComment = async (req, res) => {
    try {
        const { p_session_id, p_comment } = req.body;
        if (!p_session_id || !p_comment) {
            return res.status(400).json({ error: 'Faltan parámetros obligatorios (p_session_id, p_comment)' });
        }

        await pool.query(
            'UPDATE sessions SET comment = $1 WHERE id = $2;',
            [p_comment, p_session_id]
        );

        res.json({ success: true });
    } catch (err) {
        console.error('[API] Error al guardar comentario:', err);
        res.status(500).json({ error: 'Error al registrar el comentario' });
    }
};

app.post('/api/save-session-comment', checkDb, handleSaveComment);
app.post('/api/rpc/save_session_comment', checkDb, handleSaveComment);

// Fallback para SPA (evitando colisionar con rutas /api/)
app.get('*', (req, res) => {
    if (req.path.startsWith('/api/')) {
        return res.status(404).json({ error: 'Endpoint no encontrado' });
    }
    res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});
