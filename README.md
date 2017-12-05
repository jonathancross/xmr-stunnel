Connect a Monero wallet to a full node via stunnel
==================================================

Taken from: https://monero.stackexchange.com/a/3466/1023

Pretty sure this is not the most easy way to generate these certificates, but here is a script based on [this tutorial](http://pki-tutorial.readthedocs.io/en/latest/advanced/index.html) :

Stunnel configuration file for the server :

    [monerod_server]
    accept = 30000
    connect = < monerod-local-ip >:18081
    sslVersion = TLSv1.2
    verify = 2
    cert = /path/to/certs/green-chain.pem
    key = /path/to/certs/green.no.key
    CAfile = /path/to/ca/tls-ca-chain.pem
    CRLfile = /path/to/crl/tls-ca-chain.crl


Stunnel configuration file for the client :

    [monerod_client]
    client = yes
    accept = 18081
    connect = < external.ip.of.node >:30000
    sslVersion = TLSv1.2
    verify = 3
    cert = /path/to/certs/barney.crt
    key = /path/to/certs/barney.key
    CAfile = /path/to/ca/green-chain.pem

This example requires port `30000` to be open on `external.ip.of.node`, and eventually redirected to the machine hosting stunnel.
