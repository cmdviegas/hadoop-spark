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
# (C) 2023 CARLOS M D VIEGAS
#
# This is a bash script that initialize Hadoop services
#

USERNAME=$1
PASSWORD=$2

# Some coloring
green=$(tput setaf 2)
lblue=$(tput setaf 6)
reset=$(tput sgr0)
printf " * [${green}BOOT${reset}] ${lblue}Starting bootstrap.sh${reset}...\n"

# Load .bashrc
printf " * [${green}BASH${reset}] ${lblue}Loading .bashrc${reset}...\n"

echo "export HDFS_NAMENODE_USER=\"$1\"" >> ~/.bashrc
#source ${MYDIR}/.bashrc
eval "$(tail -n +10 ~/.bashrc)" # workaround for ubuntu .bashrc

# Copy hosts to hosts file
printf " * [${green}HOSTS${reset}] ${lblue}Copying hosts file${reset}...\n"
echo "${PASSWORD}" | sudo -S bash -c "cat ${PWD}/config_files/hosts > /etc/hosts"

# Start SSH service
echo "${PASSWORD}" | sudo -S service ssh start

# Do only at node-master
if [ "$HOSTNAME" == "node-master" ] ; then

    # Install python packages for pyspark (OPTIONAL)
    #pip install --upgrade pip && pip install pandas pyarrow

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
    ${green} ░  ░  ░      ░  ░   ░        ░ ░      ░ ░     ${lblue}$(tput blink)v3.3.5${reset}\n\n"
                                        
    # Time to wait for slaves to establish ssh connection with node-master
    # Only needed when node-master is started before slaves
    sleep 6

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

    # Create /user folders
    hdfs dfs -mkdir -p /user/${HDFS_NAMENODE_USER}
    hdfs dfs -mkdir /spark-logs
    hdfs dfs -mkdir /spark-libs
    hdfs dfs -put ${SPARK_HOME}/jars/*.jar /spark-libs/

    # Start SPARK history server
    printf " * [${green}SPARK${reset}] ${lblue}Starting SPARK history server${reset}...\n"
    start-history-server.sh

    printf "
    ${lblue} APACHE
    ${green}   ██████  ██▓███   ▄▄▄       ██▀███   ██ ▄█▀
    ${green} ▒██    ▒ ▓██░  ██▒▒████▄    ▓██ ▒ ██▒ ██▄█▒ 
    ${green} ░ ▓██▄   ▓██░ ██▓▒▒██  ▀█▄  ▓██ ░▄█ ▒▓███▄░ 
    ${green}   ▒   ██▒▒██▄█▓▒ ▒░██▄▄▄▄██ ▒██▀▀█▄  ▓██ █▄ 
    ${green} ▒██████▒▒▒██▒ ░  ░ ▓█   ▓██▒░██▓ ▒██▒▒██▒ █▄
    ${green} ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░ ▒▒   ▓▒█░░ ▒▓ ░▒▓░▒ ▒▒ ▓▒
    ${green} ░ ░▒  ░ ░░▒ ░       ▒   ▒▒ ░  ░▒ ░ ▒░░ ░▒ ▒░
    ${green} ░  ░  ░  ░░         ░   ▒     ░░   ░ ░ ░░ ░ 
    ${green}       ░                 ░  ░   ░     ░  ░       ${lblue}$(tput blink)v3.3.2${reset}\n\n"

    sleep 5

    printf " * [${green}HDFS${reset}] ${lblue}Checking HDFS nodes report${reset}...\n"
    hdfs dfsadmin -report

    sleep 8

    printf " * [${green}YARN${reset}] ${lblue}Checking YARN nodes list${reset}...\n"
    yarn node -list

    sleep 2

    printf " * ${green}$(tput blink)All set!${reset}\n"
else
    sleep 2

    printf " * ${green}Ready!${reset}\n"
fi

# Start bash terminal
/bin/bash
