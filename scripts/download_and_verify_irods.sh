#!/bin/bash

set -e -x -o pipefail

BUILD_DIR=${BUILD_DIR:=$PWD}

ARCH=${ARCH:=x86_64}
PLATFORM=${PLATFORM:=ubuntu12}

IRODS_VERSION=${IRODS_VERSION:=4.1.10}
PG_PLUGIN_VERSION=${PG_PLUGIN_VERSION:=1.10}
IRODS_RIP_DIR=${IRODS_RIP_DIR:=/usr/local/irods}

RENCI_FTP_URL=${RENCI_FTP_URL:=https://dnap.cog.sanger.ac.uk}
RENCI_PKG_URL=${RENCI_PKG_URL:=https://packages.irods.org}
WTSI_NPG_GITHUB_URL=${WTSI_NPG_GITHUB_URL:=https://github.com/wtsi-npg}
WTSI_NPG_GITHUB_REPO=${WTSI_NPG_GITHUB_REPO:=irods-legacy-gclp}

before_install_3_3_1() {
    sudo mkdir -p ${IRODS_RIP_DIR}
    sudo chown -R $USER:$USER ${IRODS_RIP_DIR}
    git clone ${WTSI_NPG_GITHUB_URL}/${WTSI_NPG_GITHUB_REPO} ${IRODS_RIP_DIR}
}

before_install_4_1_x() {
    curl -sSL -O ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-database-plugin-postgres-${PG_PLUGIN_VERSION}-${PLATFORM}-${ARCH}.deb
    curl -sSL -O ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-dev-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
    curl -sSL -O ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-icat-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb
    curl -sSL -O ${RENCI_FTP_URL}/pub/irods/releases/${IRODS_VERSION}/${PLATFORM}/irods-runtime-${IRODS_VERSION}-${PLATFORM}-${ARCH}.deb

    sha256sum -c ${BUILD_DIR}/checksums/packages-${IRODS_VERSION}.sha256
}

before_install_4_2_x() {
    curl -sSL -O ${RENCI_PKG_URL}/irods-signing-key.asc
    if [ $(grep -c 'BEGIN PGP PUBLIC KEY BLOCK' irods-signing-key.asc) != 1 ];
    then
        echo 'More than one GPG key in irods-signing-key.asc'
        exit 1
    fi

    sudo apt-key add irods-signing-key.asc
    echo "deb [arch=amd64] ${RENCI_PKG_URL}/apt/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/renci-irods.list
    sudo apt-get update
}

case $IRODS_VERSION in

    3.3.1)
        before_install_3_3_1
        ;;

    4.1.*)
        before_install_4_1_x
        ;;

    4.2.*)
        before_install_4_2_x
        ;;
    *)
        echo Unknown iRODS version $IRODS_VERSION
        exit 1
esac
