#!/bin/sh
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
# Description: This script downloads Hadoop and Spark files based on the versions specified in the .env file, and also verifies their checksums.

# You can edit this file to suit your requirements.

# Do not execute this file directly. Instead, use: docker compose run --rm init

RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
YELLOW_COLOR='\033[0;33m'
LIGHTBLUE_COLOR='\033[0;36m'
RESET_COLORS='\033[0m'
INFO="[${GREEN_COLOR}INFO${RESET_COLORS}]"
ERROR="[${RED_COLOR}ERROR${RESET_COLORS}]"
WARN="[${YELLOW_COLOR}WARN${RESET_COLORS}]"

log_info() { printf "%b %b\n" "${INFO}" "$1"; }
log_warn() { printf "%b %b\n" "${WARN}" "$1"; }
log_error() { printf "%b %b\n" "${ERROR}" "$1"; }

if [ -z "${DOCKER_COMPOSE_RUN}" ]; then
    log_warn "This script must be executed using: ${YELLOW_COLOR}docker compose run --rm init${RESET_COLORS}"
    exit 1
fi

if [ -f ".env" ]; then
    HADOOP_VERSION=$(grep '^HADOOP_VERSION=' ".env" | cut -d '=' -f2)
    SPARK_VERSION=$(grep '^SPARK_VERSION=' ".env" | cut -d '=' -f2)
else
    log_error ".env file not found."
    exit 1
fi

if [ -z "${HADOOP_VERSION}" ] || [ -z "${SPARK_VERSION}" ]; then
    log_error "HADOOP_VERSION and SPARK_VERSION must be defined in .env file."
    exit 1
fi

HADOOP_FILE="hadoop-${HADOOP_VERSION}.tar.gz"
HADOOP_URL="https://dlcdn.apache.org/hadoop/core/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}"
HADOOP_SHA_URL="https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE}.sha512"

SPARK_FILE="spark-${SPARK_VERSION}-bin-hadoop3.tgz"
SPARK_URL="https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/${SPARK_FILE}"
SPARK_SHA_URL="https://downloads.apache.org/spark/spark-${SPARK_VERSION}/${SPARK_FILE}.sha512"

# Function to extract checksum from .sha512 file (supports both formats)
get_checksum() {
    sha_url="$1"
    sha_file=$(basename "${sha_url}")

    wget -q --no-check-certificate -O "${sha_file}" "${sha_url}"
    if [ $? -ne 0 ]; then
        log_error "Failed to download checksum file: ${sha_file}"
        exit 1
    fi

    if grep -q "^SHA512 (" "${sha_file}" 2>/dev/null; then
        checksum=$(sed -n 's/^SHA512 ([^)]*) = //p' "${sha_file}")
    else
        checksum=$(cut -d ' ' -f1 "${sha_file}")
    fi

    # Remove blank spaces and convert to lowercase
    echo "${checksum}" | tr -d ' \t\n\r' | tr 'A-F' 'a-f'
}

# Download file using aria2c with checksum verification
download_with_checksum() {
    filename="$1"
    url="$2"
    sha_url="$3"

    checksum=$(get_checksum "${sha_url}")
    if [ -z "${checksum}" ]; then
        log_error "Could not extract checksum for ${filename}"
        exit 1
    fi

    # Ensure dependencies are installed
    apk add -q --no-cache aria2

    # Download the file with aria2c
    aria2c -x 6 -s 6 \
        --disable-ipv6 \
        --file-allocation=none \
        --allow-overwrite=true \
        --check-certificate=false \
        --checksum=sha-512=${checksum} \
        "${url}"

    if [ $? -ne 0 ]; then
        log_error "Download or checksum verification failed for ${filename}."
        exit 1
    fi

    # Cleanup checksum file
    rm -f "$(basename "${sha_url}")"
}

# Download Apache Hadoop
if [ ! -f "${HADOOP_FILE}" ]; then
    download_with_checksum "${HADOOP_FILE}" "${HADOOP_URL}" "${HADOOP_SHA_URL}"
fi

# Download Apache Spark
if [ ! -f "${SPARK_FILE}" ]; then
    download_with_checksum "${SPARK_FILE}" "${SPARK_URL}" "${SPARK_SHA_URL}"
fi

# Adjust user permissions for downloaded files
chown 1000:1000 "${HADOOP_FILE}" "${SPARK_FILE}" 2>/dev/null || true
