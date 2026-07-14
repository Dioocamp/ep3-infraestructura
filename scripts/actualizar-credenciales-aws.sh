#!/usr/bin/env bash
# ======================================================================
#  Inyecta/refresca las credenciales de AWS Academy en el servicio
#  clinica_ms-citas (las credenciales del Learner Lab rotan por sesion).
#
#  Ejecutar en el NODO MANAGER cada vez que:
#   - se inicia una nueva sesion de AWS Academy, o
#   - se vuelve a ejecutar 'docker stack deploy'.
#
#  Uso:  bash scripts/actualizar-credenciales-aws.sh [ruta_credentials]
#        (por defecto lee ~/.aws/credentials, pegado desde "AWS Details")
# ======================================================================
set -euo pipefail

CRED_FILE="${1:-$HOME/.aws/credentials}"

if [ ! -f "${CRED_FILE}" ]; then
  echo "ERROR: no existe ${CRED_FILE}."
  echo "Pega alli el bloque [default] que muestra AWS Academy > AWS Details > AWS CLI."
  exit 1
fi

leer_clave() {
  awk -F' *= *' -v k="$1" '$1 == k {print $2; exit}' "${CRED_FILE}"
}

KEY=$(leer_clave aws_access_key_id)
SECRET=$(leer_clave aws_secret_access_key)
TOKEN=$(leer_clave aws_session_token)

if [ -z "${KEY}" ] || [ -z "${SECRET}" ] || [ -z "${TOKEN}" ]; then
  echo "ERROR: ${CRED_FILE} no contiene las tres claves de AWS Academy."
  exit 1
fi

echo ">> Actualizando credenciales de AWS en clinica_ms-citas..."
docker service update --quiet \
  --env-add AWS_ACCESS_KEY_ID="${KEY}" \
  --env-add AWS_SECRET_ACCESS_KEY="${SECRET}" \
  --env-add AWS_SESSION_TOKEN="${TOKEN}" \
  clinica_ms-citas

echo ">> Listo: las replicas de ms-citas se reinician con la nueva sesion."
