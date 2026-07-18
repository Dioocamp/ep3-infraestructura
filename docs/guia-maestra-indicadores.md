# GUÍA MAESTRA EP3 — Los 17 indicadores al 100%

Para cada indicador: **qué exige la pauta al 100% → qué lo cumple (ya
construido) → cómo se demuestra → el error que te baja puntos.**
Al final, la ruta completa desde hoy hasta la entrega.

Estado actual: ✅ = ya hecho y verificado · 🔧 = falta acción tuya en AWS/grabación.

---

## DIMENSIÓN ENCARGO (50%) — se evalúa mirando los repos de GitHub

### IE1 — Dockerfile funcional y optimizado (10%) ✅

**Pauta al 100%:** "claro, funcional y altamente optimizado, siguiendo buenas
prácticas de eficiencia y seguridad. Imágenes reproducibles y livianas que se
ejecutan correctamente y exponen los endpoints esperados."

**Lo cumple:** `Dockerfile` en cada microservicio con:
- Multi-stage: compila con `maven:3.9-eclipse-temurin-17`, ejecuta solo el JAR
  en `eclipse-temurin:17-jre-alpine` (eficiencia + liviandad).
- `USER clinica` sin privilegios (seguridad — lo que casi todos omiten).
- Capa de dependencias cacheada (`pom.xml` + `dependency:go-offline` antes de `src/`).
- `HEALTHCHECK` contra `/actuator/health` + `EXPOSE` correcto.
- `.dockerignore` por servicio; toda la config por variables de entorno.
- **Verificado en tu máquina:** imágenes de 368 MB y 389 MB, contenedores
  `healthy`, endpoints respondiendo.

**Se demuestra:** el docente abre el Dockerfile en GitHub; tú además lo
muestras funcionando en la escena 2 del video.
**Error a evitar:** tocar el Dockerfile a última hora sin reconstruir y probar.

### IE4 — Pipeline CI/CD configurado (10%) ✅ (verde tras secrets 🔧)

**Pauta al 100%:** "completamente automatizado y documentado. Build, test y
despliegue sin intervención manual, con integración continua fluida y
trazabilidad."

**Lo cumple:** `.github/workflows/ci-cd.yml` en cada microservicio:
1. `build-test`: Maven `clean verify` + **reporte de tests subido como
   artifact** (esa es la "trazabilidad" textual de la pauta).
2. `docker-push`: imagen a Docker Hub con tags `latest` **y SHA del commit**.
3. `deploy-swarm`: SSH al manager y `docker service update` con el tag SHA.
- `develop` solo compila y testea; `main` despliega — flujo documentado en el
  encabezado del YAML y en el README.

**Se demuestra:** pestaña Actions en verde (tras configurar secrets, paso A3).
**Error a evitar:** dejar la última ejecución en rojo el día de la revisión —
haz un push trivial final para que lo último visible esté verde.

### IE5 — Etapas de provisión cloud en el pipeline (10%) ✅ (correr 🔧)

**Pauta al 100%:** "incluye y documenta todas las etapas necesarias para la
provisión y configuración automatizada de servicios cloud (bases de datos,
colas, almacenamiento), asegurando integración y funcionamiento correcto."

**Lo cumple:** job `provision-cloud` del repo infraestructura que ejecuta
`infra/provision.sh` (IaC versionado): crea idempotentemente la cola SQS
`clinica-citas-queue`, la Lambda `clinica-notificador` y el trigger con
`ReportBatchItemFailures`. La BD corre como servicio del stack Swarm (no es
servicio cloud aparte) — eso está justificado por escrito en el README.

**Se demuestra:** ejecución verde del job + los recursos visibles en la
consola AWS.
**Error a evitar:** correr el pipeline con los secrets de AWS Academy
vencidos (rotan cada sesión → actualizarlos antes).

### IE7 — Clúster Swarm: archivos, nodos, documentación (10%) ✅ (crear clúster 🔧)

**Pauta al 100%:** "correctamente configurado, con integración de nodos
manager y worker y despliegue exitoso de servicios distribuidos usando
archivos de definición bien estructurados y documentados."

**Lo cumple:** `docker-compose.yml` v3.8 (deploy, réplicas, restart_policy,
límites de recursos, overlay), `scripts/init-swarm.sh`, `scripts/join-worker.sh`,
`scripts/deploy-stack.sh`, y el README con las secciones **"Inicializar el
clúster"**, **"Añadir nodos manager y worker"** y **"Desplegar servicios
distribuidos"** (la pauta pide esa documentación textualmente).

**Se demuestra:** los archivos en GitHub + `docker node ls` con 2 nodos Ready
en el video.
**Error a evitar:** SG sin los puertos internos de Swarm (2377/7946/4789) —
el join falla y pierdes tiempo en cámara.

### IE10 — Función serverless: código + despliegue + prueba (10%) ✅ (desplegar 🔧)

**Pauta al 100%:** "alineadas a requerimientos funcionales del sistema,
asegurando correcta integración, documentación y despliegue, así como buen
uso de prácticas de FaaS."

**Lo cumple:** `lambda/notificador/` con:
- `lambda_function.py`: validación del contrato, **logging estructurado JSON**
  y **`batchItemFailures`** (manejo parcial de errores — la práctica FaaS que
  separa el 100% del 60%). Probada localmente con evento válido e inválido.
- `evento-ejemplo.json` (formato SQS real), `requirements.txt`, y README con
  **instrucciones exactas de despliegue y prueba** (la pauta las exige).
- Alineación funcional clara: notificar al paciente cuando se agenda su cita.

**Se demuestra:** carpeta en GitHub + `aws lambda invoke` con el evento de
ejemplo → `{"batchItemFailures": []}`.
**Error a evitar:** desplegarla y no probarla nunca por la cola real.

---

## DIMENSIÓN PRESENTACIÓN (50%) — se evalúa viendo el video

### IE2 — Contenedores locales + endpoints (5%) ✅ ensayado

**Pauta al 100%:** "genera contenedores de todos los microservicios en
entorno local, validando exitosamente el acceso a los endpoints."
**Lo cumple:** escena 2 — ya la ejecuté completa en tu máquina: build de las
2 imágenes, red `clinica-local`, ambos contenedores healthy, curl a
`/api/medicos`, `/api/citas`, `/actuator/health`, y POST de cita validando el
médico entre contenedores.
**En el video:** muestra los DOS microservicios (la pauta dice "todos").
**Error a evitar:** hacer curl antes de que Spring arranque (~20 s).

### IE3 — Compose compatible Swarm explicado (5%) ✅ (demo 🔧)

**Pauta al 100%:** "correctamente estructurado y permite desplegar todos los
microservicios en diferentes contenedores bajo Swarm, sin errores."
**En el video (escena 3):** recorre el YAML señalando `deploy.replicas`,
`restart_policy`, `resources.limits`, red `overlay`, imágenes desde Docker
Hub — y muestra `docker service ls` con 2/2.
**Error a evitar:** leer el archivo entero línea por línea; señala las 4
claves de Swarm y avanza.

### IE6 — Pipeline en acción, commit→nube (5%) 🔧

**Pauta al 100%:** "despliegan correctamente todos los microservicios,
demostrando su funcionamiento completo en la nube."
**En el video (escena 4):** commit trivial → push → Actions con las 3 etapas
→ curl al endpoint en la nube respondiendo. Truco del runbook: graba el
inicio, pausa mientras corre (4-6 min), graba el final verde.
**Error a evitar:** improvisar si sale rojo — corta, arregla, regraba.

### IE8 — Escalado dinámico de réplicas (5%) 🔧

**Pauta al 100%:** "ajustando dinámicamente el número de réplicas,
demostrando escalabilidad eficiente y funcionamiento bajo distintos
escenarios de carga."
**En el video (escena 5):** `scale=4` → `service ps` (réplicas en ambos
nodos) → `scale=1` → `scale=2`, con un curl respondiendo en paralelo todo el
tiempo. La pauta pide "arriba **o** abajo"; mostrar ambos + servicio vivo es
lo que sella el 100% ("distintos escenarios").
**Error a evitar:** escalar a 4 en instancias sin memoria → réplica `Pending`
en cámara (si pasa: narra el límite de recursos como decisión, o usa 3).

### IE9 — Argumentación de decisiones técnicas (5%) ✅ guion listo

**Pauta al 100%:** "argumenta sólidamente todas las decisiones, justificando
cómo la configuración satisface escalabilidad, disponibilidad y
mantenibilidad."
**Lo cumple:** escena 6 del guion — un párrafo por cada uno de los TRES
requisitos (la pauta los nombra y hay que nombrarlos): escalabilidad =
réplicas sin estado + overlay; disponibilidad = 2 nodos + restart_policy +
start-first; mantenibilidad = imágenes por SHA + config en variables de
entorno. Respaldo escrito: sección "Decisiones técnicas" del README.
**Error a evitar:** quedarse en "usé Swarm porque es fácil" — nombra los tres
criterios explícitamente.

### IE11 — Cola en la nube con propósito (6%) 🔧

**Pauta al 100%:** "define una cola en la nube, demostrando su uso efectivo
para gestionar un requerimiento asíncrono con documentación clara."
**En el video (escena 7):** consola SQS con `clinica-citas-queue` + su
Monitoring, y el argumento: desacopla el agendamiento (síncrono, crítico) de
la notificación (asíncrona, tolerante a fallos); si el consumidor cae, los
mensajes esperan.
**Error a evitar:** mostrar la cola sin explicar QUÉ requerimiento resuelve —
el propósito vale más que la pantalla.

### IE12 — API Gateway protege el backend (4%) 🔧

**Pauta al 100%:** "controlando el acceso y protegiendo **todos** los
componentes del backend."
**Lo cumple:** REST API con **dos capas**: API key + usage plan (sin key →
403) y cabecera secreta `x-gateway-secret` que el `GatewaySecretFilter` de
**ambos** microservicios exige (acceso directo → 401). Las 8 rutas de los dos
servicios pasan por el Gateway.
**En el video (escena 8):** los 3 curl → 403, 200, 401. Tres códigos
distintos = dos capas de protección demostradas en 30 segundos.
**Error a evitar:** proteger solo `/citas` — el 100% exige TODOS los
componentes (por eso el filtro está en los dos microservicios).

### IE13 — Integración de la función serverless (5%) 🔧

**Pauta al 100%:** "integra correctamente funciones serverless con
microservicios u otros servicios cloud, demostrando interacción funcional y
documentación."
**En el video (escena 9):** el código de la Lambda (señala
`batchItemFailures`), el trigger SQS en la consola, y una ejecución real en
CloudWatch Logs.
**Error a evitar:** mostrar solo el código sin una ejecución real.

### IE14 — Productor y consumidor por la cola, E2E (2%) 🔧

**Pauta al 100%:** "conectando correctamente componentes productores y
consumidores, y demostrando el flujo de mensajes end-to-end."
**Lo cumple:** productor = `ms-citas` (`NotificadorCitas` publica
`CITA_CREADA` al crear cita); consumidor = la Lambda vía trigger.
**En el video:** queda demostrado dentro de la escena 10 (POST → métrica SQS
→ log de la Lambda).
**Error a evitar:** credenciales AWS vencidas en ms-citas → el POST da 201
pero nada llega a la cola (ejecuta `actualizar-credenciales-aws.sh` antes).

### IE15 — Prueba end-to-end con escalabilidad (3%) 🔧

**Pauta al 100%:** "pruebas completas de extremo a extremo, demostrando la
escalabilidad y correcta respuesta de todo el sistema distribuido bajo
distintas condiciones."
**En el video (escena 10):** POST por el Gateway (201) → validación
inter-microservicios → MySQL → SQS → Lambda → CloudWatch, y el sistema
respondiendo mientras escalaste en la escena 5. Guion exacto en
`docs/prueba-e2e.md`.
**Error a evitar:** olvidar crear los datos base antes (especialidad, médico,
paciente) — sin ellos el POST devuelve 404/422 en cámara.

### IE16 — Orden, hilo conductor, lenguaje técnico (3%) ✅ guion listo

**Pauta al 100%:** "claramente estructurado, con introducción, desarrollo y
cierre; coherente, fluido, con uso adecuado del lenguaje técnico."
**Lo cumple:** el guion tiene intro (arquitectura) → desarrollo (local →
clúster → CI/CD → serverless) → cierre (E2E + resumen), y usa el vocabulario
que la pauta espera oír: *orquestación, réplicas, overlay, idempotente,
trigger, trazabilidad, rollback, desacoplar*.
**Error a evitar:** saltarte la intro o el cierre por apuro — son los 3
puntos más baratos del video.

### IE17 — Audio claro y sin ruido (2%) 🔧

**Pauta al 100%:** "audio completamente claro, con volumen estable y sin
interferencias."
**Cómo:** audífonos con micrófono, pieza en silencio, y —trabajando solo—
graba primero las demos SIN voz y narra encima después viendo el video.
Escucha el resultado completo antes de exportar.
**Error a evitar:** narrar mientras tipeas comandos: se nota el estrés y el
teclado en el micrófono.

---

## RUTA COMPLETA (dónde estás y qué sigue)

**Ya hecho y verificado ✅**
1. Código EP3 completo: 20 tests verdes, Dockerfiles probados con build+run
   real, filtro de gateway, publicador SQS, Lambda probada localmente.
2. Los 3 repos publicados en GitHub con ramas, tags y toda la documentación.
3. Docker Desktop operativo en tu máquina; demo local (escena 2) ensayada.
4. Guion narrador único + runbook + esta guía, en repo y Drive.

**Te falta (runbook `docs/runbook-grabacion.md` en detalle):**

| # | Paso | Runbook | Tiempo | Indicadores que activa |
|---|---|---|---|---|
| 1 | Correo al docente confirmando entrega individual | — | 5 min | valida IE16/IE17 |
| 2 | Docker Hub: cuenta + token | A2 | 5 min | IE4 |
| 3 | Secrets en los 3 repos + re-run pipelines → verdes | A3 | 15 min | IE4 |
| 4 | 2 EC2 + Security Group + Docker instalado | A4 | 25 min | IE7 |
| 5 | `init-swarm.sh` + `join-worker.sh` → `docker node ls` | A5 | 5 min | IE7 |
| 6 | `provision.sh` → SQS + Lambda + trigger | A6 | 5 min | IE5, IE10 |
| 7 | Editar compose (3 valores) + push → stack desplegado | A7 | 10 min | IE3, IE5 |
| 8 | API Gateway por consola + Deploy a `prod` | A8 | 40 min | IE12 |
| 9 | Verificación total: 403/200/401 + E2E completa | A9 | 15 min | IE14, IE15 |
| 10 | Pre-vuelo del día de grabación (checklist 11 puntos) | B | 30 min | todos |
| 11 | Grabar por escenas con plan B + editar + exportar mp4 | C | 2–3 h | IE2–IE17 |
| 12 | Entregar: 3 enlaces GitHub en AVA + correo; mp4 en AVA + correo | checklist | 15 min | — |

**Total estimado: una tarde para 1–9, y otra sesión para 10–12.**

Regla final: **nada entra al video sin haberlo ejecutado en seco 5 minutos
antes.** Con eso, no hay sorpresas — solo confirmaciones.
