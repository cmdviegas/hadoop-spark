# ██████╗  ██████╗ █████╗
# ██╔══██╗██╔════╝██╔══██╗
# ██║  ██║██║     ███████║
# ██║  ██║██║     ██╔══██║
# ██████╔╝╚██████╗██║  ██║
# ╚═════╝  ╚═════╝╚═╝  ╚═╝
# DEPARTAMENTO DE ENGENHARIA DE COMPUTACAO E AUTOMACAO
# UNIVERSIDADE FEDERAL DO RIO GRANDE DO NORTE, NATAL/RN
#
# (C) 2023 CARLOS M D VIEGAS
#
# This Dockerfile creates an image of Apache Hadoop 3.3.5 and Apache Spark 3.3.2
#

# Import base image
FROM ubuntu:22.04

# Update system and install required packages (silently)
RUN apt-get update && apt-get install -y sudo ssh vim openjdk-11-jdk-headless python3.9 python3-pip net-tools iputils-ping iproute2 dos2unix

# Create a symbolic link to make 'python' be recognized as a system command
RUN sudo ln -sf /usr/bin/python3 /usr/bin/python

# Creates spark user, add to sudoers and defines working dir
ARG USER
ARG PASS
ENV USERNAME "${USER}"
ENV PASSWORD "${PASS}"

RUN adduser --disabled-password --gecos "" ${USERNAME}
RUN echo "${USERNAME}:${PASSWORD}" | chpasswd
RUN usermod -aG sudo ${USERNAME}
USER ${USERNAME}
ENV MYDIR /home/${USERNAME}
WORKDIR ${MYDIR}

# Configure Hadoop enviroment variables
ENV HADOOP_HOME "${MYDIR}/hadoop"
ENV HADOOP_CONF_DIR "${HADOOP_HOME}/etc/hadoop"
ENV SPARK_HOME "${HADOOP_HOME}/spark"

# Copy all files from local folder to container, except the ones in .dockerignore
COPY . .

# Set permissions
RUN echo "${PASSWORD}" | sudo -S chown "${USERNAME}:${USERNAME}" -R config_files/
RUN echo "${PASSWORD}" | sudo -S chown "${USERNAME}:${USERNAME}" ${MYDIR}/download.sh
RUN chmod +x ${MYDIR}/download.sh

# Copy and extract Hadoop to container filesystem
# Download hadoop-3.3.5.tar.gz from Apache (if needed)
#RUN wget --no-check-certificate https://dlcdn.apache.org/hadoop/common/hadoop-3.3.5/hadoop-3.3.5.tar.gz
RUN tar -zxf hadoop-3*.tar.gz -C ${MYDIR} && rm -rf hadoop-3*.tar.gz
RUN ln -sf hadoop-3* hadoop

# Download spark-3.3.2-bin-hadoop3.tgz from Apache (if needed)
#RUN wget --no-check-certificate https://dlcdn.apache.org/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz
RUN tar -zxf spark-3*-bin-hadoop3.tgz -C ${HADOOP_HOME} && rm -rf spark-3*-bin-hadoop3.tgz
RUN ln -sf ${HADOOP_HOME}/spark-3*-bin-hadoop3 ${SPARK_HOME}

# Optional (convert charset from UTF-16 to UTF-8)
RUN dos2unix config_files/*
RUN dos2unix ${MYDIR}/download.sh

# Load environment variables into .bashrc file
RUN cat config_files/bashrc >> .bashrc

# Copy config files to Hadoop config folder
RUN cp config_files/*.xml ${HADOOP_CONF_DIR}/
RUN cp config_files/workers ${HADOOP_CONF_DIR}/
RUN cp config_files/hadoop-env.sh ${HADOOP_CONF_DIR}/
RUN chmod 0755 ${HADOOP_CONF_DIR}/*.sh
RUN cp config_files/spark-defaults.conf ${SPARK_HOME}/conf
RUN cp config_files/spark-env.sh ${SPARK_HOME}/conf
RUN chmod 0755 ${SPARK_HOME}/conf/*.sh

# Configure ssh for passwordless access
RUN mkdir -p ./.ssh && cat config_files/ssh_config >> .ssh/config && chmod 0600 .ssh/config
RUN ssh-keygen -q -N "" -t rsa -f .ssh/id_rsa
RUN cp .ssh/id_rsa.pub .ssh/authorized_keys && chmod 0600 .ssh/authorized_keys

# Run a script on boot
RUN chmod 0700 config_files/bootstrap.sh
CMD ${MYDIR}/config_files/bootstrap.sh ${USERNAME} ${PASSWORD}
