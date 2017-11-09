FROM ubuntu:xenial
MAINTAINER Stuart Horsman <shorsman@cba.com.au>

## shutup debconf
ARG DEBIAN_FRONTEND=noninteractive

## install java and utils
RUN apt-get update && apt-get install -y \
  software-properties-common \
  python-software-properties \
  maven \
  curl \
  wget \
  unzip \
  vim \
  sudo \
  && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections \
  && add-apt-repository -y ppa:webupd8team/java \
  && apt-get update \
  && apt-get install -y oracle-java8-installer \
  && rm -rf /var/lib/apt/lists/* /var/cache/oracle-jdk8-installer

## define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

## Base image doesn't start in root
WORKDIR /

## Add the CDH 5 repository
COPY conf/cloudera.list /etc/apt/sources.list.d/cloudera.list
## Set preference for cloudera packages
COPY conf/cloudera.pref /etc/apt/preferences.d/cloudera.pref

## Add a Repository Key
RUN wget http://archive.cloudera.com/cdh5/ubuntu/xenial/amd64/cdh/archive.key -O archive.key && apt-key add archive.key && \
  apt-get update && apt-get install -y zookeeper-server \
    hadoop-conf-pseudo \
    python2.7 \
    hue \
    kudu \
    impala \
    hue-plugins \
    spark spark-core spark-history-server spark-python

## Copy updated config files
COPY conf/core-site.xml /etc/hadoop/conf/core-site.xml
COPY conf/hdfs-site.xml /etc/hadoop/conf/hdfs-site.xml
COPY conf/mapred-site.xml /etc/hadoop/conf/mapred-site.xml
COPY conf/hadoop-env.sh /etc/hadoop/conf/hadoop-env.sh
COPY conf/yarn-site.xml /etc/hadoop/conf/yarn-site.xml
COPY conf/fair-scheduler.xml /etc/hadoop/conf/fair-scheduler.xml
COPY conf/spark-defaults.conf /etc/spark/conf/spark-defaults.conf

## Format HDFS
RUN sudo -u hdfs hdfs namenode -format

COPY conf/run-hadoop.sh /usr/bin/run-hadoop.sh
RUN chmod +x /usr/bin/run-hadoop.sh

## NameNode (HDFS)
EXPOSE 8020 50070

## DataNode (HDFS)
EXPOSE 50010 50020 50075

## ResourceManager (YARN)
EXPOSE 8030 8031 8032 8033 8088

## NodeManager (YARN)
EXPOSE 8040 8042

## JobHistoryServer
EXPOSE 10020 19888

## Hue
EXPOSE 8888

## Spark history server
EXPOSE 18080

## Technical port which can be used for your custom purpose.
EXPOSE 9999

## add tini
ENV TINI_VERSION v0.16.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

## define default command
ENTRYPOINT ["/tini", "--"]
CMD ["/usr/bin/run-hadoop.sh"]
