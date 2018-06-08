#!/bin/bash

sleep 5
kinit -kt /var/lib/krb5kdc/root.keytab root/resourcemanager.hadoop@HADOOP

${HADOOP_HOME}/sbin/yarn-daemon.sh --config /etc/hadoop start resourcemanager
tail -f /dev/null
