#!/usr/bin/env bash
# ======================================================================
#  Inyecta/actualiza las credenciales de AWS en el servicio
#  clinica_ms-citas (necesarias para publicar en la cola SQS).
#
#  Con una cuenta personal de AWS las credenciales NO expiran, asi que
#  normalmente solo se ejecuta UNA VEZ. Vuelve a ejecutarlo solo si
#  regeneras el access key en IAM.
#
#  Uso:  bash scripts/actualizar-credenciales-aws.sh [ruta_credentials]
#        (por defecto lee ~/.aws/credentials)
# ======================================================================
set -euo pipefail

CRED_FILE="${1:-$HOME/.aws/credentials}"

if [ ! -f "${CRED_FILE}" ]; then
  echo "ERROR: no existe ${CRED_FILE}."
  echo "Pega alli el bloque [default] con tu access key de IAM."
  exit 1
fi

leer_clave() {
  awk -F' *= *' -v k="$1" '$1 == k {print $2; exit}' "${CRED_FILE}"
}

KEY=$(leer_clave aws_access_key_id)
SECRET=$(leer_clave aws_secret_access_key)
TOKEN=$(leer_clave aws_session_token)

if [ -z "${KEY}" ] || [ -z "${SECRET}" ]; then
  echo "ERROR: ${CRED_FILE} no contiene aws_access_key_id / aws_secret_access_key."
  exit 1
fi

echo ">> Actualizando credenciales de AWS en clinica_ms-citas..."

if [ -n "${TOKEN}" ]; then
  # Solo aplica si usas credenciales temporales (AWS Academy / STS).
  docker service update --quiet \
    --env-add AWS_ACCESS_KEY_ID="${KEY}" \
    --env-add AWS_SECRET_ACCESS_KEY="${SECRET}" \
    --env-add AWS_SESSION_TOKEN="${TOKEN}" \
    clinica_ms-citas
else
  # Cuenta personal: access key permanente, sin session token.
  docker service update --quiet \
    --env-add AWS_ACCESS_KEY_ID="${KEY}" \
    --env-add AWS_SECRET_ACCESS_KEY="${SECRET}" \
    clinica_ms-citas
fi

echo ">> Listo: las replicas de ms-citas se reinician con las credenciales nuevas."
