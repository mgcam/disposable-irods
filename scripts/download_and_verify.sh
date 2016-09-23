#!/bin/bash

set -e -x

IRODS_VERSION=${IRODS_VERSION:=4.1.9}
PLATFORM=${PLATFORM:=ubuntu12}
ARCH=x86_64

RENCI_FTP_URL=${RENCI_FTP_URL:=ftp://ftp.renci.org}
WTSI_NPG_GITHUB_URL=${WTSI_NPG_GITHUB_URL:=https://github.com/wtsi-npg}

before_install_common() {
    echo sudo apt-get update -qq
}

before_install_3_3_1() {
    wget ${WTSI_NPG_GITHUB_URL}/irods-legacy/releases/download/3.3.1-travis-bc85aa/irods.tar.gz
}

before_install_4_1_x() {
    wget ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-database-plugin-postgres-${PG_PLUGIN_VERSION}-${PLATFORM}-${ARCH}.deb
    wget ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-dev-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
    wget ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-icat-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
    wget ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-icommands-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
    wget ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-runtime-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb

    sha256sum -c ./checksums/packages.sha256
}

case $IRODS_VERSION in

    3.3.1)
        before_install_common
        before_install_3_3_1
        ;;

    4.1.9)
        before_install_common
        before_install_4_1_x
        ;;

    *)
        echo Unknown iRODS version $IRODS_VERSION
        exit 1
esac
