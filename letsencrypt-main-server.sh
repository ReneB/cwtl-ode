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
	SUFFIX=""
else
	ENVIRONMENT=$SANDBOX_ENVIRONMENT
	SUFFIX="--dry-run --test-cert"
fi

TOMCAT_HOME=$(ls -d /var/lib/tomcat* | tail -n1)
TOMCAT_USER=$(ls -ld $TOMCAT_HOME/webapps | awk '{print $3}')
TOMCAT_SERVICE=$(echo $TOMCAT_HOME | awk '{n=split($1,A,"/"); print A[n]}')
SSL_DIR=$TOMCAT_HOME/ssl

PASSWORD=$(getConfig "keystorePassword")
MAILADDRESS=$(getConfig "mailAddress")
TARGET_ACCOUNT=$(getConfig "syncAccount")
SYNC_DIR=$(getConfig "syncDir")
MARKER_FILE=$(getConfig "markerFile")

DOMAIN=$(getConfig "domain")
WILDCARD_DOMAIN="*.$DOMAIN"

CERTBOT_DIR=/etc/letsencrypt/live/$DOMAIN

certbot certonly --manual-auth-hook=$SRC_DIR/letsencrypt-namecheap-dns-auth.production.sh -n --manual -d $WILDCARD_DOMAIN --manual-public-ip-logging-ok -m $MAILADDRESS --force-renewal --agree-tos $SUFFIX

if [ ! -d $SSL_DIR ]; then
    mkdir -p $SSL_DIR
fi

# TODO: here we should check that certbot actually renewed the certificate!

openssl pkcs12 -export -out $SSL_DIR/$DOMAIN.p12 -inkey $CERTBOT_DIR/privkey.pem -in $CERTBOT_DIR/cert.pem -certfile $CERTBOT_DIR/fullchain.pem -password pass:$PASSWORD

keytool -importkeystore -destkeystore $SSL_DIR/$DOMAIN.jks -srckeystore $SSL_DIR/$DOMAIN.p12 -srcstoretype PKCS12 -srcstorepass $PASSWORD -deststorepass $PASSWORD -noprompt

chown -R $TOMCAT_USER:$TOMCAT_USER $SSL_DIR

# This line is required when you refresh the certificates because Tomcat needs
# to be restarted to load a new certificate.
# Here we assume the service has the same name as the Tomcat directory
# (e.g. tomcat9)
/usr/sbin/service $TOMCAT_SERVICE restart

# Now prepare the keystore for being downloaded by downstream servers

mkdir -p /home/$TARGET_ACCOUNT/$SYNC_DIR

cp $SSL_DIR/$DOMAIN.jks /home/$TARGET_ACCOUNT/$SYNC_DIR
echo $(date) > /home/$TARGET_ACCOUNT/$SYNC_DIR/$MARKER_FILE

chown -R $TARGET_ACCOUNT:$TARGET_ACCOUNT /home/$TARGET_ACCOUNT/$SYNC_DIR
