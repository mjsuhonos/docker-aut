# Base Debian Linux based image with OpenJDK and Maven
FROM maven:3-jdk-11

# Metadata
LABEL maintainer="Nick Ruest <ruestn@gmail.com>"
LABEL description="Docker image for the Archives Unleashed Toolkit."
LABEL website="http://archivesunleashed.org/"

## Build variables
#######################
ARG SPARK_VERSION=3.3.1

# Sample resources
RUN git clone https://github.com/archivesunleashed/aut-resources.git

# Archives Unleashed Toolkit
RUN git clone https://github.com/archivesunleashed/aut.git /aut \
    && cd /aut \
    && export JAVA_OPTS=-Xmx512m \
    && mvn clean install

# Spark shell
RUN mkdir /spark \
    && cd /tmp \
    && wget -q "https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.tgz" \
    && tar -xf "/tmp/spark-$SPARK_VERSION-bin-hadoop2.tgz" -C /spark --strip-components=1 \
    && rm "/tmp/spark-$SPARK_VERSION-bin-hadoop2.tgz"

# Install pip
RUN apt-get update && \
    apt-get install -y python3-pip && \
    rm -rf /var/lib/apt/lists/*

# HTML text extraction
RUN pip install readability-lxml
RUN pip install html5lib
RUN pip install lxml
RUN pip install bs4

# Hash for indexing in SQLite
RUN pip install cityhash

CMD /spark/bin/spark-shell --jars /aut/target/aut-1.2.1-SNAPSHOT-fatjar.jar
