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

### Description:
# This Dockerfile creates an image of Apache Hadoop 3.4.1 and Apache Spark 3.5.5.

### How it works:
# This file uses debian linux as base system and then downloads hadoop and spark. In installs all dependencies to run the cluster. The docker image will contain a fully distributed hadoop cluster with multiple worker nodes.

###
##### BUILD STAGE
FROM ubuntu:22.04 AS build

# Bash execution
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment vars
ARG SPARK_VER
ARG HADOOP_VER
ARG USER
ARG PASS
ARG CONTAINER_WORKDIR="/home/${USER}"

ENV SPARK_VERSION=${SPARK_VER}
ENV HADOOP_VERSION=${HADOOP_VER}
ENV CONTAINER_USERNAME="${USER}"
ENV HADOOP_HOME="${CONTAINER_WORKDIR}/hadoop"
ENV SPARK_HOME="${CONTAINER_WORKDIR}/spark"

# Update system and install required packages
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    aria2 \
    && \
    apt-get autoremove -yqq --purge && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working dir
WORKDIR ${CONTAINER_WORKDIR}

# Copy Hadoop and Spark (if exist) to the container workdir
COPY hadoop-${HADOOP_VERSION}.tar.gz .
COPY spark-${SPARK_VERSION}-bin-hadoop3.tgz .

# Extract Hadoop/Spark to the container filesystem
RUN if [ ! -f ${CONTAINER_WORKDIR}/hadoop-${HADOOP_VERSION}.tar.gz ]; then \
        aria2c -x 16 --check-certificate=false --allow-overwrite=false --quiet=true \
        https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz; \
    fi \
    && \
    tar -zxf hadoop-${HADOOP_VERSION}.tar.gz -C ${CONTAINER_WORKDIR} && \
    rm -rf hadoop-${HADOOP_VERSION}.tar.gz && \
    ln -sf ${CONTAINER_WORKDIR}/hadoop-3* ${CONTAINER_WORKDIR}/hadoop \
    && \
    if [ ! -f ${CONTAINER_WORKDIR}/spark-${SPARK_VERSION}-bin-hadoop3.tgz ]; then \
        aria2c -x 16 --check-certificate=false --allow-overwrite=false --quiet=true \
        https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz; \
    fi \
    && \
    tar -zxf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C ${CONTAINER_WORKDIR} && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    ln -sf ${CONTAINER_WORKDIR}/spark-3*-bin-hadoop3 ${CONTAINER_WORKDIR}/spark

# Additional libs for Spark
RUN aria2c -x 16 --check-certificate=false --allow-overwrite=false --quiet=true -d ${SPARK_HOME}/jars \
        https://jdbc.postgresql.org/download/postgresql-42.7.5.jar \
        https://repos.spark-packages.org/graphframes/graphframes/0.8.4-spark3.5-s_2.12/graphframes-0.8.4-spark3.5-s_2.12.jar

###
##### FINAL IMAGE
FROM ubuntu:22.04 AS final

# Bash execution
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment vars
ARG SPARK_VER
ARG HADOOP_VER
ARG USER
ARG PASS

ENV SPARK_VERSION=${SPARK_VER}
ENV HADOOP_VERSION=${HADOOP_VER}
ENV CONTAINER_USERNAME=${USER}
ENV CONTAINER_PASSWORD=${PASS}
ENV CONTAINER_WORKDIR="/home/${USER}"
ENV HADOOP_HOME="${CONTAINER_WORKDIR}/hadoop"
ENV SPARK_HOME="${CONTAINER_WORKDIR}/spark"

# Update system and install required packages
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    sudo dos2unix ssh wget python3.11-minimal python3-pip iproute2 \
    iputils-ping net-tools postgresql-client python3-pandas python3-grpcio openjdk-11-jdk-headless \
    && \
    pip install -q --no-warn-script-location -q graphframes grpcio-status protobuf \
    && \
    apt-get autoremove -yqq --purge && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Creates symbolic link to make 'python' and 'python3' recognized as a system command
RUN ln -sf /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/python /usr/bin/python3

# Creates user and add it to sudoers 
RUN adduser --disabled-password --gecos "" ${CONTAINER_USERNAME} && \
    echo "${CONTAINER_USERNAME}:${CONTAINER_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${CONTAINER_USERNAME} && \
    echo "${CONTAINER_USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${CONTAINER_USERNAME}

# Set new user
USER ${CONTAINER_USERNAME}
WORKDIR ${CONTAINER_WORKDIR}

# Copy all files from local folder to container, except the ones in .dockerignore
COPY --from=build --chown=${CONTAINER_USERNAME}:${CONTAINER_USERNAME} ${CONTAINER_WORKDIR}/hadoop ${HADOOP_HOME}/
COPY --from=build --chown=${CONTAINER_USERNAME}:${CONTAINER_USERNAME} ${CONTAINER_WORKDIR}/spark ${SPARK_HOME}/

# Copy all files from local folder to container, except the ones in .dockerignore
COPY --chown=${CONTAINER_USERNAME}:${CONTAINER_USERNAME} config_files/ ${CONTAINER_WORKDIR}/config_files
COPY --chown=${CONTAINER_USERNAME}:${CONTAINER_USERNAME} myfiles/ ${CONTAINER_WORKDIR}/myfiles
COPY --chown=${CONTAINER_USERNAME}:${CONTAINER_USERNAME} *.sh .
COPY --chown=${CONTAINER_USERNAME}:${CONTAINER_USERNAME} .env .

# Optional (convert charset from UTF-16 to UTF-8)
RUN dos2unix config_files/*

# Load environment variables into .bashrc file
RUN cat config_files/system/bash_profile >> ${CONTAINER_WORKDIR}/.bashrc && \
    sed -i "s/^export\? HDFS_NAMENODE_USER=.*/export HDFS_NAMENODE_USER=${CONTAINER_USERNAME}/" "${CONTAINER_WORKDIR}/.bashrc"

# Copy config files to Hadoop config folder
RUN cp config_files/hadoop/* ${HADOOP_HOME}/etc/hadoop/ && \
    chmod 0755 ${HADOOP_HOME}/etc/hadoop/*.sh && \
    cp config_files/spark/* ${SPARK_HOME}/conf && \
    chmod 0755 ${SPARK_HOME}/conf/*.sh

# Configure ssh for passwordless access
RUN mkdir -p ./.ssh && \
    cat config_files/system/ssh_config >> .ssh/config && \
    chmod 0600 .ssh/config && \
    ssh-keygen -q -N "" -t rsa -f .ssh/id_rsa && \
    cat .ssh/id_rsa.pub >> .ssh/authorized_keys && \
    chmod 0600 .ssh/authorized_keys

# Cleaning and permission set
RUN rm -rf config_files/ && \
    sudo rm -rf /tmp/* /var/tmp/* && \
    chmod 0700 bootstrap.sh config-services.sh start-services.sh

# Run 'bootstrap.sh' script on boot
ENTRYPOINT ${CONTAINER_WORKDIR}/bootstrap.sh
