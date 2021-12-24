#!/bin/bash
# 
# LetsEncrypt renewal script for CantWaitToLearn Headwind MDM
# Modified from the original to allow use of wildcard domains.

export SRC_DIR=$(dirname "$0")

getConfig () {
    echo $(ruby $SRC_DIR/get-config.rb "letsencrypt-config.json" $1 $ENVIRONMENT)
}

SANDBOX_ENVIRONMENT="sandbox"

if [ -n $1 ] && [ "$1" = "production" ]
then 
	ENVIRONMENT=$1
else
	ENVIRONMENT=$SANDBOX_ENVIRONMENT
fi

TOMCAT_HOME=$(ls -d /var/lib/tomcat* | tail -n1)
TOMCAT_USER=$(ls -ld $TOMCAT_HOME/webapps | awk '{print $3}')
TOMCAT_SERVICE=$(echo $TOMCAT_HOME | awk '{n=split($1,A,"/"); print A[n]}')
SSL_DIR=$TOMCAT_HOME/ssl

PASSWORD=$(getConfig "keystorePassword")
SYNC_ACCOUNT=$(getConfig "syncAccount")
SYNC_DIR=$(getConfig "syncDir")

DOMAIN=$(getConfig "domain")

if [ ! -d $SSL_DIR ]; then
    mkdir -p $SSL_DIR
fi

if [ ! -d $SRC_DIR/$SYNC_DIR ]; then
    mkdir -p $SRC_DIR/$SYNC_DIR
fi

sftp -r $SYNC_ACCOUNT@$UPSTREAM_DOMAIN:$SYNC_DIR/* $SRC_DIR/$SYNC_DIR


cp $SRC_DIR/$SYNC_DIR/$DOMAIN.jks $SSL_DIR

chown -R $TOMCAT_USER:$TOMCAT_USER $SSL_DIR

# This line is required when you refresh the certificates because Tomcat needs
# to be restarted to load a new certificate.
# Here we assume the service has the same name as the Tomcat directory
# (e.g. tomcat9)
/usr/sbin/service $TOMCAT_SERVICE restart

