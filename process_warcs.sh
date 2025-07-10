#! /bin/bash

# FIXME: Take a parameter for the WARC(s) to process


# Load AUT in Docker to process WARCS
docker run --rm -it -v /Users/mjsuhonos/docker-aut/warcs:/warcs aut \
	/spark/bin/spark-submit \
	--master local\[10\] \
	--driver-memory 32g \
	--conf spark.driver.maxResultSize=0 \
	--py-files /aut/target/aut.zip --jars /aut/target/aut-1.2.1-SNAPSHOT-fatjar.jar \
	warcs/spark_readerize.py
	# TODO: add input file(s) parameter here

# generate output CSV files
csvcut -c 1,2,3,4 warcs/results/part*.csv > warcs/results/webpages.csv
csvcut -c 1,5,6 warcs/results/part*.csv > warcs/results/content.csv
python3 ./query_annif.py warcs/results/content.csv warcs/results/scores.csv

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# END OF PROCESSING
# 
# Don't forget to save the output files to a safe place!
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Assume a SQLite3 DB exists and wikidata table is populated
#find warcs -name 'webpages.csv' -exec sh -c 'sqlite3 mydb.db -cmd ".mode csv" -cmd ".import \"$0\" webpages"' {} \;
#find warcs -name 'scores.csv' -exec sh -c 'sqlite3 mydb.db -cmd ".mode csv" -cmd ".import \"$0\" scores"' {} \;
# Required for fulltext analysis
#find warcs -name 'content.csv' -exec sh -c 'sqlite3 mydb.db -cmd ".mode csv" -cmd ".import \"$0\" content"' {} \;