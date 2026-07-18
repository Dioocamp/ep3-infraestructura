# INSTRUCTIVO DE GRABACIÓN DETALLADO — cada clic, cada tecla, cada frase

Escrito para seguirlo sin saber nada previo. Tiempo total estimado:
**1 h de preparación + 1 h de rodaje + 1 h de voz y edición.**

> ⛔ **ANTES DE EMPEZAR:** este instructivo sirve solo si la Fase A del
> runbook ya está hecha (clúster Swarm corriendo en las 2 EC2, cola SQS,
> Lambda y API Gateway funcionando). Si no, primero ve a
> `docs/runbook-grabacion.md`, Fase A. Además, HOY, antes de grabar,
> ejecuta el pre-vuelo de la Fase B (credenciales frescas de AWS Academy).

**Cómo se usa este documento:** cada escena tiene:
- 🖥️ **HACES** — pasos numerados: qué abrir, qué escribir, dónde hacer clic.
- 👁️ **ESPERAS VER** — lo que debe aparecer en pantalla.
- 🚑 **SI FALLA** — qué hacer sin entrar en pánico.
- 🎙️ **DICES** — el texto que grabarás como voz sobre ese pedazo de video.

**El truco de grabar solo:** primero grabas la PANTALLA sin hablar
(micrófono apagado), haciendo los pasos con calma. La voz la grabas
DESPUÉS, encima del video, leyendo los 🎙️ DICES. Nunca haces las dos cosas
a la vez.

---

# PARTE 0 — Instalar y configurar el grabador (una vez, 20 min)

## 0.1 Instalar OBS Studio (graba la pantalla, gratis)

1. Abre Chrome → escribe en la barra: `obsproject.com` → Enter.
2. Clic en el botón **Windows** → se descarga el instalador.
3. Cuando termine, clic en el archivo descargado (esquina superior derecha
   de Chrome o carpeta Descargas) → Siguiente, Siguiente, Instalar, Finalizar.
4. Se abre OBS con un "Asistente de configuración automática":
   - Elige **"Optimizar solo para grabación"** → Siguiente → Siguiente →
     Aplicar configuración.
5. En la ventana principal de OBS, abajo hay un panel llamado **"Fuentes"**:
   - Clic en el **+** → elige **"Captura de pantalla"** → OK → OK.
   - Ahora OBS muestra tu pantalla completa en la vista previa.
6. Silencia el micrófono: en el panel **"Mezclador de audio"**, clic en el
   🔊 del canal "Mic/Aux" para que quede tachado (la voz va después).
7. ¿Dónde quedan los videos? Menú **Archivo → Mostrar grabaciones** te abre
   la carpeta (por defecto `C:\Users\dinko\Videos`).
8. Los botones que usarás: **"Iniciar grabación"** y **"Detener grabación"**
   (columna derecha). Pruébalo 10 segundos ahora y revisa que el archivo
   aparezca en la carpeta.

## 0.2 Instalar Clipchamp (editor de video, gratis de Microsoft)

1. Presiona la tecla **Windows** → escribe `Microsoft Store` → Enter.
2. En la Store, busca `Clipchamp` → **Obtener/Instalar**.
   (Alternativa si prefieres web: canva.com también sirve — la pauta sugiere
   Kaltura, Canva o Teams.)

---

# PARTE 1 — Preparar el "set" de ventanas (30 min, no se graba)

Vas a dejar 5 ventanas listas. Alterna entre ellas con **Alt+Tab**
(mantén Alt presionado y toca Tab hasta la ventana que quieres).

## 1.1 Ventana 1 — PowerShell "local"

1. Presiona la tecla **Windows** → escribe `powershell` → Enter.
2. Agranda la letra para el video: mantén **Ctrl** y mueve la **rueda del
   mouse** hacia arriba (o clic derecho en la barra de título →
   Propiedades → Fuente → tamaño 18 → Aceptar).
3. Copia y pega esta línea (para pegar en PowerShell: **clic derecho**
   dentro de la ventana) y presiona Enter:
   ```
   cd C:\Users\dinko\OneDrive\Documentos\Claude-Code\EP2-Microservicios
   ```
4. Limpia restos de ensayos anteriores (si dice que no existen, está bien):
   ```
   docker rm -f personal citas
   ```
5. Verifica que Docker Desktop esté corriendo: escribe `docker ps` → Enter.
   👁️ Debe responder con una tabla (aunque esté vacía).
   🚑 Si dice "error during connect": tecla Windows → escribe
   `Docker Desktop` → Enter → espera 2 min a que el ícono de la ballena en
   la barra de tareas deje de moverse → repite `docker ps`.

## 1.2 Ventana 2 — Visual Studio Code

1. Tecla **Windows** → escribe `Visual Studio Code` → Enter.
2. Menú **File → Open Folder** → navega a
   `C:\Users\dinko\OneDrive\Documentos\Claude-Code\EP2-Microservicios` →
   **Seleccionar carpeta**. (Si pregunta "¿Confías en los autores?" → Sí.)
3. En el panel izquierdo (explorador de archivos), abre estos 3 archivos
   haciendo clic (quedan como pestañas arriba):
   - `ep3-infraestructura` → `docker-compose.yml`
   - `ep3-infraestructura` → `lambda` → `notificador` → `lambda_function.py`
   - `ms-citas` → `README.md`
4. Agranda la letra: **Ctrl y +** (dos o tres veces).

## 1.3 Ventana 3 — Terminal SSH conectada al servidor (manager)

1. Necesitas 2 datos: la **IP pública del manager** (consola AWS → EC2 →
   Instances → clic en swarm-manager → campo "Public IPv4 address") y la
   ruta de tu llave `clinica-key.pem` (donde la descargaste, p. ej.
   `C:\Users\dinko\Downloads\clinica-key.pem`).
2. Abre OTRA ventana de PowerShell (tecla Windows → `powershell` → Enter).
3. Agranda la letra igual que antes (Ctrl + rueda).
4. Escribe (reemplaza la IP por la tuya) y Enter:
   ```
   ssh -i C:\Users\dinko\Downloads\clinica-key.pem ec2-user@IP_DEL_MANAGER
   ```
5. La primera vez pregunta "Are you sure you want to continue connecting?"
   → escribe `yes` → Enter.
   👁️ El prompt cambia a algo como `[ec2-user@ip-172-31-x-x ~]$` — ya estás
   DENTRO del servidor.
   🚑 Si dice "UNPROTECTED PRIVATE KEY FILE": ejecuta estas 2 líneas en
   PowerShell y reintenta el ssh:
   ```
   icacls C:\Users\dinko\Downloads\clinica-key.pem /inheritance:r
   icacls C:\Users\dinko\Downloads\clinica-key.pem /grant:r "dinko:R"
   ```
   🚑 Si se queda pegado sin responder: la instancia está apagada o la IP
   cambió → consola EC2 → Instance state → Start, y usa la IP nueva.
6. Ya conectado, escribe:
   ```
   cd ~/ep3-infraestructura
   ```

## 1.4 Ventana 4 — Chrome con 5 pestañas EN ESTE ORDEN

Abre Chrome y crea 5 pestañas (Ctrl+T abre cada nueva):

1. **Pestaña 1:** `github.com/Dioocamp/ms-citas` → clic en la pestaña
   **"Actions"** (barra superior del repo, al lado de "Pull requests").
2. **Pestaña 2:** primero entra a AWS: pestaña de AWS Academy → **Start
   Lab** → espera el punto 🟢 → clic en **"AWS"** (se abre la consola).
   En la barra de búsqueda de arriba escribe `SQS` → Enter → clic en
   **clinica-citas-queue** → clic en la pestaña **"Monitoring"**.
3. **Pestaña 3:** (Ctrl+T) barra de búsqueda AWS → `API Gateway` → Enter →
   clic en **clinica-gateway** → se ve el árbol de **Resources**.
4. **Pestaña 4:** (Ctrl+T) búsqueda → `Lambda` → Enter → clic en
   **clinica-notificador** → debe verse el diagrama con **SQS** a la
   izquierda como trigger.
5. **Pestaña 5:** `github.com/Dioocamp/ep3-infraestructura` → baja con la
   rueda hasta que el **diagrama de arquitectura** del README llene la
   pantalla. Esta pestaña es tu "lámina" de introducción.

Cambias de pestaña con **Ctrl+1, Ctrl+2, Ctrl+3, Ctrl+4, Ctrl+5**.

## 1.5 Ventana 5 — Segundo PowerShell "curl"

1. Otra ventana PowerShell más (tecla Windows → `powershell` → Enter),
   letra grande (Ctrl + rueda).
2. Define tus 3 variables. Copia estas líneas a un Bloc de notas primero,
   reemplaza los valores por LOS TUYOS, y pégalas (clic derecho) + Enter:
   ```
   $env:GW  = "https://TU-ID.execute-api.us-east-1.amazonaws.com/prod"
   $env:KEY = "TU-API-KEY"
   $env:IP  = "IP_PUBLICA_DEL_MANAGER"
   ```
   - `GW`: consola API Gateway → clinica-gateway → **Stages** → `prod` →
     copia el **Invoke URL**.
   - `KEY`: API Gateway → **API keys** (menú izquierdo) → clinica-key →
     **Show** → copia el valor.
   - `IP`: la misma del paso 1.3.

## 1.6 Datos base + prueba de fuego (decide si puedes grabar)

En la **Ventana 5**, pega y ejecuta de a una estas líneas (crean la
especialidad, el médico y la paciente si no existen; si ya existen dará
error de duplicado — no importa):

```
curl.exe -s -X POST "$env:GW/api/especialidades" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"nombre\":\"Cardiologia\",\"descripcion\":\"Especialidad del corazon\"}'
curl.exe -s -X POST "$env:GW/api/medicos" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"rut\":\"15111222-3\",\"nombre\":\"Carla\",\"apellido\":\"Soto\",\"email\":\"carla@clinica.cl\",\"registroSuperintendencia\":\"SIS-2001\",\"especialidadId\":1}'
curl.exe -s -X POST "$env:GW/api/pacientes" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"rut\":\"12345678-5\",\"nombre\":\"Ana\",\"apellido\":\"Rojas\",\"email\":\"ana@mail.cl\",\"telefono\":\"+56933333333\",\"fechaNacimiento\":\"1992-08-15\"}'
```

**PRUEBA DE FUEGO** (si esto no pasa, NO grabes todavía):

```
curl.exe -H "x-api-key: $env:KEY" "$env:GW/api/medicos"
```
👁️ Debe devolver un JSON con la doctora Carla Soto.
🚑 Si devuelve `{"message":"Forbidden"}`: la KEY está mala o falta Deploy
API. Si devuelve error 5xx: la IP del manager cambió → runbook Fase B
punto 2. Si no responde: el stack está caído → Ventana 3:
`docker service ls` y runbook tabla de fallas.

Y en la **Ventana 3** (SSH), refresca las credenciales para la escena 10:
```
bash scripts/actualizar-credenciales-aws.sh
```

**Todo listo. Respira. Empieza el rodaje.**

---

# PARTE 2 — RODAJE (pantalla sin voz, ~45 min con calma)

Consejo: graba TODO seguido en una sola toma larga; los errores y esperas
se cortan después en la edición. Si algo sale mal en una escena, respira,
arréglalo y repite esa escena sin detener OBS — luego cortas.

## ESCENA 1 · Introducción (30 s de imagen)

🖥️ **HACES:**
1. Ve a Chrome, **Ctrl+5** (pestaña del diagrama).
2. En OBS: clic **"Iniciar grabación"** (OBS se minimiza solo; si no,
   minimízalo tú).
3. Deja el diagrama en pantalla ~30 segundos. Mueve la rueda del mouse
   MUY suavemente arriba/abajo una vez para que no parezca imagen congelada.

🎙️ **DICES (lo grabarás después sobre este plano):**
> «Hola, soy Dinko Ocampo. En esta evaluación desplegué en la nube el
> sistema de microservicios de la clínica: dos servicios Spring Boot
> orquestados con Docker Swarm sobre dos instancias EC2, un pipeline CI/CD
> con GitHub Actions, y una arquitectura serverless con API Gateway, una
> cola SQS y una función Lambda. Veamos primero cómo se construyen los
> contenedores.»

## ESCENA 2 · Contenedores locales (IE2)

🖥️ **HACES:**
1. **Alt+Tab** a la Ventana 1 (PowerShell local).
2. Escribe (o pega con clic derecho) cada comando y Enter, esperando que
   termine uno antes del siguiente:
   ```
   docker build -t ms-personal-medico .\ms-personal-medico
   ```
   👁️ Corren líneas "#1, #2..." y termina en segundos (está cacheado del
   ensayo) con "naming to docker.io/library/ms-personal-medico".
   ```
   docker build -t ms-citas .\ms-citas
   ```
   ```
   docker network create clinica-local
   ```
   👁️ Devuelve un código largo. 🚑 Si dice "already exists", perfecto, sigue.
   ```
   docker run -d --name personal --network clinica-local -p 8081:8081 -e SPRING_PROFILES_ACTIVE=h2 ms-personal-medico
   ```
   ```
   docker run -d --name citas --network clinica-local -p 8082:8082 -e SPRING_PROFILES_ACTIVE=h2 -e MS_PERSONAL_MEDICO_URL=http://personal:8081 ms-citas
   ```
   👁️ Cada run devuelve un código largo = contenedor creado.
3. **Cuenta 25 segundos** (Spring arrancando — esta espera se corta luego).
4. Ahora los tres curl:
   ```
   curl.exe http://localhost:8081/api/medicos
   ```
   👁️ JSON con médicos (Ana Soto, Luis Perez...).
   ```
   curl.exe http://localhost:8082/api/citas
   ```
   👁️ JSON con citas sembradas.
   ```
   curl.exe http://localhost:8081/actuator/health
   ```
   👁️ `{"status":"UP","groups":["liveness","readiness"]}`.
   🚑 Si algún curl falla: espera 10 s más y repítelo. Si sigue:
   `docker logs citas` para ver el error (y esa toma la repites).

🎙️ **DICES:**
> «Cada microservicio tiene un Dockerfile multi-stage: una etapa compila con
> Maven y otra ejecuta solo el JAR sobre un JRE Alpine, con usuario no root
> y health check integrado. La imagen final es liviana y reproducible.
> Construyo ambas imágenes, levanto los contenedores y valido los endpoints:
> médicos responde en el puerto 8081, citas en el 8082, y el health check
> reporta estado UP.»

## ESCENA 3 · Compose + Swarm (IE3, IE7)

🖥️ **HACES:**
1. **Alt+Tab** a VS Code, pestaña `docker-compose.yml`.
2. Baja despacio con la rueda. Con el mouse, **selecciona** (clic y
   arrastra, queda azul) cada una de estas líneas, una por una, dejándolas
   1-2 segundos seleccionadas:
   - `replicas: 2`
   - el bloque `restart_policy:`
   - el bloque `resources:` → `limits:`
   - al final: `driver: overlay`
3. **Alt+Tab** a la Ventana 3 (SSH) y ejecuta:
   ```
   docker node ls
   ```
   👁️ 2 filas: una con MANAGER STATUS "Leader" y otra vacía (el worker),
   ambas STATUS "Ready".
   ```
   docker service ls
   ```
   👁️ 3 servicios: mysql `1/1`, ms-personal-medico `2/2`, ms-citas `2/2`.
   ```
   docker service ps clinica_ms-citas
   ```
   👁️ 2 réplicas "Running", una en cada NODE (hostnames distintos).
   🚑 Si algo está `0/2`: `docker service ps <nombre>` para ver el motivo;
   lo típico es MySQL arrancando → espera 2 min y repite.

🎙️ **DICES:**
> «El docker-compose, en versión 3.8 compatible con Swarm, define los dos
> microservicios con dos réplicas cada uno, política de reinicio ante
> fallos, límites de CPU y memoria, y una red overlay que comunica los
> contenedores entre nodos. Las imágenes vienen de Docker Hub, publicadas
> por el pipeline. El clúster tiene un nodo manager y un worker; al
> desplegar el stack, Swarm distribuye las réplicas entre ambos nodos, como
> se ve acá: hay réplicas de citas corriendo en el manager y en el worker.»

## ESCENA 4 · Pipeline CI/CD en vivo (IE6) — en dos partes

🖥️ **HACES (parte 1):**
1. **Alt+Tab** a VS Code, pestaña `README.md` de ms-citas.
2. Ve al final del archivo (Ctrl+End) y escribe en una línea nueva:
   `Despliegue continuo verificado en la EP3.` → guarda con **Ctrl+S**.
3. **Alt+Tab** a Ventana 1 (PowerShell local) y ejecuta:
   ```
   cd ms-citas
   git add .
   git commit -m "docs: verificacion de despliegue continuo"
   git push
   ```
   👁️ El push termina con algo como `main -> main`.
4. **Alt+Tab** a Chrome, **Ctrl+1** (Actions) → presiona **F5**.
   👁️ Aparece arriba "docs: verificacion de despliegue continuo" con un
   círculo amarillo girando. Clic en él: se ven los 3 jobs.
5. **En OBS: clic "Detener grabación"** (pausa real del rodaje).
6. Espera 4-6 minutos. Refresca (F5) hasta que los 3 jobs tengan ✓ verde.
   🚑 Si un job sale ✗ rojo: clic en él, lee la línea roja del log. Lo más
   común: token de Docker Hub mal puesto (job docker-push) o clave SSH
   (deploy-swarm) → corrige el secret (Settings → Secrets → Actions) →
   botón "Re-run failed jobs". Cuando esté verde, sigues.

🖥️ **HACES (parte 2):**
7. **En OBS: "Iniciar grabación"** de nuevo.
8. En Actions (verde): clic en el job **docker-push** para que se vea 2
   segundos su detalle, vuelve atrás.
9. **Alt+Tab** a Ventana 5:
   ```
   curl.exe -H "x-api-key: $env:KEY" "$env:GW/api/citas"
   ```
   👁️ JSON con citas → tu cambio ya corre EN LA NUBE.

🎙️ **DICES:**
> «Ahora el ciclo completo de integración y despliegue continuo. Hago un
> commit y push a main... y GitHub Actions dispara el pipeline: primera
> etapa, build y pruebas con Maven, que publica el reporte de tests como
> artefacto para trazabilidad; segunda, construye la imagen Docker y la sube
> a Docker Hub con dos tags, latest y el SHA del commit; tercera, se conecta
> por SSH al manager y actualiza el servicio en Swarm, sin intervención
> manual. El endpoint en la nube ya responde con el cambio desplegado.»

## ESCENA 5 · Escalado (IE8)

🖥️ **HACES:**
1. Pon dos ventanas lado a lado: clic en la Ventana 3 (SSH) y presiona
   **Windows + flecha izquierda**; clic en la Ventana 5 y
   **Windows + flecha derecha**.
2. En la mitad izquierda (SSH):
   ```
   docker service scale clinica_ms-citas=4
   ```
   👁️ Barras de progreso hasta "verify: Service converged".
   ```
   docker service ps clinica_ms-citas
   ```
   👁️ 4 réplicas Running repartidas entre los 2 nodos.
3. En la mitad derecha (curl), 2-3 veces:
   ```
   curl.exe -s -o NUL -w "%{http_code}" -H "x-api-key: $env:KEY" "$env:GW/api/citas"
   ```
   👁️ Imprime `200` cada vez.
4. Izquierda:
   ```
   docker service scale clinica_ms-citas=1
   ```
   Derecha: otro curl → `200`.
5. Izquierda:
   ```
   docker service scale clinica_ms-citas=2
   ```
   🚑 Si al escalar a 4 una réplica queda "Pending": memoria justa del
   t3.small — repite la toma escalando a 3 (y en la narración di "tres").

🎙️ **DICES:**
> «Simulo un aumento de demanda: escalo citas de dos a cuatro réplicas con
> un solo comando. Swarm programa las nuevas réplicas en ambos nodos y el
> servicio nunca deja de responder, como muestra la petición en paralelo.
> Ante baja demanda escalo hacia abajo a una réplica, y el sistema sigue
> disponible. Vuelvo a dos, el estado normal.»

## ESCENA 6 · Justificación técnica (IE9)

🖥️ **HACES:**
1. Chrome, **Ctrl+5** → baja con la rueda hasta la sección
   **"Decisiones técnicas (resumen para IE9)"** del README.
2. Scroll MUY lento por los bullets durante ~40 segundos. Nada más.

🎙️ **DICES:**
> «Las decisiones del clúster responden a tres requisitos. Escalabilidad:
> los microservicios son sin estado, así que las réplicas se ajustan en
> segundos y la red overlay balancea las peticiones entre nodos.
> Disponibilidad: con dos nodos y política de reinicio ante fallos, la caída
> de un contenedor —o de un nodo completo— no interrumpe el servicio, y el
> update start-first despliega sin downtime. Mantenibilidad: las imágenes se
> versionan por SHA de commit, lo que hace cada despliegue trazable y el
> rollback trivial, y toda la configuración vive en variables de entorno,
> nunca en el código.»

## ESCENA 7 · La cola SQS (IE11)

🖥️ **HACES:**
1. Chrome, **Ctrl+2** (SQS → Monitoring).
2. Pasa el cursor lentamente sobre los gráficos **"Number Of Messages
   Sent"** y **"Number Of Messages Received"**.
3. Clic en la pestaña **"Details"** 3 segundos (se ve nombre y ARN) y
   vuelve a Monitoring.

🎙️ **DICES:**
> «Esta es la cola clinica-citas-queue, creada de forma idempotente por la
> etapa de provisión del pipeline. Su propósito es desacoplar el
> agendamiento de la notificación al paciente: crear la cita es síncrono y
> crítico; notificar es asíncrono y tolerante a fallos. Si el consumidor
> está caído, los mensajes esperan en la cola y no se pierde ninguna
> notificación, con reintentos automáticos por lote parcial.»

## ESCENA 8 · API Gateway (IE12)

🖥️ **HACES:**
1. Chrome, **Ctrl+3**: que se vea 3 segundos el árbol de recursos
   (/api/citas, /api/medicos...). Clic en **Usage plans** (menú izquierdo)
   2 segundos, vuelve a Resources.
2. **Alt+Tab** a Ventana 5 (pantalla completa: Windows + flecha arriba) y
   ejecuta de a uno:
   ```
   curl.exe -i "$env:GW/api/medicos"
   ```
   👁️ Primera línea: `HTTP/1.1 403 Forbidden` y `{"message":"Forbidden"}`.
   ```
   curl.exe -i -H "x-api-key: $env:KEY" "$env:GW/api/medicos"
   ```
   👁️ `HTTP/1.1 200 OK` + el JSON de médicos.
   ```
   curl.exe -i "http://$($env:IP):8081/api/medicos"
   ```
   👁️ `HTTP/1.1 401` — bloqueado por el filtro del microservicio.
   🚑 Si el 2º da 500/502: la IP del manager cambió desde que configuraste
   el Gateway → corta el rodaje, runbook Fase B punto 2, regraba la escena.

🎙️ **DICES:**
> «Todo el acceso externo entra por API Gateway. La protección tiene dos
> capas: el Gateway exige una API key con plan de uso y throttling —sin
> ella, 403—, y además inyecta una cabecera secreta hacia el backend, que un
> filtro en ambos microservicios valida. Por eso el acceso directo a la
> instancia devuelve 401: el Gateway es la única puerta de entrada al
> sistema.»

## ESCENA 9 · La Lambda (IE13, IE14)

🖥️ **HACES:**
1. **Alt+Tab** a VS Code, pestaña `lambda_function.py`.
2. Selecciona con el mouse (2 s cada una): la línea
   `CAMPOS_OBLIGATORIOS = (...)` y la línea
   `return {"batchItemFailures": fallidos}`.
3. **Alt+Tab** a Chrome, **Ctrl+4** (Lambda): que se vea el diagrama con
   **SQS** conectado a la izquierda de clinica-notificador (~5 s).

🎙️ **DICES:**
> «El consumidor de la cola es la función serverless clinica-notificador, en
> Python. Recibe los lotes del trigger SQS, valida el contrato del mensaje y
> registra la notificación con logging estructurado. Si un mensaje del lote
> falla, devuelve batchItemFailures y SQS reintenta solo ese mensaje: manejo
> parcial de errores, una buena práctica de FaaS.»

## ESCENA 10 · Prueba end-to-end + cierre (IE15)

🖥️ **HACES:**
1. Ventana 5 (pantalla completa):
   ```
   curl.exe -i -X POST "$env:GW/api/citas" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"fecha\":\"2026-08-20\",\"hora\":\"10:30\",\"motivo\":\"Control cardiologico\",\"medicoId\":1,\"pacienteId\":1}'
   ```
   👁️ `HTTP/1.1 201` y un JSON con `"estado":"PROGRAMADA"`.
   🚑 Si da 404/422: faltan los datos base → vuelve a Parte 1.6.
2. **Alt+Tab** a Ventana 3 (SSH):
   ```
   aws logs tail /aws/lambda/clinica-notificador --since 2m
   ```
   👁️ (Tarda 5-15 s; si sale vacío, espera 10 s y repite el comando.)
   Una línea JSON con `"evento": "notificacion_enviada"` y el mensaje
   «Estimado/a Ana Rojas...».
   🚑 Si tras 2 intentos no aparece: credenciales vencidas →
   `bash scripts/actualizar-credenciales-aws.sh`, espera 1 min, repite el
   POST del paso 1 y este tail (la toma se repite).
3. Chrome **Ctrl+5** (diagrama) 3 segundos — plano de cierre.
4. **OBS: "Detener grabación".** Fin del rodaje. 🎬

🎙️ **DICES:**
> «La prueba completa: agendo una cita como cliente externo, por el Gateway.
> Citas valida el médico contra personal-médico, persiste en MySQL y publica
> el evento en SQS... y en los logs de CloudWatch la Lambda ya registró la
> notificación a la paciente. Petición externa, microservicios, cola y
> serverless: el flujo completo, funcionando en la nube.
> En resumen: contenedores optimizados, orquestación con réplicas y
> tolerancia a fallos, despliegue continuo sin intervención manual y una
> arquitectura asíncrona y serverless que escala. Gracias por ver.»

---

# PARTE 3 — Voz y edición en Clipchamp (~1 h)

1. Tecla Windows → `Clipchamp` → Enter → **Create a new video**.
2. Botón **Import media** → navega a `C:\Users\dinko\Videos` → elige tu(s)
   grabación(es) de OBS → arrástralas a la línea de tiempo (abajo).
3. **Cortar lo que sobra:** mueve la aguja al inicio de un tramo malo
   (espera de Spring, error, pipeline corriendo) → clic en el clip → botón
   de **tijeras** (Split) → repite al final del tramo → clic en el pedazo
   del medio → tecla **Supr**. Repite con cada tramo muerto.
4. **Grabar tu voz:** ponte los audífonos con micrófono. En el panel
   izquierdo: **Record & create → Audio** → botón rojo → se graba MIENTRAS
   ves el video correr → lee el 🎙️ DICES de la escena que está en pantalla
   → detén al final de la escena → **Save and edit** (el audio cae a la
   línea de tiempo). Hazlo escena por escena (10 clips de voz cortos es más
   fácil que uno largo). Arrastra cada clip de audio para alinearlo con su
   escena.
5. Revisa la duración total (esquina de la línea de tiempo): debe quedar
   **entre 3:00 y 8:00** (apunta a ~7:00). ¿Muy largo? Corta más esperas y
   tipeos. ¿Muy corto? No pasa nada mientras superes 3:00 y estén las 10
   escenas.
6. **Escucha TODO de principio a fin con audífonos.** Volumen parejo, sin
   ruido, sin silencios raros. Si una escena de voz salió mal: clic en ese
   clip de audio → Supr → grábala de nuevo (paso 4).
7. **Exportar:** botón **Export** (arriba derecha) → **1080p** → espera →
   el `.mp4` queda en Descargas. Renómbralo:
   `EP3_JVY0101_Dinko_Ocampo.mp4`.
8. **Entregar:**
   - Sube el mp4 al AVA (la actividad de la EP3) y envíalo también al
     correo del docente (si pesa mucho: súbelo a tu Drive → clic derecho →
     Compartir → "Cualquier persona con el enlace" → pega el enlace en el
     correo).
   - En la MISMA entrega del AVA y el MISMO correo, pega los 3 enlaces:
     `github.com/Dioocamp/ms-personal-medico`,
     `github.com/Dioocamp/ms-citas`,
     `github.com/Dioocamp/ep3-infraestructura`.
   - Antes de cerrar: pestaña Actions de cada microservicio EN VERDE
     (la última ejecución visible).

**Listo. Entregaste con todo verificado. 🎓**
