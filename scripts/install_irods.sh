#!/bin/bash

set -e -x

BUILD_DIR=${BUILD_DIR:=$PWD}

ARCH=${ARCH:=x86_64}
PLATFORM=${PLATFORM:=ubuntu12}

IRODS_VERSION=${IRODS_VERSION:=4.1.10}
PG_PLUGIN_VERSION=${PG_PLUGIN_VERSION:=1.10}
IRODS_RIP_DIR=${IRODS_RIP_DIR:=/usr/local/irods}

PGHOME=${PGHOME:=/usr/lib/postgresql}
PGVERSION=${PGVERSION:=9.3}

install_common() {
    sudo apt-get install -q -y postgresql-client odbc-postgresql unixodbc-dev
}

install_3_3_1() {
    cp ${BUILD_DIR}/config/odbc.ini $HOME/.odbc.ini

    postgres_home=${PGHOME}/${PGVERSION}
    vault_path=${IRODS_RIP_DIR}/iRODS/Vault
    mkdir -p $vault_path
    chown -R $USER:$USER $vault_path

    sed -i.bak -e "s#__POSTGRES_HOME__#$postgres_home#" ${BUILD_DIR}/config/irodssetup.in
    sed -i.bak -e "s#__VAULT__#$vault_path#" ${BUILD_DIR}/config/irodssetup.in
    sed -i.bak -e 's/i386-linux-gnu/x86_64-linux-gnu/' ${IRODS_RIP_DIR}/iRODS/scripts/perl/utils_platform.pl

    cd ${IRODS_RIP_DIR}/iRODS
    ./irodssetup < ${BUILD_DIR}/config/irodssetup.in
    ./irodsctl stop

    # Rebuild with -fPIC for libRodsAPI.a
    export CFLAGS=-fPIC
    make clean
    make
}

install_4_x() {
    sudo apt-get install -q -y libssl-dev
    sudo apt-get install -q -y python-pip python-psutil python-requests
    sudo apt-get install -q -y python-sphinx
    sudo apt-get install -q -y super libjson-perl jq
    sudo -H pip install jsonschema

    sudo dpkg -i irods-icat-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb irods-database-plugin-postgres-${PG_PLUGIN_VERSION}-${PLATFORM}-${ARCH}.deb
    sudo dpkg -i irods-runtime-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb irods-dev-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
}

case $IRODS_VERSION in

    3.3.1)
        install_common
        install_3_3_1
        ;;

    4.*)
        install_common
        install_4_x
        ;;

    *)
        echo Unknown iRODS version $IRODS_VERSION
        exit 1
esac
