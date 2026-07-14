# Checklist de entrega EP3 (Fase 10)

## Configuración inicial (una sola vez)

- [ ] Crear cuenta Docker Hub (si no existe) y un **Access Token**
      (Account Settings → Security → New Access Token).
- [ ] Crear el repo `ep3-infraestructura` en GitHub (usuario Dioocamp) y
      pushear esta carpeta.
- [ ] Configurar los **secrets** en los 3 repos según la tabla del README.
- [ ] Ajustar en `docker-compose.yml`: usuario Docker Hub,
      `NOTIFICACIONES_QUEUE_URL` (sale de `infra/provision.sh`) y
      `GATEWAY_SECRET`.
- [ ] Levantar las 2 EC2, instalar Docker, abrir puertos del Security Group
      (ver `infra/api-gateway.md` §7).
- [ ] `scripts/init-swarm.sh` en la EC2 manager; `scripts/join-worker.sh`
      en la worker; verificar con `docker node ls`.
- [ ] Configurar el API Gateway siguiendo `infra/api-gateway.md` (§1–§5).

## Antes de cada sesión de trabajo/demo (AWS Academy)

- [ ] Iniciar el Learner Lab y copiar las credenciales de **AWS Details**.
- [ ] Actualizar los 3 secrets AWS en GitHub (repo infraestructura).
- [ ] Actualizar `~/.aws/credentials` en el manager y ejecutar
      `bash scripts/actualizar-credenciales-aws.sh`.
- [ ] Si la IP pública de las EC2 cambió (instancias detenidas): actualizar
      `EC2_HOST` en los secrets y las URLs de integración del API Gateway
      (+ *Deploy API*).

## Verificación pre-entrega

- [ ] Clonar los 3 repos en una carpeta limpia y construir desde cero:
      `docker build .` en cada microservicio termina sin errores.
- [ ] `mvnw clean verify` verde en ambos microservicios (20 tests en total:
      7 en personal-médico y 13 en citas).
- [ ] Push a `main` en un microservicio → pipeline completo en verde →
      cambio visible en la nube.
- [ ] Push a `main` en infraestructura → provisión + stack deploy en verde.
- [ ] Los 4 curls de verificación de `infra/api-gateway.md` §6 dan
      403 / 200 / 401 / 201 respectivamente.
- [ ] Prueba end-to-end completa según `docs/prueba-e2e.md`.

## Entrega del encargo (los repos)

- [ ] Los 3 repos en GitHub, públicos (o con acceso para el docente):
      `ms-personal-medico`, `ms-citas`, `ep3-infraestructura`.
- [ ] Verificar que cada repo muestra en GitHub: Dockerfile,
      `.github/workflows/ci-cd.yml`, y en infraestructura además
      `docker-compose.yml`, `scripts/`, `lambda/`, `infra/`.
- [ ] Copiar los **3 enlaces** en el AVA.
- [ ] Enviar correo al docente con los 3 enlaces (copia de respaldo).

## Entrega de la presentación (el video)

- [ ] Grabar siguiendo `docs/guion-video.md` (3–8 min, objetivo 7:30).
- [ ] Voces de **ambos** integrantes, claras y sin ruido de fondo.
- [ ] Exportar a mp4 y verlo completo una vez antes de subirlo.
- [ ] Subir el archivo al AVA **y** enviarlo/compartirlo al correo del
      docente dentro del plazo.
