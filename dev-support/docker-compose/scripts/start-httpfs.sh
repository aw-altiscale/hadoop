#!/bin/bash

sleep 5
${HADOOP_HOME}/sbin/httpfs.sh start
tail -f /dev/null
