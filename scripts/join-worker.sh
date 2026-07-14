#!/usr/bin/env bash
# ======================================================================
#  Une esta maquina como NODO WORKER al cluster Swarm (EC2 #2).
#  Uso:  bash scripts/join-worker.sh <TOKEN> <IP_MANAGER>
#
#  El token lo imprime scripts/init-swarm.sh en el manager, o se obtiene
#  con:  docker swarm join-token -q worker
# ======================================================================
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "Uso: bash scripts/join-worker.sh <TOKEN> <IP_MANAGER>"
  exit 1
fi

TOKEN="$1"
MANAGER_IP="$2"

echo ">> Uniendo este nodo como worker al cluster ${MANAGER_IP}:2377..."
docker swarm join --token "${TOKEN}" "${MANAGER_IP}:2377"

echo ">> Listo. Verifica en el manager con:  docker node ls"
