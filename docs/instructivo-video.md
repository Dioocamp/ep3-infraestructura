# INSTRUCTIVO DE GRABACIÓN — acción por acción + narración

Método (grabando solo): **primero grabas la pantalla SIN hablar** siguiendo
los pasos 🖥️ HACES de cada escena. Después reproduces tu grabación y grabas
la voz encima leyendo 🎙️ DICES. Al final cortas pausas y exportas. Así nunca
tienes que tipear y hablar a la vez.

Requisito previo: Fase A del runbook completada (Swarm desplegado, SQS,
Lambda y Gateway funcionando) y pre-vuelo Fase B hecho (credenciales
frescas, datos base creados, ensayo en seco).

---

## PREPARAR EL SET (15 min, no se graba)

1. **Grabador de pantalla:** abre OBS Studio (o la grabadora que uses) →
   fuente: pantalla completa. Micrófono SILENCIADO (la voz va después).
2. **Ventana 1 — PowerShell local:**
   `cd C:\Users\dinko\OneDrive\Documentos\Claude-Code\EP2-Microservicios`
   y limpia restos de ensayos: `docker rm -f personal citas` (ignora el
   error si no existen).
3. **Ventana 2 — VS Code:** abre la carpeta `EP2-Microservicios` con tres
   pestañas listas: `ep3-infraestructura/docker-compose.yml`,
   `ep3-infraestructura/lambda/notificador/lambda_function.py`, y el
   `README.md` de ms-citas (para el cambio trivial de la escena 4).
4. **Ventana 3 — SSH al manager:** conéctate ya
   (`ssh -i clinica-key.pem ec2-user@IP_MANAGER`) y déjala en
   `cd ~/ep3-infraestructura`.
5. **Ventana 4 — Chrome con 5 pestañas, en este orden:**
   1. github.com/Dioocamp/ms-citas → pestaña **Actions**
   2. Consola AWS → **SQS** → clinica-citas-queue → pestaña *Monitoring*
   3. Consola AWS → **API Gateway** → clinica-gateway → *Resources*
   4. Consola AWS → **Lambda** → clinica-notificador (se ve el trigger SQS)
   5. github.com/Dioocamp/ep3-infraestructura → README a la altura del
      **diagrama de arquitectura** (esta pestaña es tu "lámina" de intro)
6. **Ventana 5 — segundo PowerShell** para los curl. Define las variables
   (usa TUS valores reales):
   ```powershell
   $env:GW  = "https://TU-ID.execute-api.us-east-1.amazonaws.com/prod"
   $env:KEY = "TU-API-KEY"
   $env:IP  = "IP_PUBLICA_MANAGER"
   ```
7. Prueba de fuego (30 s): `curl.exe -H "x-api-key: $env:KEY" "$env:GW/api/medicos"`
   → debe dar 200 con el médico. Si no, NO grabes: vuelve a Fase B.

> Alterna ventanas con **Alt+Tab** (o Win+número si están ancladas a la
> barra). Sube el tamaño de fuente de las terminales a 16-18 pt antes de
> partir: se graba para verse en pantalla completa.

---

## ESCENA 1 · Introducción (graba 30 s de pantalla quieta)

🖥️ **HACES:**
1. Ventana 4, pestaña 5 (README con el diagrama de arquitectura).
2. Inicia la grabación. Deja el diagrama visible 30 segundos, moviendo
   suavemente el scroll para que se vea vivo.

🎙️ **DICES (voz en off sobre ese plano):**
> «Hola, soy Dinko Ocampo. En esta evaluación desplegué en la nube el
> sistema de microservicios de la clínica: dos servicios Spring Boot
> orquestados con Docker Swarm sobre dos instancias EC2, un pipeline CI/CD
> con GitHub Actions, y una arquitectura serverless con API Gateway, una
> cola SQS y una función Lambda. Veamos primero cómo se construyen los
> contenedores.»

## ESCENA 2 · Docker local (≈1 min de metraje)

🖥️ **HACES:** Ventana 1 (PowerShell local). Escribe, dando 2-3 segundos
entre comandos para que se lean:

```powershell
docker build -t ms-personal-medico .\ms-personal-medico
docker build -t ms-citas .\ms-citas
docker network create clinica-local
docker run -d --name personal --network clinica-local -p 8081:8081 -e SPRING_PROFILES_ACTIVE=h2 ms-personal-medico
docker run -d --name citas --network clinica-local -p 8082:8082 -e SPRING_PROFILES_ACTIVE=h2 -e MS_PERSONAL_MEDICO_URL=http://personal:8081 ms-citas
```
*(cuenta 20 segundos en silencio — Spring arrancando; puedes cortar esa
espera en la edición)*
```powershell
curl.exe http://localhost:8081/api/medicos
curl.exe http://localhost:8082/api/citas
curl.exe http://localhost:8081/actuator/health
```

**Esperas ver:** los build terminan en segundos (cache), los dos primeros
curl devuelven JSON con datos, el último `{"status":"UP",...}`.
**Si falla:** `docker logs citas` — casi siempre es que faltó esperar.

🎙️ **DICES:**
> «Cada microservicio tiene un Dockerfile multi-stage: una etapa compila con
> Maven y otra ejecuta solo el JAR sobre un JRE Alpine, con usuario no root
> y health check integrado. La imagen final es liviana y reproducible.
> Construyo ambas imágenes, levanto los contenedores y valido los endpoints:
> médicos responde en el puerto 8081, citas en el 8082, y el health check
> reporta estado UP.»

## ESCENA 3 · Compose + Swarm (≈1 min)

🖥️ **HACES:**
1. Ventana 2 (VS Code), pestaña `docker-compose.yml`. Baja despacio y
   **selecciona con el mouse** (para resaltarlas en pantalla) estas líneas,
   en orden: `replicas: 2` → `restart_policy` → `resources.limits` →
   `driver: overlay`.
2. Alt+Tab a Ventana 3 (SSH manager) y escribe:
```bash
docker node ls
docker service ls
docker service ps clinica_ms-citas
```

**Esperas ver:** 2 nodos `Ready` (manager Leader + worker); réplicas `1/1` y
`2/2`; y en `service ps` réplicas repartidas entre ambos hostnames.

🎙️ **DICES:**
> «El docker-compose, en versión 3.8 compatible con Swarm, define los dos
> microservicios con dos réplicas cada uno, política de reinicio ante
> fallos, límites de CPU y memoria, y una red overlay que comunica los
> contenedores entre nodos. Las imágenes vienen de Docker Hub, publicadas
> por el pipeline. El clúster tiene un nodo manager y un worker; al
> desplegar el stack, Swarm distribuye las réplicas entre ambos nodos, como
> se ve acá: hay réplicas de citas corriendo en el manager y en el worker.»

## ESCENA 4 · Pipeline CI/CD (se graba en 2 partes)

🖥️ **HACES (parte 1):**
1. Ventana 2 (VS Code), README de ms-citas: agrega una línea trivial al
   final (por ejemplo `Despliegue continuo verificado en EP3.`) y guarda.
2. Ventana 1:
```powershell
cd ms-citas
git add . ; git commit -m "docs: verificacion de despliegue continuo" ; git push
```
3. Ventana 4, pestaña 1 (Actions): F5 → clic en el workflow que acaba de
   aparecer → se ven los jobs en amarillo/azul corriendo.
4. **PAUSA la grabación.** Espera 4-6 min a que termine (verde).

🖥️ **HACES (parte 2, reanuda grabación):**
5. F5 en Actions → los 3 jobs con ✓ verde → clic para expandir
   `docker-push` un segundo.
6. Ventana 5: `curl.exe -H "x-api-key: $env:KEY" "$env:GW/api/citas"` → 200.

**Si sale rojo:** corta. Lee el log del job rojo (99% = secret AWS vencido o
token Docker Hub). Arregla, push de nuevo, regraba la parte 2.

🎙️ **DICES:**
> «Ahora el ciclo completo de integración y despliegue continuo. Hago un
> commit y push a main... y GitHub Actions dispara el pipeline: primera
> etapa, build y pruebas con Maven, que publica el reporte de tests como
> artefacto para trazabilidad; segunda, construye la imagen Docker y la sube
> a Docker Hub con dos tags, latest y el SHA del commit; tercera, se conecta
> por SSH al manager y actualiza el servicio en Swarm, sin intervención
> manual. El endpoint en la nube ya responde con el cambio desplegado.»

## ESCENA 5 · Escalado (≈45 s)

🖥️ **HACES:**
1. Acomoda Ventana 3 (SSH) y Ventana 5 (curl) lado a lado (Win+← y Win+→).
2. En Ventana 3:
```bash
docker service scale clinica_ms-citas=4
docker service ps clinica_ms-citas
```
3. En Ventana 5 (mientras converge): `curl.exe -s -o NUL -w "%{http_code}`n" -H "x-api-key: $env:KEY" "$env:GW/api/citas"` → `200`. Repítelo 2-3 veces.
4. En Ventana 3:
```bash
docker service scale clinica_ms-citas=1
docker service scale clinica_ms-citas=2
```
5. Un último curl → `200`.

**Esperas ver:** `4/4` convergido en segundos y réplicas en ambos nodos.
**Si una réplica queda `Pending`:** memoria justa — usa 3 en vez de 4 y
menciona los límites de recursos como decisión de diseño.

🎙️ **DICES:**
> «Simulo un aumento de demanda: escalo citas de dos a cuatro réplicas con
> un solo comando. Swarm programa las nuevas réplicas en ambos nodos y el
> servicio nunca deja de responder, como muestra la petición en paralelo.
> Ante baja demanda escalo hacia abajo a una réplica, y el sistema sigue
> disponible. Vuelvo a dos, el estado normal.»

## ESCENA 6 · Justificación técnica (≈45 s, sin comandos)

🖥️ **HACES:** Ventana 4, pestaña 5 → baja hasta la sección **"Decisiones
técnicas (resumen para IE9)"** del README. Scroll lento por los bullets
mientras corre la narración.

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

## ESCENA 7 · Cola SQS (≈40 s, sin comandos)

🖥️ **HACES:** Ventana 4, pestaña 2 (SQS → clinica-citas-queue →
*Monitoring*). Pasa el mouse por los gráficos "Number of messages sent" /
"received". Clic breve en la pestaña de detalles para que se vea el nombre
y el ARN de la cola.

🎙️ **DICES:**
> «Esta es la cola clinica-citas-queue, creada de forma idempotente por la
> etapa de provisión del pipeline. Su propósito es desacoplar el
> agendamiento de la notificación al paciente: crear la cita es síncrono y
> crítico; notificar es asíncrono y tolerante a fallos. Si el consumidor
> está caído, los mensajes esperan en la cola y no se pierde ninguna
> notificación, con reintentos automáticos por lote parcial.»

## ESCENA 8 · API Gateway (≈35 s)

🖥️ **HACES:**
1. Ventana 4, pestaña 3 (API Gateway): muestra 3 segundos el árbol de
   recursos (/api/citas, /api/medicos...) y el Usage Plan.
2. Ventana 5, los tres curl, uno por uno:
```powershell
curl.exe -i "$env:GW/api/medicos"
curl.exe -i -H "x-api-key: $env:KEY" "$env:GW/api/medicos"
curl.exe -i "http://$($env:IP):8081/api/medicos"
```

**Esperas ver, en orden: `403 Forbidden` → `200 OK` con JSON → `401`.**
**Si el 2º da 500:** la IP del manager cambió → actualizar integraciones +
Deploy API (Fase B punto 2). No grabes hasta arreglarlo.

🎙️ **DICES:**
> «Todo el acceso externo entra por API Gateway. La protección tiene dos
> capas: el Gateway exige una API key con plan de uso y throttling —sin
> ella, 403—, y además inyecta una cabecera secreta hacia el backend, que un
> filtro en ambos microservicios valida. Por eso el acceso directo a la
> instancia devuelve 401: el Gateway es la única puerta de entrada al
> sistema.»

## ESCENA 9 · Lambda + trigger (≈30 s, sin comandos)

🖥️ **HACES:**
1. Ventana 2 (VS Code), pestaña `lambda_function.py`: selecciona con el
   mouse la línea del `return {"batchItemFailures": fallidos}` y la
   constante `CAMPOS_OBLIGATORIOS`.
2. Ventana 4, pestaña 4 (Lambda): que se vea el diagrama con **SQS como
   trigger** de clinica-notificador.

🎙️ **DICES:**
> «El consumidor de la cola es la función serverless clinica-notificador, en
> Python. Recibe los lotes del trigger SQS, valida el contrato del mensaje y
> registra la notificación con logging estructurado. Si un mensaje del lote
> falla, devuelve batchItemFailures y SQS reintenta solo ese mensaje: manejo
> parcial de errores, una buena práctica de FaaS.»

## ESCENA 10 · End-to-end + cierre (≈45 s)

🖥️ **HACES:**
1. Ventana 5:
```powershell
curl.exe -i -X POST "$env:GW/api/citas" -H "x-api-key: $env:KEY" -H "Content-Type: application/json" -d '{\"fecha\":\"2026-08-20\",\"hora\":\"10:30\",\"motivo\":\"Control cardiologico\",\"medicoId\":1,\"pacienteId\":1}'
```
   **Esperas ver:** `201 Created` y `"estado":"PROGRAMADA"`.
2. Ventana 3 (SSH manager):
```bash
aws logs tail /aws/lambda/clinica-notificador --since 2m
```
   **Esperas ver** (tarda 5-15 s; puedes repetir el comando): la línea
   `{"evento": "notificacion_enviada", ... "Estimado/a ..."}`.
3. Vuelve 3 segundos a la pestaña del diagrama (cierre visual) y corta.

**Si el log no aparece en 30 s:** credenciales de ms-citas vencidas →
`bash scripts/actualizar-credenciales-aws.sh`, espera 1 min, repite el POST
y regraba la escena.

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

## DESPUÉS DE GRABAR (edición, 1 h)

1. Importa el metraje a tu editor (Kaltura, Canva o el que uses).
2. Corta: esperas de arranque de Spring (escena 2), la pausa del pipeline
   (escena 4) y cualquier tipeo lento.
3. Graba la voz en off escena por escena leyendo los 🎙️ DICES con el video
   corriendo delante (audífonos con micrófono, pieza en silencio).
4. Verifica duración: **entre 3 y 8 minutos** (objetivo ~7).
5. Escucha TODO el video una vez con audífonos: volumen parejo, sin ruido.
6. Exporta en **mp4**.
7. Entrega: mp4 en el AVA + correo al docente; y los 3 enlaces de GitHub en
   el AVA + el mismo correo.
