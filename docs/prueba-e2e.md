# Prueba end-to-end + escalado (IE8, IE15)

Guion exacto de la demostración final: recorre el flujo completo
**petición externa → API Gateway → ms-citas (Swarm) → SQS → Lambda → CloudWatch**
y valida el escalado en ambos sentidos. Es el clímax del video.

## Preparación (antes de grabar)

```bash
# En el nodo manager: credenciales AWS Academy frescas en ms-citas
bash scripts/actualizar-credenciales-aws.sh

# Datos base (via Gateway): 1 especialidad, 1 medico, 1 paciente
GW="https://XXXXXXXXXX.execute-api.us-east-1.amazonaws.com/prod"
KEY="x-api-key: VALOR_DE_LA_KEY"

curl -s -X POST "$GW/api/especialidades" -H "$KEY" -H "Content-Type: application/json" \
  -d '{"nombre":"Cardiologia","descripcion":"Especialidad del corazon"}'
curl -s -X POST "$GW/api/medicos" -H "$KEY" -H "Content-Type: application/json" \
  -d '{"rut":"15111222-3","nombre":"Carla","apellido":"Soto","email":"carla@clinica.cl","especialidadId":1}'
curl -s -X POST "$GW/api/pacientes" -H "$KEY" -H "Content-Type: application/json" \
  -d '{"rut":"12345678-5","nombre":"Ana","apellido":"Rojas","email":"ana@mail.cl","telefono":"+56933333333","fechaNacimiento":"1992-08-15"}'
```

## Secuencia de la demo

### 1. Estado inicial del clúster

```bash
docker node ls        # manager + worker, ambos Ready
docker service ls     # replicas 2/2 en ambos microservicios
```

### 2. Petición externa: crear una cita por el Gateway

```bash
curl -i -X POST "$GW/api/citas" -H "$KEY" -H "Content-Type: application/json" \
  -d '{"fecha":"2026-08-20","hora":"10:30","motivo":"Control cardiologico","medicoId":1,"pacienteId":1}'
# Esperado: HTTP 201 + JSON con estado PROGRAMADA
```

En ese instante `ms-citas` validó el médico contra `ms-personal-medico`
(comunicación entre microservicios) y publicó el evento `CITA_CREADA` en SQS.

### 3. El mensaje pasó por la cola

Consola AWS → SQS → `clinica-citas-queue` → *Monitoring*:
`Number of messages sent` sube en 1 (y `received/deleted` también,
porque la Lambda ya lo consumió).

### 4. La Lambda lo procesó

```bash
aws logs tail /aws/lambda/clinica-notificador --since 5m
# Esperado: {"evento":"notificacion_enviada","idCita":...,"mensaje":"Estimado/a Ana Rojas..."}
```

### 5. Escalado hacia ARRIBA con carga en vivo

```bash
docker service scale clinica_ms-citas=4
docker service ps clinica_ms-citas   # 4 replicas repartidas entre manager y worker
# El sistema sigue respondiendo mientras escala:
curl -s "$GW/api/citas" -H "$KEY"    # 200 OK
```

### 6. Escalado hacia ABAJO

```bash
docker service scale clinica_ms-citas=1
curl -s "$GW/api/citas" -H "$KEY"    # sigue 200 OK con una sola replica
docker service scale clinica_ms-citas=2   # volver al estado normal
```

### 7. Tolerancia a fallos (opcional, 15 segundos que impresionan)

```bash
# En el worker: matar un contenedor a proposito
docker ps --filter name=clinica_ms-citas -q | head -1 | xargs docker kill
# En el manager: Swarm lo repone solo (restart_policy on-failure)
docker service ps clinica_ms-citas
```

## Qué demuestra cada paso (mapa a la pauta)

| Paso | Indicador |
|---|---|
| 2 (Gateway con key) + verificación 403/401 de `infra/api-gateway.md` | IE12 |
| 2→3→4 flujo productor → cola → consumidor | IE11, IE14 |
| 4 ejecución de la función serverless | IE13 |
| 5–6 escalado arriba y abajo con servicio vivo | IE8 |
| 1→6 flujo completo bajo distintas condiciones | IE15 |
