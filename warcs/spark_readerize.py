import logging
import cityhash
import datetime
from aut import *
from bs4 import BeautifulSoup
from readability import Document
from pyspark.sql.functions import col, udf
from pyspark.sql.types import StringType
from pyspark.sql import SQLContext
from pyspark import SparkContext, SparkConf

def soupify(raw_html):
    try:
        soup = BeautifulSoup(raw_html, 'lxml') # html5lib works well too, but slower
        return str(soup)
    except Exception as e:
        logging.error(f"Error soupifying content: {e}")
        return raw_html

def extract_readability(clean_html):
    try:
        doc = Document(clean_html)
        return doc.summary()
    except Exception as e:
        logging.error(f"Error extracting content: {e}")
        return clean_html

def get_cityhash_128(url):
    hash_value = cityhash.CityHash128(url)
    return '{:032x}'.format(hash_value) # Convert the 128-bit hash to a hexadecimal string

def current_datetime():
    return datetime.datetime.now().strftime('%y%m%d%H%M%S')

if __name__ == '__main__':
    conf = SparkConf().setAppName("app")
    sc = SparkContext(conf=conf)
    sqlContext = SQLContext(sc)

    # Register the UDFs with Spark
    soupify_udf = udf(soupify, StringType())
    readability_udf = udf(extract_readability, StringType())
    cityhash_udf = udf(get_cityhash_128, StringType())
    datetime_udf = udf(current_datetime)

    warc = WebArchive(sc, sqlContext, "/warcs/CC-NEWS-202501*.gz")

    results = warc.all() \
        .select(cityhash_udf("url").alias("hash"), \
        "crawl_date", "domain", "url", \
        remove_html(readability_udf(soupify_udf(remove_http_header("raw_content")))).alias("reader"), \
        datetime_udf().alias("extract_date")) \
        .filter(detect_language(col("reader")) == "en")

    results.write.csv("/warcs/CC-NEWS-202501")
