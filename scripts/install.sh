#!/bin/bash

set -e -x

IRODS_VERSION=${IRODS_VERSION:=4.1.9}
IRODS_RIP_DIR=/opt/renci/irods-3.3.1

install_common() {
    sudo apt-get install -qq odbc-postgresql unixodbc-dev
}

install_3_3_1() {
    mkdir -p ${IRODS_RIP_DIR}
    cd ${IRODS_RIP_DIR}
    tar xfz /tmp/irods-3.3.1.tar.gz
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
