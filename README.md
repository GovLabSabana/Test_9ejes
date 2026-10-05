# Convergencia Electoral: Encuentra tu Candidato

Herramienta interactiva para que ciudadanos colombianos identifiquen cuál precandidato a las **Elecciones Presidenciales 2026** se alinea mejor con sus valores y propuestas, a través de un sistema de **9 ejes ideológicos y de política pública**.

Desarrollada por el **Laboratorio de Gobierno (GovLab)** de la Universidad de La Sabana.

---

## Características

- **Test de Afinidad por 9 Ejes**: Cuestionario de preguntas tipo Likert organizadas por ejes temáticos (Economía, Trabajo, Salud, Seguridad, Medio Ambiente, entre otros).
- **Algoritmo N-Dimensional**: El sistema calcula la distancia euclidiana entre el perfil ideológico del usuario y el de cada candidato en los 9 ejes, generando un porcentaje de afinidad preciso.
- **Pantalla de bienvenida personalizada**: Solicita el nombre del usuario antes de comenzar. El nombre aparece en el título de resultados (*"Juan, estos son tus resultados"*).
- **Ranking Personalizado**: Al finalizar el test, ranking de afinidad con los 14 candidatos ordenados de mayor a menor convergencia.
- **Perfiles de Candidatos**: Visualización de la posición de cada candidato en los 9 ejes, con comparación directa frente a las respuestas del usuario, más biografía detallada y enlace a campaña oficial.
- **Compartir Resultados**: Generación de imagen descargable con el top 3 de candidatos. Soporte para compartir en Twitter/X, Facebook, WhatsApp, Instagram y Web Share API (móvil nativo).
- **Sección de Comentarios**: Al terminar el test, el usuario puede dejar comentarios o sugerencias de forma opcional (máx. 200 palabras).
- **Persistencia de datos (PostgreSQL nativo en Railway)**: Cada respuesta se guarda automáticamente en PostgreSQL vía backend Express (`submit_quiz_session`), incluyendo respuestas por pregunta, scores por eje, ranking de candidatos e ID de sesión para vincular comentarios.
- **Diseño Premium**: Glassmorphism, modo oscuro, animaciones fluidas y optimización móvil.

---

## Tecnologías Utilizadas

- **Frontend**: HTML5, CSS3 (Vanilla), JavaScript ES6+
- **Backend**: Node.js + Express (`server.js`) con cliente nativo `pg`
- **Base de datos**: [PostgreSQL en Railway](https://railway.app) (o cualquier PostgreSQL estándar)
- **Captura de imagen**: [html2canvas](https://html2canvas.hertzen.com/)
- **Fuentes**: Google Fonts (Inter)

---

## Estructura de Archivos

```
Test_9ejes/
├── index.html            # Estructura de la app (landing, nombre, quiz, resultados, perfiles)
├── app.js                # Lógica del cliente y llamadas a la API de backend
├── style.css             # Estilos y diseño responsivo
├── server.js             # Servidor Express con endpoints REST y conexión a PostgreSQL
├── migrate.js            # Script para ejecutar migraciones en PostgreSQL
├── railway_schema.sql    # Esquema completo e inicialización de datos para Railway Postgres
├── package.json          # Dependencias Node (express, pg, dotenv)
├── LICENSE               # Licencia CC BY-NC 4.0
├── README.md
├── Candidatos/           # Fotos de los candidatos
├── Partidos/             # Logos de los partidos políticos
├── Perfil/               # Imágenes de perfil por tendencia ideológica
└── Íconos/               # Logos institucionales y portada para compartir
```

---

## Base de Datos (PostgreSQL en Railway)

La aplicación utiliza PostgreSQL nativo a través de un pool de conexiones en el backend (`server.js`).

### Configuración en Railway (Paso a Paso)

1. **Crear base de datos en Railway:**
   - En tu proyecto de Railway, haz clic en **+ New** -> **Database** -> **Add PostgreSQL**.
2. **Vincular variable de entorno:**
   - Railway genera automáticamente la variable `DATABASE_URL`.
   - Si la aplicación web y la base de datos están en el mismo proyecto de Railway, la aplicación ya tendrá acceso a `DATABASE_URL`.
3. **Inicialización automática:**
   - Al desplegar la aplicación, `server.js` detecta automáticamente si las tablas existen; si la base de datos está vacía, ejecuta de manera autónoma `railway_schema.sql` creando todas las tablas, índices, datos maestros y funciones RPC.
4. **Ejecución manual (opcional):**
   - También puedes correr el script de migración manualmente ejecutando:
     ```bash
     npm run migrate
     ```
   - O copiar el contenido de `railway_schema.sql` y pegarlo en el editor **Query** del servicio PostgreSQL en el dashboard de Railway.

### Tablas principales

| Tabla | Descripción |
|---|---|
| `axes` | Los 9 ejes ideológicos (nombre, polos, peso) |
| `questions` | Preguntas del quiz, vinculadas a un eje y con dirección de polo |
| `candidates` | Perfil de cada candidato (nombre, partido, bio, URLs) |
| `candidate_positions` | Posición de cada candidato en cada eje (score de -1 a 1) |
| `sessions` | Sesión guardada por usuario (user agent, nombre, comentario) |
| `responses` | Respuesta normalizada por pregunta por sesión |
| `user_axis_scores` | Score promedio por eje por sesión |
| `results` | Ranking final de candidatos por sesión |

---

## Los 9 Ejes Ideológicos

| # | Eje | Polo Negativo Polo Positivo |
|---|---|---|
| 1 | Rol del Estado en la Economía | Libre mercado Intervencionismo |
| 2 | Política Fiscal | Austeridad Gasto social |
| 3 | Seguridad y Justicia | Mano dura Enfoque social |
| 4 | Política de Paz | Seguridad militar Diálogo y paz total |
| 5 | Medio Ambiente | Desarrollo extractivista Transición ecológica |
| 6 | Modelo Social | Conservadurismo Progresismo |
| 7 | Descentralización | Centralismo Autonomía regional |
| 8 | Política Exterior | Soberanía / aislamiento Integración global |
| 9 | Lucha contra la Corrupción | Institucionalismo Reformismo radical |

---

## Instalación y Uso Local

### Opción 1 — Python (sin dependencias)

```bash
# Clona el repositorio
git clone https://github.com/Juansotag/Test_9ejes.git
cd Test_9ejes

# Inicia el servidor local
python -m http.server 8001
```

Abre [http://localhost:8001](http://localhost:8001) en tu navegador.

### Opción 2 — Node.js / Express

```bash
git clone https://github.com/Juansotag/Test_9ejes.git
cd Test_9ejes

npm install
npm start
```

Abre [http://localhost:3000](http://localhost:3000) en tu navegador.

> **Nota:** La app requiere conexión a internet para cargar los datos desde Supabase.

---

## Candidatos Incluidos (2026)

| # | Candidato | Partido |
|---|---|---|
| 1 | Iván Cepeda | Pacto Histórico |
| 2 | David Luna | Cambio Radical |
| 3 | Abelardo de la Espriella | Salvación Nacional |
| 4 | Aníbal Gaviria | La Fuerza de las Regiones |
| 5 | Mauricio Cárdenas | Avanza Colombia |
| 6 | Victoria Dávila | Movimiento Valientes |
| 7 | Claudia López | Con Claudia Imparables |
| 8 | Juan Manuel Galán | Nuevo Liberalismo |
| 9 | Juan Carlos Pinzón | Verde Oxígeno |
| 10 | Juan Daniel Oviedo | Con Toda por Colombia |
| 11 | Enrique Peñalosa | Verde Oxígeno |
| 12 | Paloma Valencia | Centro Democrático |
| 13 | Roy Barreras | La Fuerza de la Paz |
| 14 | Sergio Fajardo | Dignidad y Compromiso |

---

## Créditos

- **Desarrollado por**: Laboratorio de Gobierno (GovLab) — Universidad de La Sabana
- **Autor**: Juan Diego Sotelo Aguilar
- **Vigilada**: MinEducación

---

## Licencia

**Creative Commons Atribución-NoComercial 4.0 Internacional (CC BY-NC 4.0)**

- **Atribución**: dar crédito al GovLab — Universidad de La Sabana.
- **No Comercial**: prohibido el uso con fines comerciales.

Consulta el archivo [LICENSE](LICENSE) para más detalles.

---

© 2026 Laboratorio de Gobierno — Universidad de La Sabana
