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
GR=$(tput setaf 2)
LB=$(tput setaf 6)
RE=$(tput sgr0)
SYS="[${GR}SYSTEM${RE}]${LB}"
CLUSTER="[${GR}CLUSTER${RE}]${LB}"
EOF="${RE}...\n"

printf "${SYS} Starting bootstrap.sh${EOF}"

# Copy hosts to hosts file
FILE=.first_boot
if [ ! -e $FILE ] ; then
    printf "${SYS} Copying hosts file to /etc/hosts${EOF}"
    echo "${PASSWORD}" | sudo -S bash -c "cat ${PWD}/config_files/hosts > /etc/hosts"
fi

# Load .bashrc
printf "\n${SYS} Loading environment variables in .bashrc${EOF}"
#source ${MYDIR}/.bashrc
eval "$(tail -n +10 ~/.bashrc)" # workaround for ubuntu .bashrc

# Start SSH service
printf "${SYS} Starting ssh server${EOF}"
echo "${PASSWORD}" | sudo -S service ssh start

# Do only at node-master
if [ "$HOSTNAME" == "node-master" ] ; then

    # Hadoop banner
    printf "
    ${LB} APACHE
    ${GR} ██░ ██  ▄▄▄      ▓█████▄  ▒█████   ▒█████   ██▓███
    ${GR}▓██░ ██▒▒████▄    ▒██▀ ██▌▒██▒  ██▒▒██▒  ██▒▓██░  ██▒
    ${GR}▒██▀▀██░▒██  ▀█▄  ░██   █▌▒██░  ██▒▒██░  ██▒▓██░ ██▓▒
    ${GR}░▓█ ░██ ░██▄▄▄▄██ ░▓█▄   ▌▒██   ██░▒██   ██░▒██▄█▓▒ ▒
    ${GR}░▓█▒░██▓ ▓█   ▓██▒░▒████▓ ░ ████▓▒░░ ████▓▒░▒██▒ ░  ░
    ${GR} ▒ ░░▒░▒ ▒▒   ▓▒█░ ▒▒▓  ▒ ░ ▒░▒░▒░ ░ ▒░▒░▒░ ▒▓▒░ ░  ░
    ${GR} ▒ ░▒░ ░  ▒   ▒▒ ░ ░ ▒  ▒   ░ ▒ ▒░   ░ ▒ ▒░ ░▒ ░
    ${GR} ░  ░░ ░  ░   ▒    ░ ░  ░ ░ ░ ░ ▒  ░ ░ ░ ▒  ░░
    ${GR} ░  ░  ░      ░  ░   ░        ░ ░      ░ ░     ${LB}$(tput blink)v3.3.5${RE}\n\n"
                                        
    # Time to wait for slaves to establish ssh connection with node-master
    # Only needed when node-master is started before slaves
    sleep 5

    # Format HDFS only at first boot
    if [ ! -e $FILE ] ; then
        printf "${CLUSTER} Formatting filesystem${EOF}"
        hdfs namenode -format
    fi

    sleep 5

    # Start HDFS and YARN services
    printf "${CLUSTER} Starting HDFS and YARN services${EOF}"
    start-dfs.sh && start-yarn.sh

    sleep 5

    # Create /user folders
    if [ ! -e $FILE ] ; then
        printf "${CLUSTER} Creating folders in HDFS${EOF}"
        hdfs dfs -mkdir -p /user/${HDFS_NAMENODE_USER}
        hdfs dfs -mkdir /spark-logs
        hdfs dfs -mkdir /spark-libs
        hdfs dfs -put ${SPARK_HOME}/jars/*.jar /spark-libs/
    fi

    printf "
    ${LB} APACHE
    ${GR}   ██████  ██▓███   ▄▄▄       ██▀███   ██ ▄█▀
    ${GR} ▒██    ▒ ▓██░  ██▒▒████▄    ▓██ ▒ ██▒ ██▄█▒ 
    ${GR} ░ ▓██▄   ▓██░ ██▓▒▒██  ▀█▄  ▓██ ░▄█ ▒▓███▄░ 
    ${GR}   ▒   ██▒▒██▄█▓▒ ▒░██▄▄▄▄██ ▒██▀▀█▄  ▓██ █▄ 
    ${GR} ▒██████▒▒▒██▒ ░  ░ ▓█   ▓██▒░██▓ ▒██▒▒██▒ █▄
    ${GR} ▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░ ▒▒   ▓▒█░░ ▒▓ ░▒▓░▒ ▒▒ ▓▒
    ${GR} ░ ░▒  ░ ░░▒ ░       ▒   ▒▒ ░  ░▒ ░ ▒░░ ░▒ ▒░
    ${GR} ░  ░  ░  ░░         ░   ▒     ░░   ░ ░ ░░ ░ 
    ${GR}       ░                 ░  ░   ░     ░  ░       ${LB}$(tput blink)v3.3.2${RE}\n\n"

    sleep 5

    # Pandas installation (optional)
    # if [ ! -e $FILE ] ; then
    #    echo "${PASSWORD}" | sudo apt install -y python3-pip
    #    pip install pandas==1.5.3 pyarrow==11.0.0
    #    echo "export PATH=\"$PATH:$PWD/.local/bin\"" >> ~/.bashrc
    #    eval "$(tail -n +10 ~/.bashrc)" # workaround for ubuntu .bashrc
    #fi
    
    # Start SPARK history server
    printf "${CLUSTER} Starting SPARK history server${EOF}"
    start-history-server.sh

    printf "${CLUSTER} Checking HDFS nodes report${EOF}"
    hdfs dfsadmin -report

    sleep 5

    printf "${CLUSTER} Checking YARN nodes list${EOF}"
    yarn node -list

    printf "${CLUSTER} ${GR}$(tput blink)ALL SET!${RE}\n"
fi

# Cleaning up
if [ ! -e $FILE ] ; then
    echo "Do not remove this file" > $FILE
    rm -rf config_files/
fi

# Start bash terminal
/bin/bash
