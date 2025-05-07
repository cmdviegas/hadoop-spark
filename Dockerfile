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
# This Dockerfile uses Ubuntu Linux as the base system, then downloads and installs Hadoop and Spark along with all necessary dependencies to run the cluster. The resulting Docker image will contain a fully distributed Hadoop cluster with multiple worker nodes.

###
##### BUILD STAGE
FROM ubuntu:24.04 AS build

# Use bash with pipefail to catch errors in pipelines
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment vars
ARG HADOOP_VERSION
ARG SPARK_VERSION
ARG MY_USERNAME
ARG MY_PASSWORD
ARG MY_WORKDIR="/home/${MY_USERNAME}"

ENV MY_USERNAME="${MY_USERNAME}"
ENV HADOOP_VERSION="${HADOOP_VERSION}"
ENV HADOOP_HOME="${MY_WORKDIR}/hadoop"
ENV SPARK_VERSION="${SPARK_VERSION}"
ENV SPARK_HOME="${MY_WORKDIR}/spark"
ENV DEBIAN_FRONTEND=noninteractive 

# Set working dir
WORKDIR ${MY_WORKDIR}

# Copy Hadoop and Spark (if exist) to the container workdir
COPY hadoop-*.tar.gz spark-*.tgz ${MY_WORKDIR}

RUN \
    # Check if hadoop or spark exist \
    if [ ! -f "${MY_WORKDIR}/hadoop-${HADOOP_VERSION}.tar.gz" ] || [ ! -f "${MY_WORKDIR}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" ]; then \
        # Install aria2c to download hadoop \
        apt-get update -qq && \
        apt-get install -y --no-install-recommends \
            aria2 \
        && \
        # Clean apt cache \
        apt-get autoremove -yqq --purge && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi \
    && \
    # Download hadoop according to $HADOOP_VERSION \
    if [ ! -f "${MY_WORKDIR}/hadoop-${HADOOP_VERSION}.tar.gz" ]; then \
        aria2c -x 16 --check-certificate=false --allow-overwrite=false --quiet=true \
        https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz; \
    fi \
    && \
    # Extract hadoop to the container filesystem \
    tar -zxf hadoop-${HADOOP_VERSION}.tar.gz -C ${MY_WORKDIR} && \
    rm -rf hadoop-${HADOOP_VERSION}.tar.gz && \
    ln -sf ${MY_WORKDIR}/hadoop-3* ${MY_WORKDIR}/hadoop \
    && \
    # Check if spark exists inside workdir, if not, download it \
    if [ ! -f "${MY_WORKDIR}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" ]; then \
        # Download spark according to $SPARK_VERSION \
        aria2c --disable-ipv6 -x 16 --check-certificate=false --allow-overwrite=false --quiet=true \
        https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
        # Additional libs for Spark \
        aria2c --disable-ipv6 -x 16 --check-certificate=false --allow-overwrite=false --quiet=true -d ${SPARK_HOME}/jars \
        https://jdbc.postgresql.org/download/postgresql-42.7.5.jar \
        https://repos.spark-packages.org/graphframes/graphframes/0.8.4-spark3.5-s_2.12/graphframes-0.8.4-spark3.5-s_2.12.jar; \
    fi \
    && \
    # Extract spark to the container filesystem \
    tar -zxf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C ${MY_WORKDIR} && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    ln -sf ${MY_WORKDIR}/spark-3*-bin-hadoop3 ${MY_WORKDIR}/spark

###
##### FINAL IMAGE
FROM ubuntu:24.04 AS final

# Use bash with pipefail to catch errors in pipelines
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment vars
ARG HADOOP_VERSION
ARG SPARK_VERSION
ARG MY_USERNAME
ARG MY_PASSWORD

ENV MY_USERNAME="${MY_USERNAME}"
ENV MY_PASSWORD="${MY_PASSWORD}"
ENV MY_WORKDIR="/home/${MY_USERNAME}"

ENV HADOOP_VERSION="${HADOOP_VERSION}"
ENV HADOOP_HOME="${MY_WORKDIR}/hadoop"
ENV SPARK_VERSION="${SPARK_VERSION}"
ENV SPARK_HOME="${MY_WORKDIR}/spark"
ENV DEBIAN_FRONTEND=noninteractive 

RUN \
    # Update system and install required packages \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jdk-headless \
        python3.12-minimal \
        python3-pip \
        python3-pandas \
        python3-grpcio \
        sudo \
        dos2unix \
        ssh \
        wget \
        iproute2 \
        iputils-ping \
        net-tools \
    && \
    pip install -q --break-system-packages --no-warn-script-location -q graphframes grpcio-status protobuf \
    && \
    # Clean apt cache \
    apt-get autoremove -yqq --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
    && \
    # Creates symbolic link to make 'python' and 'python3' recognized as a system command \
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/python /usr/bin/python3 \
    && \
    # Creates user and adds it to sudoers \
    adduser --disabled-password --gecos "" ${MY_USERNAME} && \
    echo "${MY_USERNAME}:${MY_PASSWORD}" | chpasswd && \
    usermod -aG sudo ${MY_USERNAME} && \
    echo "${MY_USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${MY_USERNAME}

# Set new user
USER ${MY_USERNAME}
WORKDIR ${MY_WORKDIR}

# Copy all files from build stage to the container
COPY --from=build --chown=${MY_USERNAME}:${MY_USERNAME} ${MY_WORKDIR}/hadoop ${HADOOP_HOME}/
COPY --from=build --chown=${MY_USERNAME}:${MY_USERNAME} ${MY_WORKDIR}/spark ${SPARK_HOME}/

# Copy all files from local folder to container, except the ones in .dockerignore
COPY --chown=${MY_USERNAME}:${MY_USERNAME} config_files/ ${MY_WORKDIR}/config_files
COPY --chown=${MY_USERNAME}:${MY_USERNAME} bootstrap.sh config-services.sh start-services.sh .env ${MY_WORKDIR}/

RUN \
    # Convert charset from UTF-16 to UTF-8 to ensure compatibility \
    dos2unix config_files/* *.sh .env \
    && \
    # Load environment variables into .bashrc file \
    cat config_files/system/bash_profile >> ${MY_WORKDIR}/.bashrc && \
    sed -i "s/^export\? HDFS_NAMENODE_USER=.*/export HDFS_NAMENODE_USER=${MY_USERNAME}/" "${MY_WORKDIR}/.bashrc" \
    && \
    # Set JAVA_HOME dynamically based on installed Java version \
    JAVA_HOME_DIR=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")") && \
    sed -i "s|^export JAVA_HOME=.*|export JAVA_HOME=\"$JAVA_HOME_DIR\"|" "${MY_WORKDIR}/.bashrc" \
    && \
    # Copy config files to hadoop config folder \
    mv config_files/hadoop/* ${HADOOP_HOME}/etc/hadoop/ && \
    chmod 0755 ${HADOOP_HOME}/etc/hadoop/*.sh && \
    # Copy config files to spark config folder \
    mv config_files/spark/* ${SPARK_HOME}/conf && \
    chmod 0755 ${SPARK_HOME}/conf/*.sh \
    && \
    # Configure ssh for passwordless access \
    mkdir -p ./.ssh && \
    cat config_files/system/ssh_config >> .ssh/config && \
    ssh-keygen -q -N "" -t rsa -f .ssh/id_rsa && \
    cat .ssh/id_rsa.pub >> .ssh/authorized_keys && \
    chmod 0600 .ssh/authorized_keys .ssh/config \
    && \
    # Cleaning and permission set \
    rm -rf config_files/ && \
    sudo rm -rf /tmp/* /var/tmp/* && \
    chmod 0700 bootstrap.sh config-services.sh start-services.sh
   
# Run 'bootstrap.sh' on startup
ENTRYPOINT ["./bootstrap.sh"]
