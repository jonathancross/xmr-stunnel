#!/bin/bash

git clone https://github.com/jonathancross/xmr-stunnel.git && cd xmr-stunnel

COUNTRY="ZA"
STATE="Ponies"
LOCATION="Everywhere"
ORGANIZATION="Monero"
ORGANIZATION_UNIT="Romerito"
ROOT_COMMON_NAME="Romerito ROOT CA"
TLS_CA_COMMON_NAME="Romerito TLS CA"
TLS_SERVER_COMMON_NAME="Monerod TLS Server"
USER_COMMON_NAME="Barney"
DNS="DNS:green.no,DNS:www.green.no"
BASE_URL="http:\/\/green.no"
EMAIL="donate@getmonero.org"
ROOT_CA_END_DATE="20221231235959Z"
TLS_CA_END_DATE="20191231235959Z"

find ./ -type f -exec sed -i "s/NO/$COUNTRY/g" {} \;
find ./ -type f -exec sed -i "s/Green AS/$ORGANIZATION/g" {} \;
find ./ -type f -exec sed -i "s/Green Certificate Authority/$ORGANIZATION_UNIT/g" {} \;
find ./ -type f -exec sed -i "s/Green Root CA/$ROOT_COMMON_NAME/g" {} \;
find ./ -type f -exec sed -i "s/Green TLS CA/$TLS_CA_COMMON_NAME/g" {} \;
find ./ -type f -exec sed -i "s/http:\/\/green\.no/$BASE_URL/g" {} \;
find ./ -type f -exec sed -i "s/sha1/sha256/g" {} \;
find ./ -type f -exec sed -i "s/2048/4096/g" {} \;

# Create ROOT CA
mkdir -p ca/root-ca/private ca/root-ca/db crl certs
chmod 700 ca/root-ca/private  && chmod 700 ca/root-ca/private
cp /dev/null ca/root-ca/db/root-ca.db && cp /dev/null ca/root-ca/db/root-ca.db.attr
echo 01 > ca/root-ca/db/root-ca.crt.srl && echo 01 > ca/root-ca/db/root-ca.crl.srl
openssl req -new -config etc/root-ca.conf -out ca/root-ca.csr -keyout ca/root-ca/private/root-ca.key -nodes \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$ROOT_COMMON_NAME/emailAddress=$EMAIL"
openssl ca -selfsign -batch -config etc/root-ca.conf -in ca/root-ca.csr \
  -out ca/root-ca.crt -extensions root_ca_ext -enddate $ROOT_CA_END_DATE
openssl ca -gencrl -config etc/root-ca.conf -out crl/root-ca.crl

#Create TLS CA
mkdir -p ca/tls-ca/private ca/tls-ca/db crl certs
chmod 700 ca/tls-ca/private
cp /dev/null ca/tls-ca/db/tls-ca.db && cp /dev/null ca/tls-ca/db/tls-ca.db.attr
echo 01 > ca/tls-ca/db/tls-ca.crt.srl && echo 01 > ca/tls-ca/db/tls-ca.crl.srl
openssl req -new -config etc/tls-ca.conf -out ca/tls-ca.csr -keyout ca/tls-ca/private/tls-ca.key -nodes \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$TLS_CA_COMMON_NAME/emailAddress=$EMAIL"
openssl ca -batch -config etc/root-ca.conf -in ca/tls-ca.csr -out ca/tls-ca.crt -extensions signing_ca_ext -enddate $TLS_CA_END_DATE
openssl ca -gencrl -config etc/tls-ca.conf -out crl/tls-ca.crl
cat ca/tls-ca.crt ca/root-ca.crt > ca/tls-ca-chain.pem
cat crl/tls-ca.crl crl/root-ca.crl > crl/tls-ca-chain.crl

#Create TLS server certificate
SAN=$DNS openssl req -new -config etc/server.conf -out certs/green.no.csr -keyout certs/green.no.key -nodes \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$TLS_SERVER_COMMON_NAME/emailAddress=$EMAIL"
openssl ca -batch -config etc/tls-ca.conf -in certs/green.no.csr -out certs/green.no.crt -extensions server_ext
cat certs/green.no.crt ca/tls-ca.crt ca/root-ca.crt> certs/green-chain.pem

# Create TLS client certificate
openssl req -new -config etc/client.conf -out certs/barney.csr -keyout certs/barney.key -nodes \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCATION/O=$ORGANIZATION/OU=$ORGANIZATION_UNIT/CN=$USER_COMMON_NAME/emailAddress=$EMAIL"
openssl ca -batch -config etc/tls-ca.conf -in certs/barney.csr -out certs/barney.crt -policy extern_pol -extensions client_ext
