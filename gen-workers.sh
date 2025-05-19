#!/bin/bash

COMPOSE_FILE="/workspace/workers.yml"
NUM_WORKER_NODES=${NUM_WORKER_NODES}

echo > "$COMPOSE_FILE"

cat > "$COMPOSE_FILE" << EOF
services:
EOF

for i in $(seq 1 $NUM_WORKER_NODES); do
  cat >> "$COMPOSE_FILE" << EOF
  worker-$i:
    image: \${IMAGE_NAME}
    container_name: \${STACK_NAME}-worker-$i
    hostname: \${STACK_NAME}-worker-$i
    tty: true
    restart: on-failure
    networks:
      - spark_network
    volumes:
      - ./myfiles:/home/\${MY_USERNAME}/myfiles
      - .env:/home/\${MY_USERNAME}/.env
    entrypoint: ["bash", "bootstrap.sh"]
    command: ["WORKER"]

EOF
done

printf "\n[INFO] workers.yml file successfully generated\n" "$NUM_WORKER_NODES" "$COMPOSE_FILE"
printf "[INFO] You can now start the cluster with:\n"
printf "       docker compose build && docker compose -f workers.yml -f docker-compose.yml up\n\n"