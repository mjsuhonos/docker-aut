#! /bin/bash

# FIXME: Take a parameter for the WARC(s) to process


# Load AUT in Docker to process WARCS
docker run --rm -it -v /root/docker-aut/warcs:/warcs aut \
	/spark/bin/spark-submit \
	--master local\[60\] \ # g-60vcpu-240gb-intel
	--driver-memory 240g \ # 60 cores uses about 150GB at peak (CC-NEWS)
	--conf spark.driver.maxResultSize=0 \
	--py-files /aut/target/aut.zip --jars /aut/target/aut-1.2.1-SNAPSHOT-fatjar.jar \
	warcs/spark_readerize.py
	# TODO: add input file(s) parameter here

# generate output CSV files
# cd warcs/results/
for a in part*.csv; do csvcut -c 1,2,3,4 $a > webpages/$a; done;
for a in part*.csv; do csvcut -c 1,5,6 $a > content/$a; done;

# spawn annif processes
# each process takes about 33GB with u1-broader-e-arch0-en
# 
# TODO: find a way to automate this based on given N processes

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
# cd SQL
sqlite3 mydb.db < QuickDBD-export.sql
sqlite3 mydb.db -cmd ".mode tabs" -cmd ".import vocab.tsv vocab"

# Import webpage and score data
sqlite3 mydb.db -cmd ".mode csv" -cmd ".import webpages.csv webpages"
sqlite3 mydb.db -cmd ".mode csv" -cmd ".import scores.csv scores"

# Required for fulltext analysis
sqlite3 mydb.db -cmd ".mode csv" -cmd ".import content.csv content"