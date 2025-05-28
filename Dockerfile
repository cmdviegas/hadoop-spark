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

# Description: This Dockerfile creates an image of Apache Hadoop 3.4.1 and Apache Spark 3.5.5.

# How it works:
# This Dockerfile uses Ubuntu Linux as the base system, then downloads and installs Hadoop and Spark along with all necessary dependencies to run the cluster. The resulting Docker image will contain a fully distributed Hadoop cluster with multiple worker nodes.

# BUILD STAGE for Hadoop
FROM ubuntu:24.04 AS build-hadoop

# Use bash with pipefail to catch errors in pipelines
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment vars
ARG HADOOP_VERSION
ARG APT_MIRROR

ENV MY_USERNAME=myuser
ENV MY_WORKDIR=/home/${MY_USERNAME}
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HADOOP_HOME=${MY_WORKDIR}/hadoop
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_MIRROR="${APT_MIRROR:-http://archive.ubuntu.com/ubuntu}"

# Set working dir
WORKDIR ${MY_WORKDIR}

# Copy Hadoop (if exist) to the container workdir
COPY hadoop-*.tar.gz ${MY_WORKDIR}

RUN \
    # Check if hadoop exist \
    if [ ! -f "${MY_WORKDIR}/hadoop-${HADOOP_VERSION}.tar.gz" ]; then \
        # Install aria2c to download hadoop \
        sed -i "s|http://archive.ubuntu.com/ubuntu|${APT_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources && \
        apt-get update -qq && \
        apt-get install -y --no-install-recommends \
            aria2 \
            ca-certificates \
        && \
        # Clean apt cache \
        apt-get autoremove -yqq --purge && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi \
    && \    
    # Check if hadoop exists inside workdir, if not, download it \
    if [ ! -f "${MY_WORKDIR}/hadoop-${HADOOP_VERSION}.tar.gz" ]; then \
        # Download hadoop \
        aria2c --disable-ipv6 -x 16 --allow-overwrite=false \
        https://dlcdn.apache.org/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz; \
    fi \
    && \
    # Extract hadoop to the container filesystem \
    tar -zxf hadoop-${HADOOP_VERSION}.tar.gz -C ${MY_WORKDIR} && \
    rm -rf hadoop-${HADOOP_VERSION}.tar.gz && \
    ln -sf ${MY_WORKDIR}/hadoop-3* ${HADOOP_HOME}

# BUILD STAGE for Spark
FROM ubuntu:24.04 AS build-spark

# Use bash with pipefail to catch errors in pipelines
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment vars
ARG SPARK_VERSION
ARG APT_MIRROR

ENV MY_USERNAME=myuser
ENV MY_WORKDIR=/home/${MY_USERNAME}
ENV SPARK_VERSION=${SPARK_VERSION}
ENV SPARK_HOME=${MY_WORKDIR}/spark
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_MIRROR="${APT_MIRROR:-http://archive.ubuntu.com/ubuntu}"

# Set working dir
WORKDIR ${MY_WORKDIR}

# Copy Spark (if exist) to the container workdir
COPY spark-*.tgz ${MY_WORKDIR}

RUN \
    # Check if spark exist \
    if [ ! -f "${MY_WORKDIR}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" ]; then \
        # Install aria2c to download spark \
        sed -i "s|http://archive.ubuntu.com/ubuntu|${APT_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources && \
        apt-get update -qq && \
        apt-get install -y --no-install-recommends \
            aria2 \
            ca-certificates \
        && \
        # Clean apt cache \
        apt-get autoremove -yqq --purge && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
    fi \
    && \
    # Check if spark exists inside workdir, if not, download it \
    if [ ! -f "${MY_WORKDIR}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" ]; then \
        # Download spark \
        aria2c --disable-ipv6 -x 16 --allow-overwrite=false \
        https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz; \
    fi \
    && \
    # Extract spark to the container filesystem \
    tar -zxf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C ${MY_WORKDIR} && \
    rm -rf spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
    ln -sf ${MY_WORKDIR}/spark-3*-bin-hadoop3 ${SPARK_HOME}

# FINAL IMAGE STAGE
FROM ubuntu:24.04 AS final

# Use bash with pipefail to catch errors in pipelines
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Environment vars
ARG HADOOP_VERSION
ARG SPARK_VERSION
ARG APT_MIRROR

ENV MY_USERNAME=myuser
ENV MY_WORKDIR=/home/${MY_USERNAME}
ENV HADOOP_VERSION=${HADOOP_VERSION}
ENV HADOOP_HOME=${MY_WORKDIR}/hadoop
ENV SPARK_VERSION=${SPARK_VERSION}
ENV SPARK_HOME=${MY_WORKDIR}/spark
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_MIRROR="${APT_MIRROR:-http://archive.ubuntu.com/ubuntu}"

RUN \
    # Update system and install required packages \
    sed -i "s|http://archive.ubuntu.com/ubuntu|${APT_MIRROR}|g" /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jdk-headless \
        python3.12-minimal \
        python3-pip \
        python3-pandas \
        python3-grpcio \
        python3-protobuf \
        sudo \
        nano \
        dos2unix \
        ssh \
        wget \
        iproute2 \
        iputils-ping \
        net-tools \
        ca-certificates \
    && \
    pip install -q --break-system-packages --no-warn-script-location \
        graphframes \
        grpcio-status \
        pyspark==${SPARK_VERSION} \
        pyarrow==20.0.0 \
        jupyterlab==4.4.2 \
    && \
    # Clean apt cache \
    apt-get autoremove -yqq --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
    && \
    # Creates symbolic link to make 'python' and 'python3' recognized as a system command \
    ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 \
    && \
    # Removes default ubuntu user \
    userdel --remove ubuntu || true \
    && \
    # Creates myuser according $MY_USERNAME and adds it to sudoers \
    adduser --disabled-password --gecos "" ${MY_USERNAME} && \
    usermod -aG sudo ${MY_USERNAME} && \
    echo "${MY_USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${MY_USERNAME}

# Set new user
USER ${MY_USERNAME}
WORKDIR ${MY_WORKDIR}

# Copy all files from build stage to the container
COPY --from=build-hadoop --chown=${MY_USERNAME}:${MY_USERNAME} ${MY_WORKDIR}/hadoop ${HADOOP_HOME}/
COPY --from=build-spark --chown=${MY_USERNAME}:${MY_USERNAME} ${MY_WORKDIR}/spark ${SPARK_HOME}/

# Copy files from local folder to container, except the ones in .dockerignore
COPY --chown=${MY_USERNAME}:${MY_USERNAME} config_files/system/.bash_common ${MY_WORKDIR}/.bash_common
COPY --chown=${MY_USERNAME}:${MY_USERNAME} config_files/system/ssh_config ${MY_WORKDIR}/.ssh/config
COPY --chown=${MY_USERNAME}:${MY_USERNAME} config_files/jupyterlab/overrides.json \
/usr/local/share/jupyter/lab/settings/overrides.json
COPY --chown=${MY_USERNAME}:${MY_USERNAME} bootstrap.sh services.sh ${MY_WORKDIR}/

RUN \
    # Convert charset from UTF-16 to UTF-8 to ensure compatibility \
    dos2unix -q -k *.sh .env \
    && \
    # Load environment variables into .bashrc file \
    echo -e '\n[ -f "${HOME}/.bash_common" ] && . "${HOME}/.bash_common"' >> "${MY_WORKDIR}/.bashrc" \
    && \
    # Sets JAVA_HOME dynamically based on Java version installed
    JAVA_HOME_DIR=$(dirname "$(dirname "$(readlink -f "$(command -v java)")")") && \
    sed -i "s|^export JAVA_HOME=.*|export JAVA_HOME=\"${JAVA_HOME_DIR}\"|" "${HOME}/.bash_common" \
    && \
    # Additional libs for spark \
    wget --no-verbose --directory-prefix=${SPARK_HOME}/jars \
        https://jdbc.postgresql.org/download/postgresql-42.7.5.jar \
        https://repos.spark-packages.org/graphframes/graphframes/0.8.4-spark3.5-s_2.12/graphframes-0.8.4-spark3.5-s_2.12.jar \
    && \
    # Create a symbolic link for the spark_shuffle in Hadoop's YARN lib directory \
    ln -sf ${SPARK_HOME}/yarn/spark-${SPARK_VERSION}-yarn-shuffle.jar ${HADOOP_HOME}/share/hadoop/yarn/lib/spark-${SPARK_VERSION}-yarn-shuffle.jar \
    && \
    # Configure ssh for passwordless access \
    ssh-keygen -q -N "" -t rsa -f .ssh/id_rsa && \
    cat .ssh/id_rsa.pub >> .ssh/authorized_keys && \
    chmod 0600 .ssh/authorized_keys .ssh/config \
    && \
    # Cleaning and permission set \
    sudo rm -rf /tmp/* /var/tmp/* && \
    chmod 0700 bootstrap.sh services.sh
   
# Run 'bootstrap.sh' on startup
ENTRYPOINT ["bash", "bootstrap.sh"]
