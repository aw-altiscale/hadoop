FROM hadoop:2.7.4

COPY kerberos/conf/kdc.conf /etc/krb5kdc/kdc.conf
COPY kerberos/conf/kadm5.acl /etc/krb5kdc/kadm5.acl
COPY kerberos/conf/krb5.conf /etc/krb5.conf
COPY kerberos/kerberos.sh /etc/krb5kdc/kerberos.sh

RUN apt-get -q update && apt-get -q install -y krb5-admin-server
RUN ln -s /var/lib/krb5kdc/stash /etc/krb5kdc/stash

CMD "/etc/krb5kdc/kerberos.sh"
