

echo "Cloning easy-rsa"
rm -rf easy-rsa
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3
#pwd
#ls -la


echo "Creating PKI and CA"
export EASYRSA_BATCH=1
./easyrsa init-pki
./easyrsa build-ca nopass
if [ ! -f "pki/ca.crt" ]
then
    echo "pki/ca.crt could not be found."
    exit 1
fi


echo "Generating VPN server certificate"
./easyrsa build-server-full vpn-server.vpn.ibm.com nopass

if [ ! -f "pki/issued/vpn-server.vpn.ibm.com.crt" ]
then
    echo "pki/issued/vpn-server.vpn.ibm.com.crt could not be found."
    exit 1
fi

if [ ! -f "pki/private/vpn-server.vpn.ibm.com.key" ]
then
    echo "pki/private/vpn-server.vpn.ibm.com.key could not be found."
    exit 1
fi


echo "Generating VPN client certificate"
./easyrsa build-client-full client1.vpn.ibm.com nopass

if [ ! -f "pki/issued/client1.vpn.ibm.com.crt" ]
then
    echo "pki/issued/client1.vpn.ibm.com.crt could not be found."
    exit 1
fi

if [ ! -f "pki/private/client1.vpn.ibm.com.key" ]
then
    echo "pki/private/client1.vpn.ibm.com.key could not be found."
    exit 1
fi

pwd
mkdir ../../certificates
mv pki/* ../../certificates
cd ../../certificates
echo "ca: \"$(pwd)/ca.crt\"" > output.yaml
echo "server-cert: \"$(pwd)/issued/vpn-server.vpn.ibm.com.crt\"" >> output.yaml
echo "server-key: \"$(pwd)/private/vpn-server.vpn.ibm.com.key\"" >> output.yaml
echo "client-cert: \"$(pwd)/issued/client1.vpn.ibm.com.crt\"" >> output.yaml
echo "client-key: \"$(pwd)/private/client1.vpn.ibm.com.key\"" >> output.yaml

echo "Complete:"
cat output.yaml


cd ../..
rm -rf easy-rsa