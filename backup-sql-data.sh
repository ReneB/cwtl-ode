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

MARKER_FILE=$SRC_DIR/$SYNC_DIR/$(getConfig "markerFile")
echo $(date) > $MARKER_FILE

if [ ! -d $SRC_DIR/$SYNC_DIR ]; then
    mkdir -p $SRC_DIR/$SYNC_DIR
fi

DATABASE_CONNECTION_STRING=$(getConfig "dbConnectionString")
COUNTRY_NAME=$(cat /etc/hosts | grep cantwaittolearn-mdm | sed -e "s/.* //" | sed -e "s/\..*//")
TIMESTAMP=$(date +"%y%m%d%H%M")

pg_dump --file=$SRC_DIR/$SYNC_DIR/$COUNTRY_NAME.$TIMESTAMP.sql -d "$DATABASE_CONNECTION_STRING"

SUCCESS_FILE=$SRC_DIR/$SYNC_DIR/$(getConfig "successFile")
echo $(date) > $SUCCESS_FILE

DOMAIN=$(getConfig "domain")

ssh -i $SRC_DIR/id_downstream_server $SYNC_ACCOUNT@$DOMAIN "mkdir -p ~/$SYNC_DIR/$COUNTRY_NAME"
scp -r -i $SRC_DIR/id_downstream_server $SRC_DIR/$SYNC_DIR/* $SYNC_ACCOUNT@$DOMAIN:$SYNC_DIR/$COUNTRY_NAME

rm $SRC_DIR/$SYNC_DIR/*.sql

