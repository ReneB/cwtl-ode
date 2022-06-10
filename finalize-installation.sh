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

    read -e -p "Please enter the name of the country this device will be deployed to: " COUNTRY_NAME

    echo "Will set hostname to $COUNTRY_NAME.cantwaittolearn-mdm.com everywhere."

    echo

    TEMPLATES=$(jq -r '.templates | keys[]' hostname-mapping.json)
    for TEMPLATE in $TEMPLATES; do
        TARGET=$(jq -r ".templates[\"$TEMPLATE\"]" hostname-mapping.json)

        BASENAME=$(basename $TARGET)
        echo "* Backing up $TARGET to hostname-backups/$BASENAME"
        #cp $TARGET hostname-backups/$BASENAME
        echo "* Setting hostname to $COUNTRY_NAME.cantwaittolearn-mdm.com in $TARGET"
        #sed -e "s/REPLACEWITHCOUNTRY/$COUNTRY_NAME/" hostname-file-templates/$TEMPLATE > $TARGET
    done

    COUNTRY_UPPER_CASE=$(echo "${COUNTRY_NAME^^}")
    case $COUNTRY_UPPER_CASE in
        UGANDA)
            COUNTRY_CODE="UG"
            ;;
        LEBANON)
            COUNTRY_CODE="LB"
            ;;
        CHAD)
            COUNTRY_CODE="TD"
            ;;
        UKRAINE)
            COUNTRY_CODE="UA"
            ;;
        SUDAN)
            COUNTRY_CODE="SD"
            ;;
        JORDAN)
            COUNTRY_CODE="JO"
            ;;
        "THE NETHERLANDS")
            COUNTRY_CODE="NL"
            ;;
        *)
            read -e -p "Please enter the 2-letter country code for ${COUNTRY_NAME} (needed for WiFi configuration regulation)" COUNTRY_CODE
            ;;
    esac

    echo "Setting WiFi Country Config to ${COUNTRY_CODE}..."
    iw reg set $COUNTRY_CODE
    raspi-config nonint do_wifi_country $COUNTRY_CODE
}

reconfigure_hostname

echo "Done"
