# EP3 — Infraestructura Cloud de la Clínica (JVY0101)

Repositorio de **infraestructura y despliegue** del sistema de microservicios
de la clínica. Contiene el stack de Docker Swarm, la provisión de servicios
AWS (IaC), la función serverless y la documentación de operación.

Repositorios del sistema:

| Repositorio | Contenido |
|---|---|
| [ms-personal-medico](https://github.com/Dioocamp/ms-personal-medico) | Microservicio de especialidades y médicos (puerto 8081) |
| [ms-citas](https://github.com/Dioocamp/ms-citas) | Microservicio de pacientes y citas (puerto 8082) — publica eventos en SQS |
| **ep3-infraestructura** (este repo) | Stack Swarm, scripts, Lambda, API Gateway, pipeline de provisión |

## Arquitectura

```
                          ┌──────────────────────────── AWS ───────────────────────────┐
 Cliente externo          │                                                            │
      │                   │   ┌─────────────┐        ┌─────────────┐                   │
      │  https + x-api-key│   │ API Gateway │        │  SQS        │     ┌───────────┐ │
      └──────────────────────▶│ REST 'prod' │        │ clinica-    │────▶│  Lambda   │ │
                          │   └──────┬──────┘        │ citas-queue │     │notificador│ │
                          │          │ x-gateway-secret▲            │     └─────┬─────┘ │
                          │          ▼                │            │           ▼       │
                          │   ┌─────────────────── EC2 x2 (Docker Swarm) ─┐ CloudWatch │
                          │   │  manager ──────────── worker             │    Logs    │
                          │   │  ┌───────────────┐  ┌──────────────┐     │            │
                          │   │  │ms-personal x2 │  │ ms-citas x2  │─────┘            │
                          │   │  └───────┬───────┘  └──────┬───────┘ (evento          │
                          │   │          └───── overlay ───┤          CITA_CREADA)    │
                          │   │                     ┌──────┴──────┐                   │
                          │   │                     │  MySQL 8.4  │                   │
                          │   │                     └─────────────┘                   │
                          │   └───────────────────────────────────────────────────────┘
```

Flujo de negocio: el cliente agenda una cita a través del **API Gateway** →
`ms-citas` valida el médico contra `ms-personal-medico` (REST) y persiste en
MySQL → publica el evento `CITA_CREADA` en **SQS** → la **Lambda**
`clinica-notificador` consume el mensaje y registra la notificación al
paciente en CloudWatch Logs.

## Requisitos

- 2 instancias EC2 (Amazon Linux 2023, t3.small o superior) con Docker:
  `sudo dnf install -y docker && sudo systemctl enable --now docker && sudo usermod -aG docker ec2-user`
- Security Group según [infra/api-gateway.md](infra/api-gateway.md) §7
  (incluye los puertos internos de Swarm: 2377/tcp, 7946/tcp+udp, 4789/udp).
- Cuenta Docker Hub y cuenta AWS (Academy o Free Tier).

## Inicializar el clúster

En la **EC2 #1** (será el nodo manager), clonar este repo y ejecutar:

```bash
bash scripts/init-swarm.sh
```

El script inicializa Swarm con la IP privada de la instancia e imprime los
tokens de unión para workers y managers adicionales.

## Añadir nodos manager y worker

**Worker** — en la **EC2 #2**, con el token que imprimió `init-swarm.sh`:

```bash
bash scripts/join-worker.sh <TOKEN_WORKER> <IP_PRIVADA_MANAGER>
# o directamente:
docker swarm join --token <TOKEN_WORKER> <IP_PRIVADA_MANAGER>:2377
```

**Manager adicional** (alta disponibilidad del plano de control):

```bash
# En el manager actual, obtener el token de manager:
docker swarm join-token manager
# En la nueva instancia, ejecutar el comando que imprime.
```

Verificación en el manager:

```bash
docker node ls
# ID       HOSTNAME   STATUS  AVAILABILITY  MANAGER STATUS
# xxxxx *  manager    Ready   Active        Leader
# yyyyy    worker     Ready   Active
```

## Desplegar servicios distribuidos

1. Editar **una vez** `docker-compose.yml`: usuario de Docker Hub en las
   imágenes, `NOTIFICACIONES_QUEUE_URL` (la imprime `infra/provision.sh`)
   y `GATEWAY_SECRET`.
2. En el manager:

```bash
bash scripts/deploy-stack.sh          # docker stack deploy -c docker-compose.yml clinica
bash scripts/actualizar-credenciales-aws.sh   # inyecta la sesion de AWS Academy en ms-citas
```

3. Verificar:

```bash
docker service ls                     # replicas 2/2
docker service ps clinica_ms-citas   # replicas repartidas entre nodos
curl http://localhost:8081/actuator/health   # {"status":"UP"}
```

**Escalar** (hacia arriba o hacia abajo, sin downtime):

```bash
docker service scale clinica_ms-citas=4
docker service scale clinica_ms-citas=1
```

## Provisión de servicios cloud (IaC)

`infra/provision.sh` crea de forma **idempotente** la cola SQS
`clinica-citas-queue`, la Lambda `clinica-notificador` y el trigger entre
ambas. Lo ejecuta la etapa `provision-cloud` del pipeline en cada push a
`main`, y también puede correrse a mano:

```bash
bash infra/provision.sh
```

El API Gateway se configura por consola siguiendo
[infra/api-gateway.md](infra/api-gateway.md).

## Pipeline CI/CD de este repo

`.github/workflows/ci-cd.yml`: **provision-cloud** (SQS + Lambda, IaC) →
**deploy-swarm** (copia el compose al manager y hace `docker stack deploy`).

Secrets a configurar en GitHub (los tres repos usan el mismo criterio):

| Secret | Contenido | Repos |
|---|---|---|
| `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` | Cuenta y access token de Docker Hub | los 3 |
| `EC2_HOST` | IP pública del nodo manager | los 3 |
| `EC2_USER` | `ec2-user` | los 3 |
| `EC2_SSH_KEY` | Clave privada PEM de la instancia | los 3 |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` | Credenciales AWS Academy (rotan por sesión ⚠) | infraestructura |
| `AWS_REGION` | `us-east-1` | infraestructura |

⚠ **AWS Academy**: al iniciar cada sesión del Learner Lab hay que actualizar
los 3 secrets de AWS en GitHub **y** ejecutar
`scripts/actualizar-credenciales-aws.sh` en el manager. Hacerlo siempre antes
de grabar demos.

## Función serverless

Código, contrato del mensaje, despliegue y pruebas:
[lambda/notificador/README.md](lambda/notificador/README.md).

## Documentación de la demo

- [docs/prueba-e2e.md](docs/prueba-e2e.md) — prueba end-to-end + escalado.
- [docs/guion-video.md](docs/guion-video.md) — guion minutado del video.
- [docs/checklist-entrega.md](docs/checklist-entrega.md) — checklist final.

## Decisiones técnicas (resumen para IE9)

- **2 nodos (manager + worker)**: disponibilidad; las réplicas sobreviven a
  la caída de un nodo y el escalado distribuye carga entre máquinas.
- **Réplicas 2 + `restart_policy: on-failure`**: tolerancia a fallos sin
  intervención manual; Swarm repone contenedores caídos.
- **`update_config: start-first`**: despliegues sin downtime (primero
  arranca la réplica nueva, después baja la antigua).
- **Límites de recursos por servicio**: un microservicio con fuga de memoria
  no puede tumbar el nodo completo.
- **Imágenes versionadas por SHA de commit**: despliegues deterministas,
  trazables al código exacto y con rollback trivial (mantenibilidad).
- **Red overlay**: descubrimiento por DNS entre nodos; la BD nunca se expone
  fuera de la red del clúster.
- **MySQL con 1 réplica anclada al manager + volumen**: el estado no se
  replica a ciegas; los servicios sin estado son los que escalan.
- **Cola SQS entre ms-citas y la notificación**: desacopla el agendamiento
  (síncrono, crítico) de la notificación (asíncrona, tolerante a fallos);
  si la Lambda falla, el mensaje se reintenta sin perder citas.
