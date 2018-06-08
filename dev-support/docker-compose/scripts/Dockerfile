FROM maven:3.5.2-jdk-8

ARG HADOOP_VERSION

ENV HADOOP_SRC_PATH=/opt/hadoop-src
ENV HADOOP_LOG_DIR=/var/log/hadoop/logs
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/etc/hadoop
ENV HADOOP_NAMENODE_OPTS='-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=1049'
ENV HADOOP_DATANODE_OPTS='-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=1050'
ENV HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib:$HADOOP_HOME/lib/native"
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HADOOP_HOME/lib/native/:/usr/local/lib

RUN mkdir -p /var/log/hadoop $HADOOP_SRC_PATH $HADOOP_HOME $HADOOP_CONF_DIR

# we don't want openjdk-7, only 8
RUN apt remove -y openjdk-7-jdk openjdk-7-jre openjdk-7-jre-headless
ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle

RUN apt-get -q update && \
    apt-get -q install -y \
        ant \
        build-essential \
        cmake \
        libssl-dev \
        pkg-config \
        vim \
        zlib1g-dev \
        ntp \
        krb5-kdc \
        net-tools \
        sudo

# we get protobuf from the parent
#RUN cd /tmp && \
#    curl -OL https://github.com/google/protobuf/releases/download/v2.5.0/protobuf-2.5.0.zip && \
#    unzip protobuf-2.5.0.zip && \
#    cd protobuf-2.5.0 && \
#    ./configure && \
#    make && \
#    make check && \
#    make install

RUN groupadd -f supergroup && \
    groupadd -f yarn && \
    useradd -ms /bin/bash hdfs -g supergroup && \
    useradd -ms /bin/bash yarn -g supergroup && \
    useradd -ms /bin/bash hive -g supergroup && \
    useradd -ms /bin/bash spark -g supergroup && \
    echo "hdfs  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "yarn  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "hive  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "spark ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY dev-support/docker-compose/kerberos/conf/kdc.conf /etc/krb5kdc/kdc.conf
COPY dev-support/docker-compose/kerberos/conf/kadm5.acl /etc/krb5kdc/kadm5.acl
COPY dev-support/docker-compose/kerberos/conf/krb5.conf /etc/krb5.conf
COPY hadoop-dist/target/hadoop-$HADOOP_VERSION.tar.gz /root/hadoop.tar.gz
RUN  tar -xvzp  -C $HADOOP_HOME --strip-components 1 \
        -f /root/hadoop.tar.gz

ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
WORKDIR /root
