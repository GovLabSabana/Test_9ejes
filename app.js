// --- API Backend (PostgreSQL Nativo en Railway) ---
let lastResponseId = null; // guarda el id de la última respuesta guardada

const LIKERT_OPTIONS = [
    { value: 4, text: "Muy de acuerdo" },
    { value: 3, text: "Algo de acuerdo" },
    { value: 2, text: "Algo en desacuerdo" },
    { value: 1, text: "Muy en desacuerdo" }
];

async function saveResponse(answers, userScores, sortedCandidates) {
    try {
        const payload = {
            p_user_agent: navigator.userAgent,
            p_location_hint: userName || 'Anónimo',
            p_responses: Object.entries(answers).map(([qid, a]) => ({
                question_id: parseInt(qid),
                raw_answer: a.raw,
                normalized_score: a.normalized
            })),
            p_user_scores: Object.entries(userScores).map(([aid, score]) => ({
                axis_id: parseInt(aid),
                score: score
            })),
            p_results: sortedCandidates.map((c, i) => ({
                candidate_id: c.id,
                distance: c.distance,
                rank: i + 1
            }))
        };
        const response = await fetch('/api/submit-quiz-session', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (response.ok) {
            const data = await response.json();
            lastResponseId = data;
            console.log('[PostgreSQL] Respuesta guardada. ID:', lastResponseId);
            const btn = document.getElementById('feedback-submit-btn');
            if (btn) {
                btn.disabled = false;
                btn.textContent = 'Enviar comentario';
            }
        } else {
            const errText = await response.text();
            console.warn('[PostgreSQL] Error al guardar:', response.status, errText);
            const btn = document.getElementById('feedback-submit-btn');
            if (btn) btn.textContent = 'No disponible';
        }
    } catch (e) {
        console.warn('[PostgreSQL] Error inesperado:', e);
    }
}

async function saveComment(comment) {
    if (!lastResponseId) {
        console.warn('[PostgreSQL] No hay respuesta guardada a la que vincular el comentario.');
        return false;
    }
    try {
        const response = await fetch('/api/save-session-comment', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                p_session_id: lastResponseId,
                p_comment: comment
            })
        });
        return response.ok;
    } catch (e) {
        console.warn('[PostgreSQL] Error al guardar comentario:', e);
        return false;
    }
}
// --- Fin API Backend ---

// --- Compartir resultados ---
const MEDALS = ['🥇', '🥈', '🥉'];

function populateShareCard(top3) {
    const title = document.getElementById('share-card-title');
    const container = document.getElementById('share-card-candidates');
    title.textContent = userName
        ? `${userName}, estos son tus candidatos:`
        : 'Mis candidatos con mayor afinidad:';
    container.innerHTML = top3.map((c, i) => `
        <div class="share-candidate-row">
            <span class="share-medal">${MEDALS[i]}</span>
            <img src="${c.photo || ''}" class="share-candidate-photo" crossorigin="anonymous" onerror="this.style.display='none'">
            <div class="share-candidate-info">
                <span class="share-candidate-name">${c.name}</span>
                <span class="share-candidate-party">${c.party}</span>
            </div>
            <span class="share-pct">${c.percentage}%</span>
        </div>
    `).join('');
}

async function captureCard() {
    const card = document.getElementById('share-card');
    // Mostrar tarjeta temporalmente fuera de pantalla para capturarla
    card.style.position = 'fixed';
    card.style.left = '-9999px';
    card.style.top = '0';
    card.style.display = 'block';
    await new Promise(r => setTimeout(r, 150)); // esperar render de imágenes
    const canvas = await html2canvas(card, {
        backgroundColor: '#0f172a',
        scale: 2,
        useCORS: true,
        allowTaint: true,
        logging: false
    });
    card.style.display = 'none';
    card.style.position = '';
    card.style.left = '';
    card.style.top = '';
    return canvas;
}

async function captureAndDownload() {
    const btn = document.getElementById('btn-download');
    btn.textContent = 'Generando...';
    btn.disabled = true;
    try {
        const canvas = await captureCard();
        const link = document.createElement('a');
        link.download = `convergencia-electoral-${(userName || 'resultados').replace(/\s+/g, '-')}.png`;
        link.href = canvas.toDataURL('image/png');
        link.click();
    } finally {
        btn.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg> Descargar imagen`;
        btn.disabled = false;
    }
}

function getShareText(top3) {
    const names = top3.slice(0, 3).map((c, i) => `${MEDALS[i]} ${c.name} (${c.percentage}%)`).join(' ');
    const siteUrl = 'https://test-dilema-production.up.railway.app/';
    return userName
        ? `${userName} hizo el test Convergencia Electoral 2026 del Govlab de la Universidad de la Sabana 🗳️\n\nSus candidatos con mayor afinidad son:\n${names}\n\n¿Cuál es el tuyo? ${siteUrl}`
        : `Hice el test Convergencia Electoral 2026 🗳️\n\nMis candidatos con mayor afinidad:\n${names}\n\n¿Cuál es el tuyo? ${siteUrl}`;
}

async function shareToPlatform(platform, top3) {
    const text = getShareText(top3);
    const siteUrl = 'https://test-dilema-production.up.railway.app/';

    // Si estamos en un dispositivo móvil con Web Share API, es la forma nativa de enviar la imagen directamente a la app.
    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);

    if (isMobile && navigator.share && navigator.canShare) {
        try {
            const canvas = await captureCard();
            const blob = await new Promise(res => canvas.toBlob(res, 'image/png'));
            const file = new File([blob], 'convergencia-electoral.png', { type: 'image/png' });

            let shareText = text;
            if (platform === 'instagram') {
                shareText = "Toma pantalla o comparte tus resultados directamente 😎";
            }

            const shareData = { files: [file], title: 'Convergencia Electoral 2026', text: shareText };
            if (navigator.canShare(shareData)) {
                await navigator.share(shareData);
                return;
            }
        } catch (e) {
            console.warn("Error en Web Share API", e);
            if (e.name !== 'AbortError') captureAndDownload();
            return;
        }
    }

    // Comportamiento Desktop (o si Web Share no soporta archivos):
    // Como las páginas web no pueden adjuntar imágenes a URLs de Twitter/Facebook, descargamos la imagen primero.
    if (platform === 'native') {
        captureAndDownload();
        setTimeout(() => {
            alert("Tu imagen de resultados ha sido descargada. Compártela con tus amigos.");
            if (navigator.share) {
                navigator.share({ title: 'Convergencia Electoral 2026', text: '¿Cuál es tu candidato?', url: siteUrl }).catch(() => { });
            }
        }, 500);
        return;
    }

    try {
        await captureAndDownload();
        let url = '';

        if (platform === 'twitter') {
            url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}`;
        } else if (platform === 'facebook') {
            url = `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(siteUrl)}`;
        } else if (platform === 'whatsapp') {
            url = `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`;
        } else if (platform === 'instagram') {
            setTimeout(() => {
                alert("Tu imagen de resultados ha sido descargada.\n\nSúbela a tu perfil o historia de Instagram y etiqueta a @govlab_unisabana");
            }, 600);
            return;
        }

        if (url) {
            setTimeout(() => {
                const proceed = confirm(`Tu imagen ha sido descargada.\n\nAl continuar se abrirá ${platform}. ¡Asegúrate de adjuntar la imagen descargada a tu publicación!`);
                if (proceed) {
                    window.open(url, '_blank', 'noopener');
                }
            }, 600);
        }

    } catch (e) {
        console.error("Error al compartir", e);
    }
}
// --- Fin compartir ---

let quizData = null;
let currentQuestionIndex = 0;
let userAnswers = {};
let cameFromResults = false;
let userName = '';

const landing = document.getElementById('landing');
const nameScreen = document.getElementById('name-screen');
const quizScreen = document.getElementById('quiz-screen');
const resultsScreen = document.getElementById('results-screen');
const answersScreen = document.getElementById('answers-screen');

const startBtn = document.getElementById('start-btn');
const nameContinueBtn = document.getElementById('name-continue-btn');
const nameInput = document.getElementById('name-input');
const restartBtn = document.getElementById('restart-btn');
const viewAnswersBtn = document.getElementById('view-answers-btn');
const backToLandingBtn = document.getElementById('back-to-landing-btn');

const feedbackText = document.getElementById('feedback-text');
const feedbackSubmitBtn = document.getElementById('feedback-submit-btn');
const feedbackStatus = document.getElementById('feedback-status');
const feedbackCharCount = document.getElementById('feedback-char-count');

// Contador de palabras del textarea
feedbackText.addEventListener('input', () => {
    const text = feedbackText.value.trim();
    const words = text ? text.split(/\s+/).length : 0;
    feedbackCharCount.textContent = `${words} / 200 palabras`;

    if (words > 200) {
        feedbackCharCount.style.color = 'var(--danger, red)';
        feedbackSubmitBtn.disabled = true;
    } else {
        feedbackCharCount.style.color = '';
        feedbackSubmitBtn.disabled = false;
    }
});

// Enviar comentario
feedbackSubmitBtn.addEventListener('click', async () => {
    const text = feedbackText.value.trim();
    const words = text ? text.split(/\s+/).length : 0;

    if (!text) {
        feedbackStatus.textContent = '⚠️ Por favor escribe algo antes de enviar.';
        feedbackStatus.className = 'feedback-status error';
        return;
    }
    if (words > 200) {
        feedbackStatus.textContent = '⚠️ El comentario no puede exceder las 200 palabras.';
        feedbackStatus.className = 'feedback-status error';
        return;
    }
    feedbackSubmitBtn.disabled = true;
    feedbackSubmitBtn.textContent = 'Enviando...';
    const ok = await saveComment(text);
    if (ok) {
        feedbackStatus.textContent = '✅ ¡Gracias por tu comentario!';
        feedbackStatus.className = 'feedback-status success';
        feedbackText.value = '';
        feedbackCharCount.textContent = '0 / 200 palabras';
        feedbackSubmitBtn.textContent = 'Comentario enviado';
    } else {
        feedbackStatus.textContent = '❌ Error al enviar. Intenta de nuevo.';
        feedbackStatus.className = 'feedback-status error';
        feedbackSubmitBtn.disabled = false;
        feedbackSubmitBtn.textContent = 'Enviar comentario';
    }
});


const counter = document.getElementById('counter');
const progressBar = document.getElementById('progress-bar');
const contextTag = document.getElementById('context');
const questionText = document.getElementById('question-text');
const optionsContainer = document.getElementById('options');
const resultsList = document.getElementById('results-list');

const candidatesGrid = document.getElementById('candidates-grid');
const candidateDetailView = document.getElementById('candidate-detail-view');
const detailPhoto = document.getElementById('detail-photo');
const detailName = document.getElementById('detail-name');
const detailParty = document.getElementById('detail-party');
const detailProfile = document.getElementById('detail-profile');
const answersList = document.getElementById('answers-list');

// Load data desde la API nativa de PostgreSQL
async function init() {
    try {
        const response = await fetch('/api/quiz-data');
        if (!response.ok) throw new Error('Error al cargar datos del servidor');

        quizData = await response.json();
        console.log(`[PostgreSQL] Datos cargados: ${quizData.questions.length} preguntas, ${quizData.candidates.length} candidatos`);
    } catch (error) {
        console.error('[PostgreSQL] Error cargando datos:', error);
        alert('Error al cargar los datos. Por favor recarga la página.');
    }
}

function showNameScreen() {
    landing.classList.add('hidden');
    answersScreen.classList.add('hidden');
    resultsScreen.classList.add('hidden');
    nameScreen.classList.remove('hidden');
    nameScreen.classList.add('animate-in');
    nameInput.value = '';
    nameContinueBtn.disabled = true;
    setTimeout(() => nameInput.focus(), 300);
}

function startQuiz() {
    nameScreen.classList.add('hidden');
    quizScreen.classList.remove('hidden');
    quizScreen.classList.add('animate-in');
    currentQuestionIndex = 0;
    userAnswers = {};
    showQuestion();
}

// Habilitar botón Continuar solo si hay nombre
nameInput.addEventListener('input', () => {
    nameContinueBtn.disabled = nameInput.value.trim().length === 0;
});

// Presionar Enter en el input también continúa
nameInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && nameInput.value.trim().length > 0) {
        userName = nameInput.value.trim();
        startQuiz();
    }
});

nameContinueBtn.addEventListener('click', () => {
    userName = nameInput.value.trim();
    startQuiz();
});

function showAnswersScreen() {
    cameFromResults = false;
    landing.classList.add('hidden');
    answersScreen.classList.remove('hidden');
    answersScreen.classList.add('animate-in');
    candidateDetailView.classList.add('hidden');
    candidatesGrid.classList.remove('hidden');

    candidatesGrid.innerHTML = '';
    quizData.candidates.forEach(candidate => {
        const card = document.createElement('div');
        card.className = 'candidate-selector-card animate-in';

        card.innerHTML = `
            <img src="${candidate.photo || 'https://via.placeholder.com/80'}" alt="${candidate.name}">
            <h3>${candidate.name}</h3>
            <p style="margin-bottom: 8px;">${candidate.party}</p>
        `;
        card.onclick = () => showCandidateDetail(candidate);
        candidatesGrid.appendChild(card);
    });
}


function showCandidateDetail(candidate, fromResults = false) {
    cameFromResults = fromResults;
    if (fromResults) {
        resultsScreen.classList.add('hidden');
        answersScreen.classList.remove('hidden');
        answersScreen.classList.add('animate-in');
    }

    candidatesGrid.classList.add('hidden');
    candidateDetailView.classList.remove('hidden');
    candidateDetailView.classList.add('animate-in');

    // Use a default image if not found
    const detailPhotoPath = candidate.photo || 'https://via.placeholder.com/150?text=Candidato';
    const detailPartyPath = candidate.partyLogo || 'https://via.placeholder.com/60?text=P';
    detailPhoto.src = detailPhotoPath;
    detailName.innerText = candidate.name;
    detailParty.innerHTML = `<img src="${detailPartyPath}" style="height: 24px; vertical-align: middle; margin-right: 8px;"> ${candidate.party}`;
    detailProfile.innerHTML = '';

    // Campaign URL button
    const campaignBtn = document.getElementById('campaign-url-btn');
    if (candidate.campaignUrl) {
        campaignBtn.href = candidate.campaignUrl;
        campaignBtn.classList.remove('hidden');
    } else {
        // fallback: show button linking to a web search if no URL found
        campaignBtn.href = `https://www.google.com/search?q=${encodeURIComponent(candidate.name + ' candidato presidencia Colombia 2026')}`;
        campaignBtn.classList.remove('hidden');
    }


    // Inject profile description
    const profileTextContainer = document.getElementById('candidate-profile-text');
    if (profileTextContainer) {
        profileTextContainer.innerHTML = candidate.description ? candidate.description.split('\n\n').map(p => `<p>${p}</p>`).join('') : '';
    }

    answersList.innerHTML = `
        <div class="disclaimer-box animate-in">
            <i>⚠️</i>
            <p>Estas posiciones representan el análisis del <strong>GovLab</strong> frente a 9 ejes ideológicos y de política pública, comparadas con tus propias respuestas.</p>
        </div>
        <div class="axes-comparison"></div>
    `;

    const axesContainer = answersList.querySelector('.axes-comparison');

    if (quizData && quizData.axes) {
        Object.values(quizData.axes).forEach(ax => {
            const candScore = candidate.positions[ax.id] !== undefined ? candidate.positions[ax.id] : 0;
            const userScore = (cameFromResults && window.lastUserAxisScores) ? window.lastUserAxisScores[ax.id] : null;

            const candPct = ((candScore + 1) / 2) * 100;
            let userMarkerHtml = '';
            if (userScore !== null) {
                const userPct = ((userScore + 1) / 2) * 100;
                userMarkerHtml = `<div class="user-marker" style="left: ${userPct}%;" title="Tú"></div>`;
            }

            const item = document.createElement('div');
            item.className = 'axis-item animate-in';
            item.innerHTML = `
                <div class="axis-header">
                    <span class="axis-pole-negative">${ax.pole_negative}</span>
                    <span class="axis-name">${ax.name}</span>
                    <span class="axis-pole-positive">${ax.pole_positive}</span>
                </div>
                <div class="axis-bar-container">
                    <span class="axis-center-line"></span>
                    <div class="axis-track"></div>
                    <div class="cand-marker" style="left: ${candPct}%;">
                       ${candidate.photo ? `<img src="${candidate.photo}">` : ''}
                    </div>
                    ${userMarkerHtml}
                </div>
            `;
            axesContainer.appendChild(item);
        });
    }
}

function showQuestion() {
    const question = quizData.questions[currentQuestionIndex];

    counter.innerText = `Pregunta ${currentQuestionIndex + 1} de ${quizData.questions.length}`;
    progressBar.style.width = `${((currentQuestionIndex + 1) / quizData.questions.length) * 100}%`;

    const axis = quizData.axes[question.axis_id];
    contextTag.innerText = axis ? `Eje: ${axis.name}` : 'General';
    questionText.innerText = question.text;

    optionsContainer.innerHTML = '';

    LIKERT_OPTIONS.forEach((opt, index) => {
        const btn = document.createElement('button');
        btn.className = 'option-btn animate-in';
        btn.style.animationDelay = `${index * 0.1}s`;
        btn.innerText = opt.text;
        btn.onclick = () => selectOption(opt.value);
        optionsContainer.appendChild(btn);
    });
}

function selectOption(value) {
    const question = quizData.questions[currentQuestionIndex];
    // Normalizar a [-1, 1] y aplicar la dirección del polo
    const normalized = ((value - 2.5) / 1.5) * question.pole_direction;
    userAnswers[question.id] = { raw: value, normalized };

    if (currentQuestionIndex < quizData.questions.length - 1) {
        currentQuestionIndex++;
        showQuestion();
    } else {
        showResults();
    }
}

function showResults() {
    quizScreen.classList.add('hidden');
    resultsScreen.classList.remove('hidden');
    resultsScreen.classList.add('animate-in');

    // Personalizar título con el nombre del usuario
    const resultsTitle = document.getElementById('results-title');
    const resultsSubtitle = document.getElementById('results-subtitle');
    if (userName) {
        resultsTitle.textContent = `${userName}, estos son tus resultados`;
        resultsSubtitle.textContent = `Tienes más afinidad con los siguientes candidatos:`;
    } else {
        resultsTitle.textContent = 'Tus Resultados';
        resultsSubtitle.textContent = 'Este es el ranking de afinidad con los candidatos basado en tus respuestas:';
    }

    // Calculate user_axis_scores
    const axisSums = {};
    const axisCounts = {};
    Object.values(quizData.axes).forEach(ax => {
        axisSums[ax.id] = 0;
        axisCounts[ax.id] = 0;
    });

    Object.entries(userAnswers).forEach(([qId, ans]) => {
        const q = quizData.questions.find(x => x.id === parseInt(qId));
        if (q) {
            axisSums[q.axis_id] += ans.normalized;
            axisCounts[q.axis_id]++;
        }
    });

    const userAxisScores = {};
    Object.values(quizData.axes).forEach(ax => {
        userAxisScores[ax.id] = axisCounts[ax.id] > 0 ? (axisSums[ax.id] / axisCounts[ax.id]) : 0;
    });
    window.lastUserAxisScores = userAxisScores;

    const maxDistance = Math.sqrt(Object.keys(quizData.axes).length * Math.pow(2, 2));

    const candidates = quizData.candidates.map(candidate => {
        let sumSq = 0;
        Object.values(quizData.axes).forEach(ax => {
            const candScore = candidate.positions[ax.id] !== undefined ? candidate.positions[ax.id] : 0;
            const diff = userAxisScores[ax.id] - candScore;
            sumSq += diff * diff;
        });
        const distance = Math.sqrt(sumSq);
        const percentage = Math.max(0, 100 * (1 - (distance / maxDistance)));
        return { ...candidate, distance, percentage: Math.round(percentage) };
    });

    // Sort by percentage descending
    candidates.sort((a, b) => b.percentage - a.percentage);

    // Deshabilitar botón de comentario hasta que el guardado termine
    const fbBtn = document.getElementById('feedback-submit-btn');
    if (fbBtn) {
        fbBtn.disabled = true;
        fbBtn.textContent = 'Guardando...';
    }

    // Guardar en Supabase (sin bloquear la UI)
    saveResponse(userAnswers, window.lastUserAxisScores, candidates);

    resultsList.innerHTML = '';
    candidates.forEach((c, index) => {
        const card = document.createElement('div');
        card.className = 'candidate-card';
        card.style.cursor = 'pointer';
        card.onclick = () => showCandidateDetail(c, true);

        // Use a default image if not found
        const photoPath = c.photo || 'https://via.placeholder.com/150?text=Candidato';
        const partyPath = c.partyLogo || 'https://via.placeholder.com/60?text=P';


        card.innerHTML = `
            <div class="rank-number">#${index + 1}</div>
            <div class="candidate-image-container">
                <img src="${photoPath}" alt="${c.name}" class="candidate-photo">
                <img src="${partyPath}" alt="${c.party}" class="party-logo-mini">
            </div>
            <div class="candidate-info">
                <div class="candidate-name">${c.name}</div>
                <div class="candidate-party">${c.party}</div>
                <div class="match-bar-bg">
                    <div class="match-bar-fill" style="width: ${c.percentage}%"></div>
                </div>
            </div>
            <div class="match-percentage">
                <div class="percentage-value">${c.percentage}%</div>
                <div class="percentage-label">Afinidad</div>
            </div>
        `;
        resultsList.appendChild(card);
    });

    // Llenar y conectar botones de compartir con los top 3
    const top3 = candidates.slice(0, 3);
    populateShareCard(top3);
    document.getElementById('btn-download').onclick = () => captureAndDownload();
    document.getElementById('btn-share-native').onclick = () => shareToPlatform('native', top3);
    document.getElementById('btn-twitter').onclick = () => shareToPlatform('twitter', top3);
    document.getElementById('btn-facebook').onclick = () => shareToPlatform('facebook', top3);
    document.getElementById('btn-whatsapp').onclick = () => shareToPlatform('whatsapp', top3);
    document.getElementById('btn-instagram').onclick = () => shareToPlatform('instagram', top3);
}

startBtn.onclick = showNameScreen;
viewAnswersBtn.onclick = showAnswersScreen;
backToLandingBtn.onclick = () => {
    if (cameFromResults) {
        answersScreen.classList.add('hidden');
        resultsScreen.classList.remove('hidden');
        resultsScreen.classList.add('animate-in');
        cameFromResults = false;
    } else {
        if (!candidateDetailView.classList.contains('hidden')) {
            candidateDetailView.classList.add('hidden');
            candidatesGrid.classList.remove('hidden');
            candidatesGrid.classList.add('animate-in');
        } else {
            answersScreen.classList.add('hidden');
            landing.classList.remove('hidden');
            landing.classList.add('animate-in');
        }
    }
};
restartBtn.onclick = () => {
    resultsScreen.classList.add('hidden');
    landing.classList.remove('hidden');
    landing.classList.add('animate-in');
};

init();
