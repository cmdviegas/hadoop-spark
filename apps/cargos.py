from pyspark import SparkContext

sc = SparkContext("local", "CargosApp")

cargos_raw_rdd = sc.textFile("hdfs://node-master:9000/user/root/conjunto2.csv")


def map_function(line):
    # dividide a linha em cada ;
    splitted = line.split(';')
    # se não tem cargo, a chave 'SEM CARGO' é atribuída no lugar
    if splitted[1] == '':
        return ('SEM CARGO', splitted[0])
    # retorna cargo e nome do funcionárion
    return (splitted[1].strip(), splitted[0])


# Executa o map no RDD
pairs = cargos_raw_rdd.map(map_function)
# Remove as chaves duplicadas e as tuplas que correspondem ao cabeçalho
distinctTuplesRdd = pairs.distinct() \
                        .subtract(sc.parallelize([('CARGO','NOME'),('-----','----')]))

distinctTuplesRdd.persist

# Ordena o resultado pela chave
result_list = sorted(distinctTuplesRdd.countByKey().items())

#print(result_list)
for count in result_list:
    print(count)