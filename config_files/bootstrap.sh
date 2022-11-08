#!/bin/bash
# ██████╗  ██████╗ █████╗
# ██╔══██╗██╔════╝██╔══██╗
# ██║  ██║██║     ███████║
# ██║  ██║██║     ██╔══██║
# ██████╔╝╚██████╗██║  ██║
# ╚═════╝  ╚═════╝╚═╝  ╚═╝
# DEPARTAMENTO DE ENGENHARIA DE COMPUTACAO E AUTOMACAO
# UNIVERSIDADE FEDERAL DO RIO GRANDE DO NORTE, NATAL/RN
#
# (C) 2022 CARLOS M D VIEGAS
#
# This is a bash script that initialize Hadoop services
#

# Some coloring
green=$(tput setaf 2)
lblue=$(tput setaf 6)
reset=$(tput sgr0)
printf " * [${green}BOOT${reset}] ${lblue}Starting bootstrap.sh${reset}...\n"

# Load .bashrc
source /root/.bashrc

# Copy hosts to hosts file
cat /root/config_files/hosts >> /etc/hosts

# Start SSH service
service ssh start

# Do only at node-master
if [ "$HOSTNAME" == "node-master" ] ; then

    # Hadoop banner
    printf "
    ${lblue} APACHE
    ${green} ██░ ██  ▄▄▄      ▓█████▄  ▒█████   ▒█████   ██▓███
    ${green}▓██░ ██▒▒████▄    ▒██▀ ██▌▒██▒  ██▒▒██▒  ██▒▓██░  ██▒
    ${green}▒██▀▀██░▒██  ▀█▄  ░██   █▌▒██░  ██▒▒██░  ██▒▓██░ ██▓▒
    ${green}░▓█ ░██ ░██▄▄▄▄██ ░▓█▄   ▌▒██   ██░▒██   ██░▒██▄█▓▒ ▒
    ${green}░▓█▒░██▓ ▓█   ▓██▒░▒████▓ ░ ████▓▒░░ ████▓▒░▒██▒ ░  ░
    ${green} ▒ ░░▒░▒ ▒▒   ▓▒█░ ▒▒▓  ▒ ░ ▒░▒░▒░ ░ ▒░▒░▒░ ▒▓▒░ ░  ░
    ${green} ▒ ░▒░ ░  ▒   ▒▒ ░ ░ ▒  ▒   ░ ▒ ▒░   ░ ▒ ▒░ ░▒ ░
    ${green} ░  ░░ ░  ░   ▒    ░ ░  ░ ░ ░ ░ ▒  ░ ░ ░ ▒  ░░
    ${green} ░  ░  ░      ░  ░   ░        ░ ░      ░ ░     ${lblue}$(tput blink)v3.3.4${reset}\n\n"

    # Time to wait for slaves to establish ssh connection with node-master
    # Only needed when node-master is started before slaves
    sleep 8

    # Format HDFS only at first boot
    FILE=.first_boot
    if [ ! -e $FILE ] ; then
        echo "Do not remove this file" > $FILE
        printf " * [${green}HDFS${reset}] ${lblue}Formatting filesystem${reset}...\n"
        sleep 3
        hdfs namenode -format
    fi

    # Start HDFS service
    printf " * [${green}HDFS${reset}] ${lblue}Starting HDFS service${reset}...\n"
    start-dfs.sh

    sleep 3

    # Start YARN service
    printf " * [${green}YARN${reset}] ${lblue}Starting YARN service${reset}...\n"
    start-yarn.sh

    sleep 5

    # Create /user, /user/root, /spark-logs and /spark-libs folders
    hdfs dfs -mkdir -p /user/root
    hdfs dfs -mkdir /spark-logs
    hdfs dfs -mkdir /spark-libs
    hdfs dfs -put ${SPARK_HOME}/jars/*.jar /spark-libs/

    # Start SPARK history server
    printf " * [${green}SPARK${reset}] ${lblue}Starting SPARK history server${reset}...\n"
    start-history-server.sh

    printf " * ${green}$(tput blink)All set!${reset}\n"
else
    sleep 2

    printf " * ${green}Ready!${reset}\n"
fi

# Start bash terminal
/bin/bash
