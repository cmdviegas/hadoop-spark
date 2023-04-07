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
# This is a bash script to automatically download hadoop and spark 
#

read -p "Deseja fazer o download do Apache Hadoop 3.3.5 (yes/NO): " option

if [[ "$option" =~ ^[Yy][Ee][Ss]$ ]]; then
  wget --no-check-certificate https://dlcdn.apache.org/hadoop/common/hadoop-3.3.5/hadoop-3.3.5.tar.gz
fi

read -p "Deseja fazer o download do Apache Spark 3.3.2 (yes/NO): " option

if [[ "$option" =~ ^[Yy][Ee][Ss]$ ]]; then
  wget --no-check-certificate https://dlcdn.apache.org/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz
fi
