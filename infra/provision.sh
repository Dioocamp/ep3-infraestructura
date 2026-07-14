#!/usr/bin/env bash
# ======================================================================
#  Provision idempotente de los servicios cloud del sistema (IaC).
#  La ejecuta la etapa 'provision-cloud' del pipeline CI/CD, y tambien
#  puede correrse a mano desde la raiz del repo:  bash infra/provision.sh
#
#  Crea/actualiza:
#   1. Cola SQS  'clinica-citas-queue'   (mensajeria asincrona)
#   2. Lambda    'clinica-notificador'   (consumidor FaaS)
#   3. Trigger SQS -> Lambda con ReportBatchItemFailures
#
#  Requiere credenciales AWS en el entorno (en CI las inyecta
#  aws-actions/configure-aws-credentials desde los secrets).
# ======================================================================
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
QUEUE_NAME="clinica-citas-queue"
FUNCTION_NAME="clinica-notificador"
LAMBDA_DIR="lambda/notificador"
ZIP_FILE="/tmp/notificador.zip"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
# LabRole: rol preexistente en AWS Academy con permisos de laboratorio.
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/LabRole"

echo ">> Cuenta AWS: ${ACCOUNT_ID} (region ${REGION})"

# ----------------------------------------------------------------------
# 1. Cola SQS (create-queue es idempotente si los atributos coinciden)
# ----------------------------------------------------------------------
echo ">> [1/3] Asegurando cola SQS '${QUEUE_NAME}'..."
QUEUE_URL=$(aws sqs create-queue \
  --queue-name "${QUEUE_NAME}" \
  --attributes VisibilityTimeout=60 \
  --region "${REGION}" \
  --query QueueUrl --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes \
  --queue-url "${QUEUE_URL}" \
  --attribute-names QueueArn \
  --region "${REGION}" \
  --query 'Attributes.QueueArn' --output text)
echo "   Cola lista: ${QUEUE_URL}"

# ----------------------------------------------------------------------
# 2. Funcion Lambda: crear la primera vez, actualizar el codigo despues
# ----------------------------------------------------------------------
echo ">> [2/3] Empaquetando y desplegando '${FUNCTION_NAME}'..."
(cd "${LAMBDA_DIR}" && zip -q -j "${ZIP_FILE}" lambda_function.py)

if aws lambda get-function --function-name "${FUNCTION_NAME}" --region "${REGION}" >/dev/null 2>&1; then
  aws lambda update-function-code \
    --function-name "${FUNCTION_NAME}" \
    --zip-file "fileb://${ZIP_FILE}" \
    --region "${REGION}" >/dev/null
  echo "   Codigo de la funcion actualizado."
else
  aws lambda create-function \
    --function-name "${FUNCTION_NAME}" \
    --runtime python3.12 \
    --handler lambda_function.lambda_handler \
    --role "${ROLE_ARN}" \
    --zip-file "fileb://${ZIP_FILE}" \
    --timeout 30 \
    --region "${REGION}" >/dev/null
  echo "   Funcion creada."
  aws lambda wait function-active-v2 --function-name "${FUNCTION_NAME}" --region "${REGION}"
fi

# ----------------------------------------------------------------------
# 3. Trigger SQS -> Lambda (solo si no existe todavia)
# ----------------------------------------------------------------------
echo ">> [3/3] Asegurando trigger SQS -> Lambda..."
MAPPING=$(aws lambda list-event-source-mappings \
  --function-name "${FUNCTION_NAME}" \
  --event-source-arn "${QUEUE_ARN}" \
  --region "${REGION}" \
  --query 'EventSourceMappings[0].UUID' --output text)

if [ "${MAPPING}" = "None" ] || [ -z "${MAPPING}" ]; then
  aws lambda create-event-source-mapping \
    --function-name "${FUNCTION_NAME}" \
    --event-source-arn "${QUEUE_ARN}" \
    --batch-size 10 \
    --function-response-types ReportBatchItemFailures \
    --region "${REGION}" >/dev/null
  echo "   Trigger creado (batch 10, ReportBatchItemFailures)."
else
  echo "   Trigger ya existente (${MAPPING})."
fi

echo ""
echo ">> Provision completada."
echo ">> QUEUE_URL=${QUEUE_URL}"
echo ">> Usa esa URL en NOTIFICACIONES_QUEUE_URL del docker-compose.yml."
