-- ═══════════════════════════════════════════════════════════════════
-- TEST IDEOLÓGICO COLOMBIA 2026 — Supabase / PostgreSQL
-- Ejecutar en orden: primero tablas sin FK, luego las dependientes
-- ═══════════════════════════════════════════════════════════════════


-- 1. axes ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS axes (
  id            SMALLINT PRIMARY KEY,
  name          VARCHAR(60)  NOT NULL,
  pole_negative VARCHAR(60)  NOT NULL,
  pole_positive VARCHAR(60)  NOT NULL,
  weight        FLOAT        NOT NULL DEFAULT 1.0
);


-- 2. questions ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS questions (
  id             SMALLINT PRIMARY KEY,
  axis_id        SMALLINT    NOT NULL REFERENCES axes(id),
  code           VARCHAR(6)  NOT NULL UNIQUE,
  statement      TEXT        NOT NULL,
  pole_direction SMALLINT    NOT NULL CHECK (pole_direction IN (-1, 1))
);


-- 3. candidates ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS candidates (
  id           SMALLINT     PRIMARY KEY,
  name         VARCHAR(100) NOT NULL,
  party        VARCHAR(100),
  profile      VARCHAR(100),
  bio          TEXT,
  campaign_url VARCHAR(200),
  photo_url    VARCHAR(200),
  party_logo_url VARCHAR(200),
  profile_pic_url VARCHAR(200)
);


-- 4. candidate_positions ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS candidate_positions (
  candidate_id SMALLINT NOT NULL REFERENCES candidates(id),
  axis_id      SMALLINT NOT NULL REFERENCES axes(id),
  score        FLOAT    NOT NULL CHECK (score >= -1.0 AND score <= 1.0),
  source       TEXT,
  PRIMARY KEY (candidate_id, axis_id)
);


-- 5. sessions ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sessions (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at   TIMESTAMPTZ NOT NULL    DEFAULT now(),
  completed    BOOLEAN     NOT NULL    DEFAULT FALSE,
  user_agent   TEXT,
  location_hint VARCHAR(100),
  comment       TEXT
);


-- 6. responses ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS responses (
  session_id       UUID     NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  question_id      SMALLINT NOT NULL REFERENCES questions(id),
  raw_answer       SMALLINT NOT NULL CHECK (raw_answer BETWEEN 1 AND 4),
  normalized_score FLOAT    NOT NULL CHECK (normalized_score >= -1.0 AND normalized_score <= 1.0),
  PRIMARY KEY (session_id, question_id)
);


-- 7. user_axis_scores ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_axis_scores (
  session_id UUID     NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  axis_id    SMALLINT NOT NULL REFERENCES axes(id),
  score      FLOAT    NOT NULL CHECK (score >= -1.0 AND score <= 1.0),
  PRIMARY KEY (session_id, axis_id)
);


-- 8. results ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS results (
  session_id   UUID     NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  candidate_id SMALLINT NOT NULL REFERENCES candidates(id),
  distance     FLOAT    NOT NULL CHECK (distance >= 0),
  rank         SMALLINT NOT NULL CHECK (rank >= 1),
  PRIMARY KEY (session_id, candidate_id)
);


-- ═══════════════════════════════════════════════════════════════════
-- ÍNDICES RECOMENDADOS
-- ═══════════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_questions_axis    ON questions(axis_id);
CREATE INDEX IF NOT EXISTS idx_responses_session ON responses(session_id);
CREATE INDEX IF NOT EXISTS idx_results_session   ON results(session_id);
CREATE INDEX IF NOT EXISTS idx_results_rank      ON results(session_id, rank);


-- ═══════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (Supabase) — habilitar en tablas de usuario
-- ═══════════════════════════════════════════════════════════════════

ALTER TABLE sessions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE responses        ENABLE ROW LEVEL SECURITY;
-- RLS no requerido en backend nativo
ALTER TABLE results          ENABLE ROW LEVEL SECURITY;


-- =========================================================================
-- DATA INSERTS
-- =========================================================================

-- Inserts for axes
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (1, 'Económico', 'Intervencionismo', 'Libre mercado', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (2, 'Seguridad', 'Progresismo', 'Punitivismo', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (3, 'Moral', 'Neutralidad', 'Moralidad', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (4, 'Cultural', 'Progresismo', 'Conservadurismo', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (5, 'Ambiental', 'Ambientalismo', 'No-Ambientalismo', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (6, 'Internacional', 'Soberanismo', 'Cosmopolitismo', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (7, 'Liderazgo', 'Dogmatismo', 'Pragmatismo', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (8, 'Institucional', 'Institucionalidad', 'Ruptura', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO axes (id, name, pole_negative, pole_positive, weight) VALUES (9, 'Política social', 'Universalismo', 'Focalización', 1) ON CONFLICT (id) DO NOTHING;

-- Inserts for questions
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (1, 1, 'E1.1', 'El Estado colombiano debería tener control directo sobre sectores estratégicos como la energía, el agua y las telecomunicaciones, en lugar de dejarlos en manos privadas.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (2, 1, 'E1.2', 'El aumento del salario mínimo por encima de la inflación es una herramienta legítima y necesaria para reducir la desigualdad en Colombia.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (3, 1, 'E1.3', 'La crisis fiscal colombiana es principalmente el resultado de un Estado que gasta demasiado y recauda mal, no de una falta de inversión pública.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (4, 1, 'E1.4', 'La mejor forma de generar empleo formal en Colombia es reducir los costos y trámites que enfrentan las empresas privadas, no aumentar la regulación laboral.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (5, 1, 'E1.5', 'Colombia debería avanzar hacia una economía donde el mercado, y no el gobierno, determine los precios de bienes y servicios esenciales.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (6, 1, 'E1.6', 'El Estado colombiano tiene la responsabilidad de intervenir activamente para corregir las desigualdades económicas que el mercado por sí solo no puede resolver.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (7, 2, 'E2.1', 'La violencia en Colombia no se resolverá con más fuerza militar sino atacando las causas estructurales como la pobreza, la inequidad y el abandono estatal.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (8, 2, 'E2.2', 'Los grupos armados colombianos son principalmente organizaciones criminales que buscan lucro, no actores con causas políticas o sociales legítimas.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (9, 2, 'E2.3', 'Negociar con grupos armados que siguen delinquiendo mientras se desarrollan los diálogos de paz es un error que legitima la violencia.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (10, 2, 'E2.4', 'La inseguridad en las ciudades colombianas está directamente relacionada con la falta de oportunidades laborales y educativas para los jóvenes.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (11, 2, 'E2.5', 'El Estado colombiano debería priorizar el sometimiento a la justicia de los grupos armados sobre cualquier proceso de diálogo o negociación.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (12, 2, 'E2.6', 'Una política de seguridad efectiva en Colombia debe combinar intervención social en territorios abandonados con presencia institucional del Estado, no solo fuerza pública.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (13, 3, 'E3.1', 'El Estado colombiano no debería promover ni desincentivar ningún estilo de vida particular mientras no cause daño a terceros.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (14, 3, 'E3.2', 'La educación pública tiene la responsabilidad de transmitir valores éticos y cívicos concretos a los estudiantes, no solo conocimientos técnicos.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (15, 3, 'E3.3', 'Las decisiones personales de los ciudadanos, como qué consumir, con quién relacionarse o cómo organizar su familia, no son asunto del Estado.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (16, 3, 'E3.4', 'El Estado colombiano debería desincentivar activamente comportamientos que, aunque legales, son perjudiciales para la sociedad o la salud pública.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (17, 3, 'E3.5', 'Una sociedad sana necesita que sus instituciones públicas promuevan activamente ciertos valores compartidos, no que se declaren neutrales frente a todo.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (18, 4, 'E4.1', 'El matrimonio entre personas del mismo sexo debería tener exactamente los mismos derechos y reconocimiento legal que el matrimonio heterosexual.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (19, 4, 'E4.2', 'La perspectiva de género debería incorporarse de forma transversal en los currículos de la educación pública colombiana.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (20, 4, 'E4.3', 'La familia conformada por padre, madre e hijos sigue siendo el núcleo fundamental de la sociedad colombiana y debe ser protegida como tal por el Estado.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (21, 4, 'E4.4', 'La interrupción voluntaria del embarazo debería estar disponible de forma legal y gratuita en el sistema de salud colombiano sin restricciones adicionales.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (22, 4, 'E4.5', 'Los valores religiosos y culturales tradicionales de las comunidades colombianas deben ser respetados y preservados frente a cambios impuestos desde afuera.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (23, 4, 'E4.6', 'Colombia ha avanzado demasiado rápido en cambios culturales que no reflejan los valores de la mayoría de su población.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (24, 5, 'E5.1', 'Colombia debería prohibir la exploración y explotación de nuevos yacimientos de petróleo y gas, aunque eso implique sacrificar ingresos fiscales importantes.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (25, 5, 'E5.2', 'El desarrollo económico de las regiones más pobres de Colombia debe tener prioridad sobre la conservación ambiental cuando entren en conflicto.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (26, 5, 'E5.3', 'Las consultas previas con comunidades indígenas y afrodescendientes son un mecanismo legítimo de protección territorial aunque retrasen proyectos de infraestructura o energía.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (27, 5, 'E5.4', 'Colombia no debería sacrificar su competitividad económica adoptando estándares ambientales más exigentes que los de sus países vecinos.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (28, 5, 'E5.5', 'La transición hacia energías renovables en Colombia debe acelerarse incluso si eso implica costos más altos para los consumidores en el corto plazo.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (29, 6, 'E6.1', 'Colombia debería diversificar sus relaciones comerciales y diplomáticas, incluyendo alianzas con países como China, independientemente de la presión de Estados Unidos.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (30, 6, 'E6.2', 'Los acuerdos de libre comercio firmados por Colombia han beneficiado más a las multinacionales extranjeras que a los productores nacionales.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (31, 6, 'E6.3', 'Colombia tiene más que ganar integrándose activamente a organismos multilaterales y tratados internacionales que defendiendo su autonomía frente a ellos.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (32, 6, 'E6.4', 'Colombia debería priorizar la producción nacional de alimentos y bienes esenciales sobre la dependencia de importaciones, aunque sea menos eficiente económicamente.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (33, 6, 'E6.5', 'Las políticas públicas colombianas deberían alinearse con los estándares y recomendaciones de organismos internacionales como la OCDE o la ONU.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (34, 7, 'E7.1', 'Un gobernante que abandona sus principios ideológicos para lograr acuerdos políticos está traicionando a quienes lo eligieron.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (35, 7, 'E7.2', 'Es preferible un gobierno que logre resultados concretos y medibles, aunque para ello deba hacer concesiones ideológicas importantes.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (36, 7, 'E7.3', 'La coherencia entre lo que un político promete y lo que hace en el gobierno es más importante que la efectividad de sus políticas.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (37, 7, 'E7.4', 'En política, los buenos resultados justifican aliarse con sectores o personas con los que no se comparten valores, si eso permite avanzar en objetivos importantes.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (38, 7, 'E7.5', 'Un líder político que gobierna con base en sus convicciones, aunque los resultados sean imperfectos, es más valioso para la democracia que uno que gobierna solo por resultados.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (39, 8, 'E8.1', 'Los cambios profundos que necesita Colombia deben lograrse a través de los mecanismos institucionales existentes, no por fuera de ellos.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (40, 8, 'E8.2', 'Cuando las instituciones colombianas sistemáticamente favorecen a las élites, es legítimo buscar transformaciones que vayan más allá de lo que esas instituciones permiten.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (41, 8, 'E8.3', 'La independencia de la rama judicial frente al ejecutivo es una condición innegociable para la democracia colombiana, incluso cuando eso bloquee reformas necesarias.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (42, 8, 'E8.4', 'Las reglas de juego institucionales en Colombia fueron diseñadas para mantener el statu quo y no pueden ser el único camino para transformar el país.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (43, 8, 'E8.5', 'Un gobierno que utiliza su popularidad para presionar o deslegitimar a los órganos de control está poniendo en riesgo la democracia, independientemente de sus intenciones.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (44, 8, 'E8.6', 'En un país con tanta desigualdad como Colombia, respetar las formas institucionales no puede ser más importante que conseguir justicia social real.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (45, 9, 'E9.1', 'El sistema de salud colombiano debería garantizar exactamente la misma calidad de atención a todos los ciudadanos, eliminando la diferencia entre atención pública y privada.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (46, 9, 'E9.2', 'Los recursos limitados del Estado colombiano deberían concentrarse en quienes más los necesitan, no distribuirse de forma pareja entre toda la población.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (47, 9, 'E9.3', 'La educación pública colombiana debería ser de tan buena calidad que los colombianos de clase media y alta no sintieran necesidad de recurrir a colegios privados.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (48, 9, 'E9.4', 'Es razonable que quienes pueden pagar accedan a servicios de salud y educación privados de mayor calidad, siempre que el Estado garantice un piso mínimo para todos.', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (49, 9, 'E9.5', 'El sistema pensional colombiano debería garantizar una pensión digna a todos los ciudadanos sin importar si cotizaron o no durante su vida laboral.', -1) ON CONFLICT (id) DO NOTHING;
INSERT INTO questions (id, axis_id, code, statement, pole_direction) VALUES (50, 9, 'E9.6', 'Los subsidios y programas sociales del Estado colombiano deberían estar estrictamente dirigidos a la población en pobreza, no extenderse a sectores que pueden valerse por sí mismos.', 1) ON CONFLICT (id) DO NOTHING;

-- Inserts for candidates
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (1, 'Iván Cepeda', 'Pacto Histórico', 'Izquierda progresista', 'Senador de la República por el Pacto Histórico y uno de los líderes más visibles de la izquierda progresista en Colombia. Con una larga trayectoria en la defensa de los derechos humanos y la búsqueda de la paz, Cepeda ha sido una pieza fundamental en la construcción de diálogos con grupos armados y un crítico constante de las políticas de seguridad tradicionales.



Para las elecciones de 2026, se proyecta como un candidato que busca profundizar las reformas sociales del actual gobierno, enfocándose en la justicia climática, la redistribución de la tierra y el fortalecimiento de lo público frente a los intereses privados.', 'https://ivancepedacastro.com', 'Candidatos/Iván Cepeda.png', 'Partidos/Pacto Histórico.png', 'Perfil/izquierda_progresista.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (2, 'David Luna', 'Cambio Radical', 'Centro/Derecha', 'Senador por el partido Cambio Radical y exministro de Tecnologías de la Información. Luna se ha posicionado como una voz técnica y moderna, centrada en la transformación digital, la transparencia y la eficiencia del Estado. Es reconocido por su capacidad de debate y su enfoque en soluciones prácticas a problemas complejos de infraestructura y conectividad.



Su candidatura para 2026 lidera la iniciativa ''Gran Consulta por Colombia'', buscando unir a sectores de centro y derecha bajo una propuesta que prioriza la reactivación económica, el apoyo al emprendimiento tecnológico y el fortalecimiento de la seguridad con apoyo de la inteligencia de datos.', 'https://davidluna.com', 'Candidatos/David Luna.png', 'Partidos/Cambio Radical.png', 'Perfil/centro_derecha_tech.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (3, 'Abelardo de la Espriella', 'Movimiento de Salvación Nacional', 'Derecha dura', 'Reconocido abogado penalista y figura mediática, De la Espriella ha dado el salto a la política con un discurso de derecha conservadora y ''mano dura''. Es el líder del movimiento ''Defensores de la Patria'', desde donde promueve una visión de Estado centrada en el orden, la protección de la propiedad privada y la lucha frontal contra el crimen sin concesiones.



Su propuesta para 2026 se basa en lo que denomina ''recuperar la patria'', enfocándose en la desregulación económica, el fortalecimiento de las fuerzas militares y una crítica severa a las políticas progresistas, apelando a un electorado que busca seguridad jurídica y valores tradicionales.', 'https://defensoresdelapatria.com', 'Candidatos/Abelardo de la Espriella.png', 'Partidos/Movimiento de Salvación Nacional.png', 'Perfil/derecha_dura.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (4, 'Aníbal Gaviria', 'Fuerza de las regiones', 'Regional', 'Exgobernador de Antioquia y exalcalde de Medellín, Gaviria es una figura de amplia trayectoria administrativa y reconocimiento regional. Su liderazgo se caracteriza por un enfoque en el desarrollo de infraestructura, la innovación social y la autonomía de las regiones como motor de progreso nacional.



Participa en la escena nacional para 2026 como una opción de experiencia y gestión probada, defendiendo el federalismo y la descentralización. Busca representar a las regiones que reclaman mayor poder de decisión sobre sus recursos, promoviendo un Estado eficiente que trabaje desde la periferia hacia el centro.', 'https://anibalpresidente.co', 'Candidatos/Aníbal Gaviria.png', 'Partidos/Fuerza de las regiones.png', 'Perfil/regional.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (5, 'Mauricio Cárdenas', 'Avanza Colombia', 'Tecnócrata', 'Exministro de Hacienda y destacado economista, Cárdenas representa el ala técnica y moderada de la política colombiana. Con una sólida formación académica y experiencia en organismos internacionales, su perfil se orienta hacia la estabilidad macroeconómica, el manejo responsable de las finanzas públicas y el fomento de la inversión.



Bajo su movimiento ''Avanza Colombia'', propone una candidatura centrada en el crecimiento sostenible y la reactivación del empleo. Se presenta como una alternativa de experiencia capaz de navegar crisis fiscales, priorizando la sensatez técnica sobre la polarización ideológica para las elecciones de 2026.', 'https://mauricio-cardenas.com', 'Candidatos/Mauricio Cárdenas.png', 'Partidos/Avanza Colombia.png', 'Perfil/Tecnócrata.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (6, 'Victoria Dávila', 'Movimiento Valientes', 'Derecha dura', 'Reconocida periodista y exdirectora de la Revista Semana, Dávila ha incursionado en la política tras años de un periodismo crítico y confrontativo. Su perfil se asocia con la denuncia de la corrupción y la seguridad ciudadana, utilizando un lenguaje directo que resuena con sectores descontentos con la política tradicional.



Con su movimiento ''Valientes Colombia'', busca liderar una propuesta de derecha que promete orden, justicia y una revisión profunda de la estructura estatal. Su candidatura para 2026 apela a una ciudadanía cansada de los privilegios políticos y que busca una figura externa con determinación para realizar cambios radicales.', 'https://vickydavilaoficial.com', 'Candidatos/Victoria Dávila.png', 'Partidos/Movimiento Valientes.png', 'Perfil/derecha_dura.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (7, 'Claudia López', 'Con Claudia Imparables', 'Centro progresista', 'Exalcaldesa de Bogotá y exsenadora, López es una líder carismática conocida por su lucha contra la corrupción y su defensa de los servicios sociales urbanos. Su trayectoria en la academia y la política se ha centrado en la transparencia, el fortalecimiento de la educación pública y la movilidad sostenible.



Para 2026, con su iniciativa ''Con Claudia Imparables'', busca atraer al electorado de centro-progresista. Su propuesta se basa en un Estado cuidador, la autonomía regional y una gestión pública basada en la evidencia, presentándose como una ejecutora con temple y visión de futuro para el país.', 'https://claudia-lopez.com', 'Candidatos/Claudia López.png', 'Partidos/Con Claudia Imparables.png', 'Perfil/centro_progresista.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (8, 'Juan Manuel Galán', 'Nuevo Liberalismo', 'Centro/Derecha', 'Hijo del inmolado Luis Carlos Galán, Juan Manuel ha dedicado su carrera a revivir el legado del Nuevo Liberalismo. Su perfil combina una herencia política histórica con una visión moderna de defensa de la institucionalidad, la lucha contra el narcotráfico desde un enfoque de salud pública y el fortalecimiento de la democracia liberal.



Para 2026, su candidatura representa una opción de centro que busca alejarse de los extremos. Propone una agenda de transformación basada en las ideas de su padre, adaptadas a los retos actuales de equidad, seguridad ciudadana y una política exterior que posicione a Colombia como un actor relevante en la región.', 'https://galan.co', 'Candidatos/Juan Manuel Galán.png', 'Partidos/Nuevo Liberalismo.png', 'Perfil/centro_derecha_tech.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (9, 'Juan Carlos Pinzón', 'Verde Oxígeno', 'Centroderecha seguridad', 'Exministro de Defensa y exembajador en Estados Unidos, Pinzón es una de las voces más autorizadas en temas de seguridad y relaciones internacionales. Su perfil es marcadamente institucional, con una fuerte conexión con las fuerzas militares y un conocimiento profundo de la geopolítica regional.



Bajo el aval de Verde Oxígeno para 2026, su propuesta se centra en la recuperación del orden público, la seguridad jurídica para la inversión y el fortalecimiento de la alianza con socios estratégicos. Se presenta como una garantía de autoridad y estabilidad para un país que requiere retomar el control del territorio y la confianza institucional.', 'https://pinzonbueno.com', 'Candidatos/Juan Carlos Pinzón.png', 'Partidos/Verde Oxígeno.png', 'Perfil/centroderecha_seguridad.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (10, 'Juan Daniel Oviedo', 'Con toda por Colombia', 'Tecnócrata', 'Economista y exdirector del DANE, Oviedo irrumpió en la política con una propuesta basada en los datos y la evidencia técnica. Su paso por la administración pública le ha dado un perfil de tecnócrata cercano a la gente, capaz de explicar realidades socioeconómicas complejas de manera sencilla y transparente.



Su candidatura para 2026 se construye a través de la recolección de firmas, apostando por una política que denomina ''con toda''. Propone una gestión centrada en la eficiencia, el conocimiento estadístico para orientar la inversión social y una visión de país que priorice la superación de la pobreza mediante indicadores reales de impacto y crecimiento.', 'https://juandanieloviedo.com.co', 'Candidatos/Juan Daniel Oviedo.png', 'Partidos/Con toda por Colombia.png', 'Perfil/Tecnócrata.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (11, 'Enrique Peñalosa', 'Verde Oxígeno', 'Centro/Derecha', 'Dos veces alcalde de Bogotá, Peñalosa es reconocido por su enfoque en el urbanismo, la movilidad y la infraestructura a gran escala. Su perfil es el de un ejecutor pragmático que privilegia la transformación física del territorio como motor de bienestar social y modernización urbana.



De cara a 2026, con el aval del partido Oxígeno, Peñalosa busca escalar su modelo de gestión a nivel nacional. Su propuesta se centra en la competitividad regional, la construcción de grandes obras de infraestructura y una visión de desarrollo que priorice la eficiencia técnica sobre los discursos ideológicos, apelando a su capacidad demostrada para gerenciar ciudades.', 'https://verdeoxigeno.com', 'Candidatos/Enrique Peñalosa.png', 'Partidos/Verde Oxígeno.png', 'Perfil/centro_derecha_tech.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (12, 'Paloma Valencia', 'Centro Democrático', 'Derecha uribismo', 'Senadora del Centro Democrático y candidata presidencial oficial del uribismo para 2026. Abogada y filósofa de la Universidad de los Andes, con maestría en Escritura Creativa de la Universidad de Nueva York, cuenta con una trayectoria legíslativa de más de una década como vocera del partido. Nieta del expresidente Guillermo León Valencia, combina un linaje político histórico con un discurso propio centrado en la seguridad, la defensa de los derechos de las víctimas y el apoyo al sector agropecuario.



Su candidatura para 2026 la posiciona como la primera mujer que aspiraría a la presidencia por el Centro Democrático. Su propuesta, resumida en el lema ''Vivir sin miedo'', apuesta por recuperar la seguridad como base del desarrollo, restaurar la institucionalidad frente a los grupos armados, y un manejo responsable de las finanzas públicas, reforzando así la opción de derecha democrática frente a la polarización actual.', 'https://palomavalencia.com', 'Candidatos/Paloma Valencia.png', 'Partidos/Centro Democrático.png', 'Perfil/derecha_uribismo.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (13, 'Roy Barreras', 'Fuerza', 'Izquierda progresista', 'Exsenador, exparlamentario y exembajador de Colombia en el Reino Unido, Barreras es uno de los políticos más experimentados del país, con una carrera que abarca más de dos décadas en el Congreso. Presió el Congreso de la República en dos ocasiones (2012-2013 y 2022-2023) y fue parte de la delegación del Gobierno en las negociaciones de paz con las FARC en Cuba. A lo largo de su trayectoria transitó por el Partido Liberal, Cambio Radical, el Partido de la U y el Pacto Histórico, lo que le otorga un amplio conocimiento de todos los espectros políticos.



Para 2026, renunció a su cargo diplomático para lanzar su candidatura desde su propio partido, ''La Fuerza de la Paz''. Se presenta como una opción de centro que busca superar la polarización, con propuestas de seguridad total, reactivación económica y unidad nacional. Su lema es reconciliar a los colombianos bajo la premisa de que un país unido es la base para cualquier reforma profunda y sostenible.', 'https://fuerza.com.co', 'Candidatos/Roy Barreras.png', 'Partidos/Fuerza.png', 'Perfil/izquierda_progresista.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (14, 'Sergio Fajardo', 'Dignidad y Compromiso', 'Centro progresista', 'Matemático, doctor de la Universidad de Wisconsin y exdocente universitario, Fajardo entró a la política por fuera de los partidos tradicionales fundando el movimiento cívico ''Compromiso Ciudadano''. Como alcalde de Medellín (2004-2007) transformó la ciudad en un referente mundial de urbanismo social, y como gobernador de Antioquia (2012-2015) impulsó el plan ''Antioquia la Más Educada'', reconocido por su transparencia y gestión de regalías. Es su tercer intento presidencial, tras quedar tercero en 2018 y cuarto en 2022.



Para las elecciones de 2026 se presenta con el partido ''Dignidad y Compromiso'', que cofundó en 2023. Su propuesta se estructura en torno a la educación como motor de desarrollo, la seguridad con un enfoque institucional y el rechazo frontal a la política de ''Paz Total''. Bajo el lema ''podemos ser diferentes sin ser enemigos'', busca construir una alternativa de centro basada en la meritocracia, la transparencia y la capacidad demostrada de transformar territorios desde la base.', 'https://sergiofajardo.com', 'Candidatos/Sergio Fajardo.png', 'Partidos/Dignidad y Compromiso.png', 'Perfil/centro_progresista.jpg') ON CONFLICT (id) DO NOTHING;
INSERT INTO candidates (id, name, party, profile, bio, campaign_url, photo_url, party_logo_url, profile_pic_url) VALUES (15, 'Daniel Quintero', 'AICO', 'Izquierda progresista', 'Ingeniero electrónico, exalcalde de Medellín (2020-2023) y ex viceministro TIC durante el gobierno Santos, donde lideró iniciativas de transformación digital del Estado. También fue gerente de iNNpulsa Colombia, la agencia estatal de emprendimiento e innovación. Su alcaldía estuvo marcada por la puesta en marcha de Hidroituango y controversias sobre su suspensión, que él atribuye a persecución política.

Para 2026, se lanza con aval de AICO tras intentos fallidos en la consulta del Pacto Histórico. Su propuesta central es "resetear" el país: convocar una Asamblea Nacional Constituyente, usar tecnología (incluyendo blockchain) para combatir la corrupción en salud y contratación, y una reforma fiscal que amplíe la base tributaria bajando tasas para sacar la economía sumergida. Combina un discurso de justicia social y ambiental con un enfoque tech e innovador que lo distingue dentro del espectro progresista.', 'https://danielquintero.co', 'Candidatos/Daniel Quintero.png', 'Partidos/AICO.png', 'Perfil/izquierda_tech.jpg') ON CONFLICT (id) DO NOTHING;

-- Inserts for candidate_positions
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 1, -1.0, 'Respuestas declaradas al test original') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 2, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 3, -0.75, 'Análisis editorial — trayectoria pública DDHH') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 4, -1.0, 'Análisis editorial — posiciones públicas documentadas') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 5, -1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 6, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 7, -0.75, 'Análisis editorial — perfil y discurso') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 8, -1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (1, 9, -1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 1, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 2, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 3, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 4, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 5, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 6, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 7, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 8, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (2, 9, 0.333, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 1, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 2, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 3, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 4, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 5, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 6, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 7, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 8, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (3, 9, 0.833, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 1, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 2, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 3, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 4, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 5, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 6, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 7, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 8, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (4, 9, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 1, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 2, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 3, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 4, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 5, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 6, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 7, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 8, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (5, 9, 0.167, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 1, 0.625, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 2, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 3, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 4, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 5, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 6, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 7, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 8, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (6, 9, 0.667, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 1, -0.125, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 2, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 3, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 4, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 5, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 6, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 7, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 8, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (7, 9, -0.167, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 1, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 2, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 3, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 4, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 5, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 6, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 7, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 8, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (8, 9, -0.167, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 1, 0.125, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 2, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 3, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 4, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 5, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 6, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 7, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 8, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (9, 9, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 1, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 2, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 3, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 4, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 5, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 6, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 7, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 8, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (10, 9, -0.333, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 1, 0.375, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 2, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 3, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 4, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 5, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 6, 0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 7, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 8, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (11, 9, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 1, 0.125, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 2, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 3, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 4, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 5, 0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 6, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 7, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 8, 1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (12, 9, 0.167, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 1, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 2, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 3, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 4, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 5, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 6, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 7, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 8, -1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (13, 9, -0.833, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 1, -0.125, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 2, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 3, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 4, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 5, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 6, 0.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 7, -0.25, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 8, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (14, 9, -0.167, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 1, -0.125, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 2, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 3, -0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 4, -0.75, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 5, -1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 6, 0.5, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 7, -1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 8, -1.0, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;
INSERT INTO candidate_positions (candidate_id, axis_id, score, source) VALUES (15, 9, -0.833, 'Respuestas declaradas al test / análisis editorial (La Silla Vacía, Volcánicas, Infobae CO)') ON CONFLICT (candidate_id, axis_id) DO NOTHING;


-- =========================================================================
-- STORED PROCEDURE (RPC) PARA GUARDAR LA SESIÓN COMPLETA EN UNA SOLA LLAMADA
-- =========================================================================
CREATE OR REPLACE FUNCTION submit_quiz_session(
    p_user_agent TEXT,
    p_location_hint VARCHAR(100),
    p_responses JSONB,     -- Formato: [{"question_id": 1, "raw_answer": 4, "normalized_score": 1.0}, ...]
    p_user_scores JSONB,   -- Formato: [{"axis_id": 1, "score": 0.5}, ...]
    p_results JSONB        -- Formato: [{"candidate_id": 1, "distance": 1.5, "rank": 1}, ...]
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_id UUID;
    r RECORD;
BEGIN
    -- 1. Insertar la sesión y obtener el ID
    INSERT INTO sessions (user_agent, location_hint, completed)
    VALUES (p_user_agent, p_location_hint, TRUE)
    RETURNING id INTO v_session_id;

    -- 2. Insertar las respuestas
    FOR r IN SELECT * FROM jsonb_to_recordset(p_responses) AS x(question_id SMALLINT, raw_answer SMALLINT, normalized_score FLOAT)
    LOOP
        INSERT INTO responses (session_id, question_id, raw_answer, normalized_score)
        VALUES (v_session_id, r.question_id, r.raw_answer, r.normalized_score);
    END LOOP;

    -- 3. Insertar los scores por eje del usuario
    FOR r IN SELECT * FROM jsonb_to_recordset(p_user_scores) AS x(axis_id SMALLINT, score FLOAT)
    LOOP
        INSERT INTO user_axis_scores (session_id, axis_id, score)
        VALUES (v_session_id, r.axis_id, r.score);
    END LOOP;

    -- 4. Insertar los resultados del ranking
    FOR r IN SELECT * FROM jsonb_to_recordset(p_results) AS x(candidate_id SMALLINT, distance FLOAT, rank SMALLINT)
    LOOP
        INSERT INTO results (session_id, candidate_id, distance, rank)
        VALUES (v_session_id, r.candidate_id, r.distance, r.rank);
    END LOOP;

    RETURN v_session_id;
END;
$$;


-- RLS FIX

-- ═══════════════════════════════════════════════════════════════════
-- FUNCIÓN RPC PARA GUARDAR COMENTARIO DE SESIÓN
-- ═══════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION save_session_comment(
    p_session_id UUID,
    p_comment    TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE sessions
    SET comment = p_comment
    WHERE id = p_session_id;
END;
$$;
