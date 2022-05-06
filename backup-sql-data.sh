#!/bin/bash
#
# Data backup and upload script for CantWaitToLearn Headwind MDM

export SRC_DIR=$(dirname "$0")

getConfig () {
    echo $(ruby $SRC_DIR/get-config.rb "data-backup-config.json" $1 $ENVIRONMENT)
}

SANDBOX_ENVIRONMENT="sandbox"

if [ -n $1 ] && [ "$1" = "production" ]
then
	ENVIRONMENT=$1
else
	ENVIRONMENT=$SANDBOX_ENVIRONMENT
fi

SYNC_ACCOUNT=$(getConfig "syncAccount")
SYNC_DIR=$(getConfig "syncDir")

DOMAIN=$(getConfig "domain")

MARKER_FILE=$SRC_DIR/$SYNC_DIR/$(getConfig "markerFile")
PREVIOUS_TIMESTAMP=$(if [ -f $MARKER_FILE ]; then echo "$(cat $MARKER_FILE)"; else echo "0"; fi)

if [ ! -d $SRC_DIR/$SYNC_DIR ]; then
    mkdir -p $SRC_DIR/$SYNC_DIR
fi

DATABASE_CONNECTION_STRING=$(getConfig "dbConnectionString")
COUNTRY_NAME=$(cat /etc/hosts | grep cantwaittolearn-mdm | sed -e "s/.* //" | sed -e "s/\..*//")
TIMESTAMP=$(date +"%y%m%d%H%M")

pg_dump --file=$SRC_DIR/$SYNC_DIR/$COUNTRY_NAME.$TIMESTAMP.sql -d "$DATABASE_CONNECTION_STRING"

echo $(date) > $MARKER_FILE

echo put -r $SRC_DIR/$SYNC_DIR $SYNC_DIR/$COUNTRY_NAME | sftp -i $SRC_DIR/id_downstream_server -b - $SYNC_ACCOUNT@$DOMAIN

rm $SRC_DIR/$SYNC_DIR/*.sql

