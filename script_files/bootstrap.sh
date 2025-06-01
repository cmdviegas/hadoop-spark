#!/usr/bin/env bash
# ██████╗  ██████╗ █████╗
# ██╔══██╗██╔════╝██╔══██╗
# ██║  ██║██║     ███████║
# ██║  ██║██║     ██╔══██║
# ██████╔╝╚██████╗██║  ██║
# ╚═════╝  ╚═════╝╚═╝  ╚═╝
# DEPARTAMENTO DE ENGENHARIA DE COMPUTACAO E AUTOMACAO
# UNIVERSIDADE FEDERAL DO RIO GRANDE DO NORTE, NATAL/RN
#
# (C) 2022-2025 CARLOS M D VIEGAS
# https://github.com/cmdviegas
#

# Description: This script initializes hadoop, spark and other required services

# How it works:
# 1- Loads .bashrc
# 2- Sets user password according scecrets file
# 3- Sets hadoop workers list according to NUM_WORKER_NODES
# 4- Starts SSH server
# 5- Calls 'services.sh' script to run hadoop and spark services (only at spark-master)

# Log helpers
log_info()  { printf "%b %s\n" "${INFO}" "$1"; }

# Load .bashrc
eval "$(tail -n +10 "${HOME}/.bashrc")" # Alternative to 'source .bashrc' (hack for debian-based systems)

# Sets user password according secrets file
if [ -f "$MY_SECRETS_FILE" ]; then
  MY_PASSWORD=$(cat "$MY_SECRETS_FILE")
  echo "myuser:${MY_PASSWORD}" | sudo chpasswd -e
fi

# Updates hadoop workers file according to the amount of worker nodes
truncate -s 0 ${HADOOP_CONF_DIR}/workers
for i in $(seq 1 "${NUM_WORKER_NODES}"); do
  echo "${STACK_NAME}-worker-$i" >> "${HADOOP_CONF_DIR}/workers"
done

# Starts ssh server
sudo service ssh start > /dev/null 2>&1

# Starts hadoop/spark services (only at master)
if [ "$1" == "MASTER" ] ; then
  sleep 8
  [ -f "${HOME}/services.sh" ] && bash -c "${HOME}/services.sh start"
else
  log_info "Node ${YELLOW_COLOR}${HOSTNAME}${RESET_COLORS} started, awaiting master connection..."
fi

exec /bin/bash
