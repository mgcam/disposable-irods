#!/bin/bash

set -e -x

BUILD_DIR=${BUILD_DIR:=$PWD}

ARCH=${ARCH:=x86_64}
PLATFORM=${PLATFORM:=ubuntu12}

IRODS_VERSION=${IRODS_VERSION:=4.1.10}
PG_PLUGIN_VERSION=${PG_PLUGIN_VERSION:=1.10}
IRODS_RIP_DIR=${IRODS_RIP_DIR:=/usr/local/irods}

RENCI_FTP_URL=${RENCI_FTP_URL:=ftp://ftp.renci.org}
WTSI_NPG_GITHUB_URL=${WTSI_NPG_GITHUB_URL:=https://github.com/wtsi-npg}
WTSI_NPG_GITHUB_REPO=${WTSI_NPG_GITHUB_REPO:=irods-legacy-gclp}

before_install_common() {
    echo sudo apt-get update -qq
}

before_install_3_3_1() {
    sudo mkdir -p ${IRODS_RIP_DIR}
    sudo chown -R $USER:$USER ${IRODS_RIP_DIR}
    git clone ${WTSI_NPG_GITHUB_URL}/${WTSI_NPG_GITHUB_REPO} ${IRODS_RIP_DIR}
}

before_install_4_x() {
    curl --silent --show-error --remote-name ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-database-plugin-postgres-${PG_PLUGIN_VERSION}-${PLATFORM}-${ARCH}.deb
    curl --silent --show-error --remote-name ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-dev-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
    curl --silent --show-error --remote-name ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-icat-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
    curl --silent --show-error --remote-name ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-runtime-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb

    sha256sum -c ${BUILD_DIR}/checksums/packages-${IRODS_VERSION}.sha256
}

case $IRODS_VERSION in

    3.3.1)
        before_install_common
        before_install_3_3_1
        ;;

    4.1.*)
        before_install_common
        before_install_4_x
        ;;

    *)
        echo Unknown iRODS version $IRODS_VERSION
        exit 1
esac
