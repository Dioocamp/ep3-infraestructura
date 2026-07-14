#!/usr/bin/env bash
# ======================================================================
#  Inicializa el cluster Docker Swarm en el NODO MANAGER (EC2 #1).
#  Uso:  bash scripts/init-swarm.sh [IP_PRIVADA_DEL_MANAGER]
# ======================================================================
set -euo pipefail

# IP privada de la instancia (autodetectada si no se pasa como argumento).
ADVERTISE_ADDR="${1:-$(hostname -I | awk '{print $1}')}"

echo ">> Inicializando Docker Swarm (advertise-addr: ${ADVERTISE_ADDR})..."
docker swarm init --advertise-addr "${ADVERTISE_ADDR}"

echo ""
echo ">> Cluster creado. Para agregar un NODO WORKER, ejecuta en la otra"
echo ">> instancia el comando que aparece a continuacion:"
echo ""
docker swarm join-token worker

echo ""
echo ">> Para agregar otro MANAGER (alta disponibilidad del plano de control):"
docker swarm join-token manager

echo ""
echo ">> Estado actual de los nodos:"
docker node ls
