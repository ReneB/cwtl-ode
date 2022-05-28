echo "This script will finalize the setup of the portable CantWaitToLearn Headwind environment"
echo "It will first configure the proper hostname for the server, then encrypt the SD card using the connected hardware key"

_jq() {
    echo ${1} | jq -r "${2}"
}

reconfigure_hostname() {
    read -e -p "(Re-)configure the hostname for this server? (y/n)? " -n 1 -r PERFORM_CONFIG
    if [[ ! "$PERFORM_CONFIG" =~ ^[Yy]$ ]]; then
        return 1
    fi

    read -e -p "Please enter the name of the country this device will be deployed to: " COUNTRY_CODE

    echo "Will set hostname to $COUNTRY_CODE.cantwaittolearn-mdm.com everywhere."

    echo

    TEMPLATES=$(jq -r '.templates | keys[]' hostname-mapping.json)
    for TEMPLATE in $TEMPLATES; do
        TARGET=$(jq -r ".templates[\"$TEMPLATE\"]" hostname-mapping.json)

	BASENAME=$(basename $TARGET)
	echo "* Backing up $TARGET to hostname-backups/$BASENAME"
	cp $TARGET hostname-backups/$BASENAME
        echo "* Setting hostname to $COUNTRY_CODE.cantwaittolearn-mdm.com in $TARGET"
	sed -e "s/REPLACEWITHCOUNTRY/$COUNTRY_CODE/" hostname-file-templates/$TEMPLATE > $TARGET
    done
}

reconfigure_hostname

echo "Done"
