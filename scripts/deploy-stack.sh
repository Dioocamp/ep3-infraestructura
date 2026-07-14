#!/usr/bin/env bash
# ======================================================================
#  Despliega (o actualiza) el stack de la clinica en el cluster Swarm.
#  Ejecutar en el NODO MANAGER, desde la raiz de este repositorio.
#  Uso:  bash scripts/deploy-stack.sh
# ======================================================================
set -euo pipefail

STACK="clinica"

echo ">> Desplegando stack '${STACK}'..."
docker stack deploy -c docker-compose.yml "${STACK}" --with-registry-auth

echo ""
echo ">> Servicios del stack:"
docker service ls

echo ""
echo ">> Recuerda: tras cada 'stack deploy' hay que reinyectar las"
echo ">> credenciales de AWS Academy en ms-citas:"
echo ">>   bash scripts/actualizar-credenciales-aws.sh"
