FROM anapsix/alpine-java:8u121b13_server-jre

MAINTAINER Adam Harper <docker@adam-harper.com>

# Install Kafka from official binary releases
ENV APACHE_MIRROR http://mirror.ox.ac.uk/sites/rsync.apache.org
ENV KAFKA_SCALA 2.12
ENV KAFKA_VERSION 0.10.2.0

RUN cd /tmp \
 # download and extract kafka binaries
 && wget -q $APACHE_MIRROR/kafka/$KAFKA_VERSION/kafka_$KAFKA_SCALA-$KAFKA_VERSION.tgz \
 && mkdir -p /opt \
 && tar xfz /tmp/kafka_$KAFKA_SCALA-$KAFKA_VERSION.tgz -C /opt \
 && rm /tmp/*.tgz \
 && ln -s /opt/kafka_$KAFKA_SCALA-$KAFKA_VERSION /opt/kafka \
 # create data directory
 && mkdir -p /data

# copy configuration files
COPY etc/server.properties /opt/kafka/config/
COPY etc/log4j.properties /opt/kafka/config/

# expose kafka and JMX
EXPOSE 9092 7000

ENV SERVICE_9092_NAME kafka
ENV SERVICE_7000_NAME jmx

# expose mount point for service data
VOLUME /data

# set default log location
ENV LOG_DIR /var/log/kafka

# keep some GC logs, but rotate them
ENV KAFKA_GC_LOG_OPTS -Xloggc:/var/log/kafka/kafkaServer-gc.log -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M

# setup runtime environment
COPY bin/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*
CMD ["/usr/local/bin/start", "", ""]
