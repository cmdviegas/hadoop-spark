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

read -p "Would you like to download Hadoop and Spark from Apache servers? (yes/NO): " option

if [[ "$option" =~ ^[Yy][Ee][Ss]$ ]]; then

  read -p "Download Apache Hadoop 3.3.5? (yes/NO): " hadoop

  read -p "Download Apache Spark 3.3.2 (yes/NO): " spark

  if [[ "$hadoop" =~ ^[Yy][Ee][Ss]$ ]]; then
    wget --no-check-certificate https://dlcdn.apache.org/hadoop/common/hadoop-3.3.5/hadoop-3.3.5.tar.gz
  fi

  if [[ "$spark" =~ ^[Yy][Ee][Ss]$ ]]; then
    wget --no-check-certificate https://dlcdn.apache.org/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz
  fi

fi
