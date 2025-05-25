@echo off
rem ██████╗  ██████╗ █████╗
rem ██╔══██╗██╔════╝██╔══██╗
rem ██║  ██║██║     ███████║
rem ██║  ██║██║     ██╔══██║
rem ██████╔╝╚██████╗██║  ██║
rem ╚═════╝  ╚═════╝╚═╝  ╚═╝
rem DEPARTAMENTO DE ENGENHARIA DE COMPUTACAO E AUTOMACAO
rem UNIVERSIDADE FEDERAL DO RIO GRANDE DO NORTE, NATAL/RN
rem
rem (C) 2022-2025 CARLOS M D VIEGAS
rem https://github.com/cmdviegas
rem
rem Description: This is a batch script to download Hadoop and Spark (if needed) through a Windows Command Prompt or Powershell

if not exist ".env" (
    echo [ERROR] .env file not found
    exit /b 1
)

set "HADOOP_VERSION="
set "SPARK_VERSION="

for /f "usebackq tokens=1,2 delims==" %%A in (".env") do (
    if "%%A"=="HADOOP_VERSION" set "HADOOP_VERSION=%%B"
    if "%%A"=="SPARK_VERSION" set "SPARK_VERSION=%%B"
)

if not defined HADOOP_VERSION (
    echo [ERROR] HADOOP_VERSION not defined in the .env file.
    exit /b 1
)

if not defined SPARK_VERSION (
    echo [ERROR] SPARK_VERSION not defined in the .env file.
    exit /b 1
)

echo Downloading Apache Hadoop %HADOOP_VERSION% and Apache Spark %SPARK_VERSION% ...

set "HADOOP_FILE=hadoop-%HADOOP_VERSION%.tar.gz"
set "SPARK_FILE=spark-%SPARK_VERSION%-bin-hadoop3.tgz"

set "HADOOP_URL=https://dlcdn.apache.org/hadoop/core/hadoop-%HADOOP_VERSION%/%HADOOP_FILE%"
set "SPARK_URL=https://dlcdn.apache.org/spark/spark-%SPARK_VERSION%/%SPARK_FILE%"

rem Hadoop
if exist "%HADOOP_FILE%" (
    echo [INFO] %HADOOP_FILE% already exists. Skipping.
) else (
    echo.
    echo [DOWNLOADING] %HADOOP_FILE%
    curl --ipv4 -L -o "%HADOOP_FILE%" "%HADOOP_URL%"
)

rem Spark
if exist "%SPARK_FILE%" (
    echo [INFO] %SPARK_FILE% already exists. Skipping.
) else (
    echo.
    echo [DOWNLOADING] %SPARK_FILE%
    curl --ipv4 -L -o "%SPARK_FILE%" "%SPARK_URL%"
)
