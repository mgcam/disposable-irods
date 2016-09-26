#!/bin/bash

set -e -x

IRODS_VERSION=${IRODS_VERSION:=4.1.9}

PGHOME=${PGHOME:=/usr/lib/postgresql}
PGVERSION=${PGVERSION:=9.3}

install_common() {
    sudo apt-get install -qq odbc-postgresql unixodbc-dev
}

install_3_3_1() {
    cp ./config/odbc.ini $HOME/.odbc.ini

    postgres_home=${PGHOME}/${PGVERSION}
    vault_path=$PWD/irods-legacy/iRODS/Vault
    mkdir -p $vault_path

    sed -i.bak -e "s#__POSTGRES_HOME__#$postgres_home#" ./config/irodssetup.in
    sed -i.bak -e "s#__VAULT__#$vault_path#" ./config/irodssetup.in
    sed -i.bak -e 's/i386-linux-gnu/x86_64-linux-gnu/' ./irods-legacy/iRODS/scripts/perl/utils_platform.pl

    cd ./irods-legacy/iRODS
    ./irodssetup < ../../config/irodssetup.in
    ./irodsctl stop

    # Rebuild with -fPIC for libRodsAPI.a
    export CFLAGS=-fPIC
    make clean
    make
}

install_4_1_x() {
    sudo apt-get install -qq python-psutil python-requests
    sudo apt-get install -qq python-sphinx
    sudo apt-get install super libjson-perl jq
    sudo -H pip install jsonschema

    sudo dpkg -i irods-icat-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb irods-database-plugin-postgres-${PG_PLUGIN_VERSION}-${PLATFORM}-${ARCH}.deb
    sudo dpkg -i irods-runtime-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb irods-dev-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
}

case $IRODS_VERSION in

    3.3.1)
        install_common
        install_3_3_1
        ;;

    4.1.9)
        install_common
        install_4_1_x
        ;;

    *)
        echo Unknown iRODS version $IRODS_VERSION
        exit 1
esac
