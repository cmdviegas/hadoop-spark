from pyspark import SparkContext

import pyspark
from pyspark.sql import SparkSession

spark = SparkSession.builder \
                            .master("local") \
                            .appName("Onibus App") \
                            .config("spark.some.config.option", "some-value") \
                            .getOrCreate()

linhas_ds = spark.read.option("multiline", "true").json(
    "hdfs://node-master:9000/user/root/onibus/2018_04_21_linhas.json")
tabela_linhas_ds = spark.read.option("multiline", "true").json(
    "hdfs://node-master:9000/user/root/onibus/2018_04_21_tabelaLinha.json")
trechos_ds = spark.read.option("multiline", "true").json(
    "hdfs://node-master:9000/user/root/onibus/2018_04_21_trechosItinerarios.json"
)

joined = linhas_ds.join(tabela_linhas_ds,
                        linhas_ds.COD == tabela_linhas_ds.COD)

joined_rdd = joined.rdd


def map_func(line):
    return {
        "num_linha": line.COD,
        "nome": line.NOME,
        "hora": line.HORA,
        "ponto": line.PONTO
    }


def red_func(x, y):
    if x["num_linha"] == y["num_linha"]:
        return {"num_linha": x["num_linha"]}
    return x


mapped = joined_rdd.map(map_func)

mapped.persist


def map2(line):
    return {"ponto": line["ponto"], "horario": line["hora"]}


num_linha = input("Insira o numero da linha: ")

print("linha escolhida: ", num_linha)

resultado = mapped.filter(lambda x: x["num_linha"] == str(num_linha)).map(
    map2).collect()

print("fim do filter")

if (len(resultado) == 0):
    print("linha nao encontrada")
else:
    print("linha 340: ")
    for entry in resultado:
        print(entry)
