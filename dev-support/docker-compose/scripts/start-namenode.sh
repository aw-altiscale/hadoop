#!/bin/bash

if [[ $FORMAT_NAMENODE == true ]]; then
  ${HADOOP_HOME}/bin/hdfs namenode -format
fi

${HADOOP_HOME}/sbin/hadoop-daemon.sh --config /etc/hadoop --script hdfs start namenode
tail -f /dev/null
