#! /bin/bash

# FIXME: Take a parameter for the WARC(s) to process


# Load AUT in Docker to process WARCS
docker run --rm -it -v /root/docker-aut/warcs:/warcs aut \
	/spark/bin/spark-submit \
	--master local\[60\] \
	--driver-memory 240g \ # 60 cores uses about 150GB at peak
	--conf spark.driver.maxResultSize=0 \
	--py-files /aut/target/aut.zip --jars /aut/target/aut-1.2.1-SNAPSHOT-fatjar.jar \
	warcs/spark_readerize.py
	# TODO: add input file(s) parameter here

# generate output CSV files
csvcut -c 1,2,3,4 warcs/results/part*.csv > warcs/results/webpages.csv
csvcut -c 1,5,6 warcs/results/part*.csv > warcs/results/content.csv

# spawn annif processes
# each process takes about 30GB with u1-broader-e-arch0-en

# cd Annif
poetry run annif run --port 5001 &
poetry run annif run --port 5002 &
poetry run annif run --port 5003 &
poetry run annif run --port 5004 &
poetry run annif run --port 5005 &
poetry run annif run --port 5006 &

python3 ./query_annif.py warcs/results/content.csv warcs/results/scores.csv

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# END OF PROCESSING
# 
# Don't forget to save the output files to a safe place!
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Create SQLite database and schema
sqlite3 mydb.db < QuickDBD-export.sql
sqlite3 mydb.db -cmd ".mode tabs" -cmd ".import vocab.tsv vocab"

# Import webpage and score data
find warcs -name 'webpages.csv' -exec sh -c 'sqlite3 mydb.db -cmd ".mode csv" -cmd ".import \"$0\" webpages"' {} \;
find warcs -name 'scores.csv' -exec sh -c 'sqlite3 mydb.db -cmd ".mode csv" -cmd ".import \"$0\" scores"' {} \;
# Required for fulltext analysis
find warcs -name 'content.csv' -exec sh -c 'sqlite3 mydb.db -cmd ".mode csv" -cmd ".import \"$0\" content"' {} \;