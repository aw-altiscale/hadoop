#!/bin/bash

sleep 5
kinit -kt /var/lib/krb5kdc/root.keytab root/nodemanager1.hadoop@HADOOP

${HADOOP_HOME}/sbin/yarn-daemon.sh --config /etc/hadoop start nodemanager
tail -f /dev/null
