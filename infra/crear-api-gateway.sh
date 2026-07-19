#!/usr/bin/env bash
# ======================================================================
#  Crea el API Gateway completo de la clinica (IaC).
#
#  Ejecutar EN EL NODO MANAGER, desde la raiz del repositorio:
#      bash infra/crear-api-gateway.sh
#
#  Crea, de forma reproducible:
#   - REST API 'clinica-gateway' (regional)
#   - 8 rutas proxy hacia los dos microservicios:
#        /api/citas          + /api/citas/{proxy+}          -> :8082
#        /api/pacientes      + /api/pacientes/{proxy+}      -> :8082
#        /api/medicos        + /api/medicos/{proxy+}        -> :8081
#        /api/especialidades + /api/especialidades/{proxy+} -> :8081
#   - Cabecera 'x-gateway-secret' inyectada en cada integracion, para que
#     el backend rechace (401) cualquier acceso que no venga del Gateway.
#   - API key 'clinica-key' obligatoria en todos los metodos (sin ella: 403)
#   - Usage plan 'clinica-plan' con throttling (10 req/s, rafaga 20)
#   - Despliegue en el stage 'prod'
#
#  Es IDEMPOTENTE: si ya existe una API con el mismo nombre, la elimina y
#  la vuelve a crear, de modo que el resultado siempre sea el mismo.
# ======================================================================
set -euo pipefail

API_NAME="clinica-gateway"
KEY_NAME="clinica-key"
PLAN_NAME="clinica-plan"
STAGE="prod"
REGION="${AWS_REGION:-us-east-1}"

# --- IP publica del manager -------------------------------------------
# Se autodetecta desde los metadatos de EC2 (IMDSv2). Se puede forzar con:
#   MANAGER_IP=1.2.3.4 bash infra/crear-api-gateway.sh
if [ -z "${MANAGER_IP:-}" ]; then
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 120" 2>/dev/null || true)
  MANAGER_IP=$(curl -s -H "X-aws-ec2-metadata-token: ${TOKEN}" \
      http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || true)
fi
if [ -z "${MANAGER_IP}" ]; then
  echo "ERROR: no se pudo detectar la IP publica. Ejecuta asi:"
  echo "  MANAGER_IP=tu.ip.publica bash infra/crear-api-gateway.sh"
  exit 1
fi

# --- Secreto compartido con el backend --------------------------------
# Se lee del docker-compose.yml para que SIEMPRE coincida con el que
# usan los microservicios (si no coinciden, el Gateway recibiria 401).
if [ -z "${GATEWAY_SECRET:-}" ]; then
  GATEWAY_SECRET=$(grep -m1 'GATEWAY_SECRET:' docker-compose.yml \
      | sed 's/.*GATEWAY_SECRET: *//' | tr -d '"'\''' | tr -d '\r' | xargs)
fi
if [ -z "${GATEWAY_SECRET}" ]; then
  echo "ERROR: no se pudo leer GATEWAY_SECRET del docker-compose.yml."
  exit 1
fi

echo "======================================================"
echo " Creando API Gateway"
echo "   Backend  : ${MANAGER_IP} (puertos 8081 y 8082)"
echo "   Region   : ${REGION}"
echo "======================================================"
echo ""

# ----------------------------------------------------------------------
# 0. Limpieza: borra una API anterior con el mismo nombre (idempotencia)
# ----------------------------------------------------------------------
ANTERIORES=$(aws apigateway get-rest-apis --region "${REGION}" \
    --query "items[?name=='${API_NAME}'].id" --output text)
for VIEJA in ${ANTERIORES}; do
  echo ">> Eliminando API anterior (${VIEJA})..."
  aws apigateway delete-rest-api --rest-api-id "${VIEJA}" --region "${REGION}"
  sleep 15   # API Gateway limita la frecuencia de estas operaciones
done

# ----------------------------------------------------------------------
# 1. Crear la API y obtener el recurso raiz
# ----------------------------------------------------------------------
echo ">> [1/5] Creando la API '${API_NAME}'..."
API_ID=$(aws apigateway create-rest-api \
    --name "${API_NAME}" \
    --description "Puerta de entrada unica a los microservicios de la clinica (EP3)" \
    --endpoint-configuration types=REGIONAL \
    --region "${REGION}" \
    --query id --output text)
sleep 3

ROOT_ID=$(aws apigateway get-resources --rest-api-id "${API_ID}" \
    --region "${REGION}" --query 'items[?path==`/`].id' --output text)

echo ">> [2/5] Creando el recurso /api..."
API_RES=$(aws apigateway create-resource \
    --rest-api-id "${API_ID}" --parent-id "${ROOT_ID}" \
    --path-part api --region "${REGION}" --query id --output text)
sleep 2

# ----------------------------------------------------------------------
# 2. Funcion que crea un par de rutas (/api/X y /api/X/{proxy+})
# ----------------------------------------------------------------------
crear_ruta() {
  local NOMBRE="$1"      # citas, pacientes, medicos, especialidades
  local PUERTO="$2"      # 8081 u 8082

  echo "   - /api/${NOMBRE}  ->  puerto ${PUERTO}"

  # --- Recurso exacto: /api/<nombre> ---
  local RES_ID
  RES_ID=$(aws apigateway create-resource \
      --rest-api-id "${API_ID}" --parent-id "${API_RES}" \
      --path-part "${NOMBRE}" --region "${REGION}" --query id --output text)
  sleep 2

  aws apigateway put-method \
      --rest-api-id "${API_ID}" --resource-id "${RES_ID}" \
      --http-method ANY --authorization-type NONE --api-key-required \
      --region "${REGION}" >/dev/null
  sleep 2

  aws apigateway put-integration \
      --rest-api-id "${API_ID}" --resource-id "${RES_ID}" \
      --http-method ANY --type HTTP_PROXY --integration-http-method ANY \
      --uri "http://${MANAGER_IP}:${PUERTO}/api/${NOMBRE}" \
      --request-parameters "integration.request.header.x-gateway-secret='${GATEWAY_SECRET}'" \
      --region "${REGION}" >/dev/null
  sleep 2

  # --- Recurso comodin: /api/<nombre>/{proxy+} ---
  local PROXY_ID
  PROXY_ID=$(aws apigateway create-resource \
      --rest-api-id "${API_ID}" --parent-id "${RES_ID}" \
      --path-part '{proxy+}' --region "${REGION}" --query id --output text)
  sleep 2

  aws apigateway put-method \
      --rest-api-id "${API_ID}" --resource-id "${PROXY_ID}" \
      --http-method ANY --authorization-type NONE --api-key-required \
      --request-parameters "method.request.path.proxy=true" \
      --region "${REGION}" >/dev/null
  sleep 2

  aws apigateway put-integration \
      --rest-api-id "${API_ID}" --resource-id "${PROXY_ID}" \
      --http-method ANY --type HTTP_PROXY --integration-http-method ANY \
      --uri "http://${MANAGER_IP}:${PUERTO}/api/${NOMBRE}/{proxy}" \
      --request-parameters "integration.request.path.proxy=method.request.path.proxy,integration.request.header.x-gateway-secret='${GATEWAY_SECRET}'" \
      --region "${REGION}" >/dev/null
  sleep 2
}

echo ">> [3/5] Creando las 8 rutas..."
crear_ruta "citas"          "8082"
crear_ruta "pacientes"      "8082"
crear_ruta "medicos"        "8081"
crear_ruta "especialidades" "8081"

# ----------------------------------------------------------------------
# 3. Desplegar al stage 'prod'
# ----------------------------------------------------------------------
echo ">> [4/5] Desplegando al stage '${STAGE}'..."
aws apigateway create-deployment \
    --rest-api-id "${API_ID}" --stage-name "${STAGE}" \
    --description "Despliegue automatizado (infra/crear-api-gateway.sh)" \
    --region "${REGION}" >/dev/null
sleep 5

# ----------------------------------------------------------------------
# 4. API key + usage plan (control de acceso: sin key -> 403)
# ----------------------------------------------------------------------
echo ">> [5/5] Creando API key y plan de uso..."

# Borra claves y planes anteriores con el mismo nombre
for VIEJO in $(aws apigateway get-usage-plans --region "${REGION}" \
    --query "items[?name=='${PLAN_NAME}'].id" --output text); do
  aws apigateway delete-usage-plan --usage-plan-id "${VIEJO}" --region "${REGION}" || true
  sleep 3
done
for VIEJA in $(aws apigateway get-api-keys --region "${REGION}" \
    --query "items[?name=='${KEY_NAME}'].id" --output text); do
  aws apigateway delete-api-key --api-key "${VIEJA}" --region "${REGION}" || true
  sleep 3
done

KEY_ID=$(aws apigateway create-api-key --name "${KEY_NAME}" --enabled \
    --description "Clave de acceso al sistema de la clinica" \
    --region "${REGION}" --query id --output text)
sleep 3

PLAN_ID=$(aws apigateway create-usage-plan --name "${PLAN_NAME}" \
    --description "Limita el trafico externo hacia el backend" \
    --api-stages "apiId=${API_ID},stage=${STAGE}" \
    --throttle "rateLimit=10,burstLimit=20" \
    --region "${REGION}" --query id --output text)
sleep 3

aws apigateway create-usage-plan-key \
    --usage-plan-id "${PLAN_ID}" --key-id "${KEY_ID}" --key-type API_KEY \
    --region "${REGION}" >/dev/null

KEY_VALUE=$(aws apigateway get-api-key --api-key "${KEY_ID}" \
    --include-value --region "${REGION}" --query value --output text)

INVOKE_URL="https://${API_ID}.execute-api.${REGION}.amazonaws.com/${STAGE}"

# ----------------------------------------------------------------------
# 5. Resultado
# ----------------------------------------------------------------------
echo ""
echo "======================================================"
echo " API GATEWAY LISTO"
echo "======================================================"
echo ""
echo " GW  = ${INVOKE_URL}"
echo " KEY = ${KEY_VALUE}"
echo ""
echo " Anota esos dos valores en tu archivo datos-ep3.txt."
echo ""
echo " Pruebalo asi (desde tu PC, en PowerShell):"
echo ""
echo "   \$env:GW  = \"${INVOKE_URL}\""
echo "   \$env:KEY = \"${KEY_VALUE}\""
echo "   \$env:IP  = \"${MANAGER_IP}\""
echo ""
echo "   curl.exe -i \"\$env:GW/api/medicos\"                            -> 403"
echo "   curl.exe -i -H \"x-api-key: \$env:KEY\" \"\$env:GW/api/medicos\"   -> 200"
echo "   curl.exe -i \"http://\$env:IP:8081/api/medicos\"                 -> 401"
echo ""
echo "======================================================"
