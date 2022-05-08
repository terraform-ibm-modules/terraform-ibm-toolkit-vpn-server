#!/usr/bin/env bash

export PATH=$BIN_DIR:$PATH

if ! command -v git 1> /dev/null 2> /dev/null; then
  echo "git cli not found" >&2
  exit 1
fi

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
cd ../..
rm -rf certificates
mkdir certificates
mv easy-rsa/easyrsa3/pki/* certificates

# pwd
# ls -lRa certificates

echo "vpn:" > output.yaml
echo "  ca: \"$(pwd)/certificates/ca.crt\"" >> output.yaml
echo "  server-cert: \"$(pwd)/certificates/issued/vpn-server.vpn.ibm.com.crt\"" >> output.yaml
echo "  server-key: \"$(pwd)/certificates/private/vpn-server.vpn.ibm.com.key\"" >> output.yaml
echo "  client-cert: \"$(pwd)/certificates/issued/client1.vpn.ibm.com.crt\"" >> output.yaml
echo "  client-key: \"$(pwd)/certificates/private/client1.vpn.ibm.com.key\"" >> output.yaml

echo "Complete:"
cat output.yaml

rm -rf easy-rsa
