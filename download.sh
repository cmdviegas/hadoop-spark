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
# (C) 2024 CARLOS M D VIEGAS
# https://github.com/cmdviegas
#
# This is a bash script to automatically download hadoop and spark 
#

read -p "Download Apache Hadoop 3.4.0? (y/N): " hadoop
read -p "Download Apache Spark 3.5.2? (y/N): " spark
read -p "Download Apache Hive 3.1.3? (y/N): " hive

if [[ "$hadoop" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
  wget -nc --no-check-certificate https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
fi

if [[ "$spark" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
  wget -nc --no-check-certificate https://dlcdn.apache.org/spark/spark-3.5.2/spark-3.5.2-bin-hadoop3.tgz
fi

if [[ "$hive" =~ ^([Yy]|[Yy][Ee][Ss])$ ]]; then
  wget -nc --no-check-certificate https://dlcdn.apache.org/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz
fi

