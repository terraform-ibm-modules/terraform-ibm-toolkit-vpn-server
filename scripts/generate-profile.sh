PATH=$BIN_DIR:$PATH



ibmcloud config --check-version=false

ibmcloud login -r "${REGION}" -g "${RESOURCE_GROUP}" --apikey "${IBMCLOUD_API_KEY}" || exit 1


VPN_READY=0
while [ $VPN_READY == 0 ]
do
    VPN=$(ibmcloud is vpn-server $VPN_SERVER --output json)
    HEALTH=$(echo $VPN | jq -r ".health_state")
    LIFECYCLE=$(echo $VPN | jq -r ".lifecycle_state")
    
    echo "Waiting for VPN:$VPN_SERVER to become stable.  health_state: $HEALTH, lifecycle_state: $LIFECYCLE"

    if [[ $HEALTH == "ok" && $LIFECYCLE == "stable" ]]
    then
        VPN_READY=1
    else
        sleep 5
    fi
done

echo "VPN $VPN_SERVER ready"

ibmcloud is vpn-server-client-configuration $VPN_SERVER --file $VPN_SERVER.ovpn

echo "Inserting client certificate into vpn profile"


sed -i '' '/#cert client_public_key.crt/a\
<cert>\
</cert>\
 ' $VPN_SERVER.ovpn

sed -i '' '/<cert>/r ./certificates/issued/client1.vpn.ibm.com.crt' $VPN_SERVER.ovpn

sed -i '' '/#key client_private_key.key/a\
<key>\
</key>\
 ' $VPN_SERVER.ovpn

sed -i '' '/<key>/r ./certificates/private/client1.vpn.ibm.com.key' $VPN_SERVER.ovpn

echo "Your OpenVPN client profile has been created, with certificates added, and is available at $(pwd)/$VPN_SERVER.ovpn"