# RUNBOOK — De cero a video grabado sin equivocarse

Guía operativa completa en 3 fases. **FASE A** se hace UNA vez (una tarde).
**FASE B** son los 30 minutos antes de grabar. **FASE C** es la grabación
escena por escena con salida esperada y plan B si algo falla.

Regla general: **nunca grabes algo que no ensayaste 5 minutos antes.**
Todos los comandos de la Fase C se ejecutan UNA vez en seco (sin grabar),
y solo cuando todo respondió como se espera, se graba.

---

# FASE A — Preparación (una sola vez)

## A1. Subir los 3 repos a GitHub (10 min)

Los commits ya están hechos y verificados en tu máquina. Solo falta subirlos.

**ms-personal-medico y ms-citas** (los remotos ya existen):

```powershell
cd C:\Users\dinko\OneDrive\Documentos\Claude-Code\EP2-Microservicios\ms-personal-medico
git push origin --all
git push origin --tags

cd ..\ms-citas
git push origin --all
git push origin --tags
```

> La primera vez se abrirá una ventana de GitHub para iniciar sesión
> (Git Credential Manager). Después queda guardado.

**ep3-infraestructura** (repo nuevo):

1. En github.com → **New repository** → nombre `ep3-infraestructura`,
   **público**, SIN readme ni .gitignore (ya existen). → Create.
2. Luego:

```powershell
cd ..\ep3-infraestructura
git remote add origin https://github.com/Dioocamp/ep3-infraestructura.git
git push origin --all
```

**Verificación:** los 3 repos en github.com/Dioocamp muestran el Dockerfile,
`.github/workflows/ci-cd.yml` y (en infraestructura) `docker-compose.yml`,
`scripts/`, `lambda/`, `infra/`, `docs/`.

⚠ Al pushear los microservicios, la pestaña **Actions** va a ejecutar el
pipeline y **va a fallar en las etapas docker-push/deploy** (aún no hay
secrets). Es normal — se arregla en A3.

## A2. Docker Hub (5 min)

1. Cuenta en hub.docker.com (si no tienes). Anota tu **usuario exacto**.
2. Account Settings → Security → **New Access Token** → nombre `github-actions`,
   permisos Read/Write → **copia el token** (solo se ve una vez).
3. Si tu usuario NO es `dioocamp`: edita `docker-compose.yml` y reemplaza
   `dioocamp/` por tu usuario en las dos imágenes. Commit + push.

## A3. Secrets en GitHub (10 min)

En **cada repo** → Settings → Secrets and variables → Actions →
New repository secret:

| Secret | Valor | ¿En qué repos? |
|---|---|---|
| `DOCKERHUB_USERNAME` | tu usuario Docker Hub | los 3 |
| `DOCKERHUB_TOKEN` | el token de A2 | los 3 |
| `EC2_HOST` | IP pública del manager (sale de A4) | los 3 |
| `EC2_USER` | `ec2-user` | los 3 |
| `EC2_SSH_KEY` | contenido completo del archivo `.pem` (ábrelo con Bloc de notas y copia TODO) | los 3 |
| `AWS_ACCESS_KEY_ID` | de AWS Details (Academy) | solo infraestructura |
| `AWS_SECRET_ACCESS_KEY` | de AWS Details | solo infraestructura |
| `AWS_SESSION_TOKEN` | de AWS Details | solo infraestructura |
| `AWS_REGION` | `us-east-1` | solo infraestructura |

Tras configurar los secrets de un microservicio: pestaña Actions →
workflow fallido → **Re-run all jobs** → debe quedar verde y la imagen
aparece en Docker Hub.

## A4. Levantar las 2 EC2 (20 min)

En AWS Academy → Start Lab → AWS Console → EC2 → **Launch instance**:

**Instancia 1 (manager):**
- Name: `swarm-manager`
- AMI: **Amazon Linux 2023**
- Type: **t3.small** (mínimo; t3.medium si el lab lo permite)
- Key pair: crea `clinica-key` (descarga el `.pem` — es el de A3)
- Security Group: crea `clinica-sg` con estas reglas de entrada:

| Tipo | Puerto | Origen |
|---|---|---|
| SSH | 22 | My IP (o 0.0.0.0/0 si tu IP cambia) |
| Custom TCP | 8081 | 0.0.0.0/0 |
| Custom TCP | 8082 | 0.0.0.0/0 |
| Custom TCP | 2377 | el propio SG (`clinica-sg`) |
| Custom TCP | 7946 | el propio SG |
| Custom UDP | 7946 | el propio SG |
| Custom UDP | 4789 | el propio SG |

> Para las reglas "el propio SG": primero crea el SG con las 3 primeras
> reglas, lánzala, y luego edita el SG agregando las reglas internas
> eligiendo como origen el mismo `clinica-sg`.

**Instancia 2 (worker):** igual (`swarm-worker`, misma key, mismo SG).

Anota la **IP pública del manager** → secret `EC2_HOST` (A3).

**Instalar Docker en AMBAS** (conéctate con PuTTY o
`ssh -i clinica-key.pem ec2-user@IP`):

```bash
sudo dnf install -y docker git
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user
exit   # reconectarse para que aplique el grupo
```

## A5. Crear el clúster Swarm (5 min)

**En el manager:**

```bash
git clone https://github.com/Dioocamp/ep3-infraestructura.git
cd ep3-infraestructura
bash scripts/init-swarm.sh
# Copia el comando "docker swarm join --token ..." que imprime
```

**En el worker:** pega ese comando `docker swarm join --token ... IP:2377`.

**Verificación (manager):** `docker node ls` → 2 nodos, ambos `Ready`.

## A6. Provisionar SQS + Lambda (5 min)

En el **manager** (tiene AWS CLI preinstalado en AL2023):

```bash
mkdir -p ~/.aws
nano ~/.aws/credentials   # pega el bloque [default] de AWS Details → guardar
cd ~/ep3-infraestructura
bash infra/provision.sh
```

La última línea imprime `QUEUE_URL=https://sqs.us-east-1.amazonaws.com/...`
→ **cópiala**.

## A7. Configurar y desplegar el stack (10 min)

En tu PC, edita `docker-compose.yml` (3 valores, una vez):
1. `dioocamp/` → tu usuario Docker Hub (si difiere).
2. `NOTIFICACIONES_QUEUE_URL:` → la QUEUE_URL de A6.
3. `GATEWAY_SECRET:` → inventa un secreto largo (anótalo, se usa en A8).

Commit + push → el pipeline de infraestructura provisiona y despliega solo.
O manual en el manager:

```bash
cd ~/ep3-infraestructura && git pull
bash scripts/deploy-stack.sh
bash scripts/actualizar-credenciales-aws.sh
```

**Verificación:** `docker service ls` → réplicas `1/1` (mysql) y `2/2`
(ambos microservicios). La primera vez tarda 2-3 min (descarga imágenes +
MySQL inicializa; los microservicios se reinician hasta que MySQL esté listo
— es el diseño, no un error).

```bash
curl http://localhost:8081/actuator/health   # {"status":"UP"}
curl http://localhost:8082/actuator/health   # {"status":"UP"}
```

## A8. API Gateway (30 min, consola)

Sigue `infra/api-gateway.md` §1–§5 al pie de la letra. Resumen: REST API
`clinica-gateway` → 8 recursos proxy hacia la IP del manager → en cada
método: API key required + cabecera `x-gateway-secret` con el valor de A7 →
API key `clinica-key` + usage plan `clinica-plan` → **Deploy API** a `prod`.

Anota: la **URL de invocación** y el **valor de la API key**.

## A9. Verificación total (la haces UNA vez aquí, y de nuevo en B)

```bash
GW="https://TU-ID.execute-api.us-east-1.amazonaws.com/prod"
KEY="x-api-key: TU-API-KEY"
IP="IP-PUBLICA-MANAGER"

curl -i "$GW/api/medicos"              # → 403 Forbidden
curl -i -H "$KEY" "$GW/api/medicos"    # → 200 OK
curl -i "http://$IP:8081/api/medicos"  # → 401 Unauthorized
```

Crea los datos base (guía `docs/prueba-e2e.md`, sección Preparación):
especialidad + médico + paciente. Luego el POST de una cita → `201` →
`aws logs tail /aws/lambda/clinica-notificador --since 5m` muestra
`notificacion_enviada`. **Si esto funciona, el sistema entero funciona.**

---

# FASE B — Pre-vuelo del día de grabación (30 min antes)

En orden, sin saltarse ninguno:

1. **AWS Academy → Start Lab** (espera el punto verde).
2. **¿Cambió la IP del manager?** (cambia si detuviste las instancias):
   - Sí → actualiza: secret `EC2_HOST` (3 repos) + las 8 integraciones del
     Gateway (§2 de la guía) + **Deploy API** de nuevo.
3. **Secrets AWS frescos** en el repo infraestructura (los 3 de AWS Details).
4. **Credenciales en el manager:** actualiza `~/.aws/credentials` (nano) y:
   ```bash
   cd ~/ep3-infraestructura && bash scripts/actualizar-credenciales-aws.sh
   ```
5. **Estado del clúster:** `docker node ls` (2 Ready) y `docker service ls`
   (1/1 y 2/2). Si algo está en 0/2: `docker service ps <servicio>` para ver
   el error (casi siempre es MySQL aún arrancando → espera 2 min).
6. **Datos base existen:** `curl -H "$KEY" "$GW/api/medicos"` → lista con el
   médico. Si está vacía, créalos (prueba-e2e.md).
7. **Ensayo en seco de la Fase C completa** (5 min, sin grabar).
8. **Prepara las ventanas:** ver "Set de grabación" abajo.
9. Docker Desktop local corriendo (para la escena 2).
10. Audífonos con micrófono puestos, pieza en silencio.

**Set de grabación (ventanas abiertas antes de partir):**
- V1: PowerShell local en `EP2-Microservicios\` (escena 2)
- V2: VS Code con el repo ms-citas y el docker-compose.yml (escenas 3 y 4)
- V3: SSH al manager (escenas 3, 5, 10)
- V4: Navegador pestañas: GitHub Actions · Docker Hub · consola SQS ·
  consola API Gateway · consola Lambda (escenas 4, 7, 8, 9)
- V5: PowerShell local para los curl al Gateway (escenas 8 y 10)

---

# FASE C — Grabación escena por escena

Formato: **[qué muestras] → comando → salida esperada → plan B si falla.**
Los textos narrados están en `docs/guion-video.md` — esta guía es la parte
técnica para no equivocarse.

### Escena 1 (0:00–0:30) — Intro con lámina de arquitectura
Muestra el diagrama del README. Sin comandos. **No puede fallar.**

### Escena 2 (0:30–1:30) — Docker local (V1)

```powershell
docker build -t ms-personal-medico .\ms-personal-medico
docker build -t ms-citas .\ms-citas
docker network create clinica-local
docker run -d --name personal --network clinica-local -p 8081:8081 -e SPRING_PROFILES_ACTIVE=h2 ms-personal-medico
docker run -d --name citas --network clinica-local -p 8082:8082 -e SPRING_PROFILES_ACTIVE=h2 -e MS_PERSONAL_MEDICO_URL=http://personal:8081 ms-citas
curl.exe http://localhost:8081/api/medicos
curl.exe http://localhost:8082/api/citas
curl.exe http://localhost:8081/actuator/health
```

- **Esperado:** builds terminan (la 2ª vez es rápido, cache), los curl
  devuelven JSON con datos sembrados y `{"status":"UP"}`.
- **Truco:** haz un build completo ANTES de grabar; en cámara el build usa
  cache y tarda segundos. Espera ~20 s tras `docker run` antes del curl
  (Spring arranca).
- **Plan B:** si un contenedor no responde → `docker logs citas` en vivo
  (mostrar logs también suma). Si quedó basura de un ensayo:
  `docker rm -f personal citas` y repite el run.

### Escena 3 (1:30–2:30) — Compose + Swarm (V2 → V3)

En V2 muestras el `docker-compose.yml` (resalta `deploy:`, `replicas: 2`,
`overlay`). En V3:

```bash
docker node ls
docker service ls
docker service ps clinica_ms-citas
```

- **Esperado:** 2 nodos Ready; réplicas 2/2; `service ps` muestra réplicas
  en manager Y worker.
- **Plan B:** el stack YA está desplegado desde la fase A — no ejecutes
  `deploy-stack.sh` en cámara (puede tardar); solo muestra el estado y
  narra que el despliegue lo hace `docker stack deploy` / el pipeline.

### Escena 4 (2:30–3:30) — Pipeline CI/CD en vivo (V2 → V4)

En V2, con un cambio trivial ya preparado (p. ej. una línea en el README):

```powershell
git add . ; git commit -m "docs: ajuste para demo de despliegue continuo" ; git push
```

Cambia a V4 (pestaña Actions) → refresca → se ve el workflow corriendo.

- **Esperado:** build-test ✓ → docker-push ✓ → deploy-swarm ✓ (total 4-6 min).
- **Truco de edición:** graba el push + inicio del pipeline, PAUSA la
  grabación, espera a que termine, y graba las 3 etapas verdes + un
  `curl.exe -H "x-api-key: ..." "$GW/api/medicos"` como prueba de que la
  nube responde. En la edición se cuenta como continuo.
- **Plan B:** si el pipeline falla en cámara, NO improvises: corta, revisa
  el log de la etapa roja (suele ser secret AWS vencido o Docker Hub token),
  arregla, y regraba la escena.

### Escena 5 (3:30–4:15) — Escalado (V3, con V5 haciendo curl)

```bash
docker service scale clinica_ms-citas=4
docker service ps clinica_ms-citas
docker service scale clinica_ms-citas=1
docker service scale clinica_ms-citas=2
```

- **Esperado:** converge en segundos (la imagen ya está en ambos nodos);
  réplicas nuevas reparten entre manager y worker. En V5 un
  `curl -H "$KEY" "$GW/api/citas"` responde 200 durante todo el proceso.
- **Plan B:** si una réplica queda `Pending` → t3.small sin memoria; escala
  a 3 en vez de 4 y narra el límite de recursos como decisión técnica.

### Escena 6 (4:15–5:00) — Justificación técnica
Lámina o README, sin comandos. **No puede fallar.**

### Escena 7 (5:00–5:40) — SQS (V4)
Consola SQS → `clinica-citas-queue` → pestaña Monitoring.
- **Truco:** ten la pestaña ya abierta y logueada. Solo narras.

### Escena 8 (5:40–6:15) — API Gateway (V4 → V5)

```powershell
curl.exe -i "$env:GW/api/medicos"                      # 403
curl.exe -i -H "x-api-key: TU-KEY" "$env:GW/api/medicos"   # 200
curl.exe -i "http://IP-MANAGER:8081/api/medicos"       # 401
```

- **Prepara antes:** `$env:GW = "https://..."` ya definido en V5.
- **Esperado:** exactamente 403 → 200 → 401 (los tres códigos distintos son
  el punto fuerte de la escena: dos capas de protección).
- **Plan B:** un `500` en el 2º curl = la IP del manager cambió y el Gateway
  apunta a la vieja → fase B punto 2.

### Escena 9 (6:15–6:45) — Lambda (V2 código + V4 consola)
Muestra `lambda_function.py` (resalta `batchItemFailures`) y en consola
Lambda el trigger SQS. Sin comandos en vivo.

### Escena 10 (6:45–7:30) — End-to-end (V5 → V3)

```powershell
curl.exe -i -X POST "$env:GW/api/citas" -H "x-api-key: TU-KEY" -H "Content-Type: application/json" -d '{\"fecha\":\"2026-08-20\",\"hora\":\"10:30\",\"motivo\":\"Control cardiologico\",\"medicoId\":1,\"pacienteId\":1}'
```

En V3 (manager):

```bash
aws logs tail /aws/lambda/clinica-notificador --since 2m
```

- **Esperado:** `201 Created` con `"estado":"PROGRAMADA"` y, en el log,
  `notificacion_enviada` con el mensaje al paciente (tarda 5-15 s en
  aparecer; ejecuta el `tail` con calma mientras narras).
- **Plan B:** si el log no muestra nada en 30 s → credenciales AWS de
  ms-citas vencidas (el POST devuelve 201 igual, el envío a SQS es best
  effort). Corta, ejecuta `actualizar-credenciales-aws.sh`, espera 1 min,
  repite el POST y regraba.
- Cierre con la frase final del guion. **Listo.**

---

# Tabla rápida de fallas y arreglos

| Síntoma | Causa | Arreglo |
|---|---|---|
| Réplicas `0/2` que se reinician | MySQL aún inicializando | Esperar 2 min; `docker service ps` para confirmar |
| `ImagePullBackOff` / `No such image` | Falta `--with-registry-auth` o imagen no existe en Hub | `docker login` en el manager y redesplegar; revisar pipeline docker-push |
| Pipeline rojo en provision-cloud | Secrets AWS vencidos (Academy) | Actualizar los 3 secrets y Re-run |
| `502/500` desde el Gateway | IP del manager cambió | Actualizar integraciones + Deploy API |
| POST 201 pero Lambda sin logs | Credenciales AWS de ms-citas vencidas | `actualizar-credenciales-aws.sh` |
| `403` con API key incluida | Falta Deploy API tras un cambio, o key no asociada al usage plan | Deploy API; revisar usage plan |
| `curl` local sin respuesta | Contenedor aún arrancando | Esperar 20 s; `docker logs <nombre>` |
| Swarm join falla | Puertos 2377/7946/4789 cerrados en el SG | Revisar reglas del SG (origen = el propio SG) |
