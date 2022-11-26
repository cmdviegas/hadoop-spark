from pyspark import SparkContext

sc = SparkContext("local", "SimpleApp")
logData = sc.textFile("hdfs://node-master:9000/user/root/README.md")
numAs = logData.filter(lambda s: 'c' in s).count()
numBs = logData.filter(lambda s: 'd' in s).count()

print("\n\nLines with c: %i, lines with d: %i\n" % (numAs, numBs))