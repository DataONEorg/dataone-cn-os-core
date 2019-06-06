#!/bin/sh

rm -rf /etc/ldap/slapd.d/*
slaptest -f /etc/ldap/slapd.conf -F /etc/ldap/slapd.d

chown -R openldap:openldap /etc/ldap/slapd.d

