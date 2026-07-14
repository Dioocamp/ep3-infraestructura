# Función serverless `clinica-notificador`

Función AWS Lambda (Python 3.12) que consume los eventos `CITA_CREADA`
publicados por `ms-citas` en la cola SQS `clinica-citas-queue` y registra la
notificación al paciente en CloudWatch Logs.

## Contrato del mensaje

`ms-citas` publica en la cola un JSON con esta forma (ver
`CitaCreadaEvento.java` en el repo de ms-citas):

```json
{
  "idCita": 7,
  "rutPaciente": "12345678-5",
  "nombrePaciente": "Ana Rojas",
  "fechaHora": "2026-08-01T09:00",
  "medicoId": 3,
  "motivo": "Control cardiologico"
}
```

Campos obligatorios: `idCita`, `rutPaciente`, `nombrePaciente`, `fechaHora`.
Si falta alguno, el mensaje se marca como fallido vía `batchItemFailures` y
SQS lo reintenta solo a él (respuesta parcial por lotes, buena práctica FaaS).

## Despliegue con AWS CLI

> Todo esto lo automatiza `infra/provision.sh` (lo ejecuta el pipeline).
> Los comandos manuales equivalentes son:

```bash
# 0. Variables (LabRole es el rol disponible en AWS Academy)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/LabRole"

# 1. Crear la cola (idempotente)
QUEUE_URL=$(aws sqs create-queue --queue-name clinica-citas-queue \
  --attributes VisibilityTimeout=60 --query QueueUrl --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" \
  --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

# 2. Empaquetar y crear la funcion
zip notificador.zip lambda_function.py
aws lambda create-function \
  --function-name clinica-notificador \
  --runtime python3.12 \
  --handler lambda_function.lambda_handler \
  --role "$ROLE_ARN" \
  --zip-file fileb://notificador.zip \
  --timeout 30

# 3. Conectar la cola como trigger (con respuesta parcial por lotes)
aws lambda create-event-source-mapping \
  --function-name clinica-notificador \
  --event-source-arn "$QUEUE_ARN" \
  --batch-size 10 \
  --function-response-types ReportBatchItemFailures
```

Para actualizar el código después de un cambio:

```bash
zip notificador.zip lambda_function.py
aws lambda update-function-code \
  --function-name clinica-notificador --zip-file fileb://notificador.zip
```

## Cómo probarla

**Invocación directa con el evento de ejemplo** (simula un lote SQS):

```bash
aws lambda invoke \
  --function-name clinica-notificador \
  --payload fileb://evento-ejemplo.json \
  salida.json

cat salida.json
# → {"batchItemFailures": []}   (lote procesado completo)
```

**Prueba end-to-end por la cola** (el flujo real del sistema):

```bash
aws sqs send-message --queue-url "$QUEUE_URL" \
  --message-body '{"idCita":99,"rutPaciente":"11111111-1","nombrePaciente":"Juan Perez","fechaHora":"2026-08-15T10:30","medicoId":3,"motivo":"Control anual"}'
```

Y luego revisar el log de la función:

```bash
aws logs tail /aws/lambda/clinica-notificador --since 5m --follow
```

Debe aparecer una línea JSON `{"evento": "notificacion_enviada", "idCita": 99, ...}`.

**Prueba del manejo de errores** (mensaje inválido → reintento parcial):

```bash
aws sqs send-message --queue-url "$QUEUE_URL" --message-body '{"idCita":100}'
# En el log aparece {"evento":"error_procesamiento",...} y el mensaje
# vuelve a la cola solo esa vez (batchItemFailures).
```
