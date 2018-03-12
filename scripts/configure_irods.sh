#!/bin/bash

set -e -x

BUILD_DIR=${BUILD_DIR:=$PWD}

IRODS_VERSION=${IRODS_VERSION:=4.1.10}
IRODS_RIP_DIR=${IRODS_RIP_DIR:=/usr/local/irods}

configure_common() {
    return
}

configure_3_3_1() {
    # The iRODS 3.3.1 setup script has created the irods user, the
    # irods database user and ICAT database already.
    cd ${IRODS_RIP_DIR}/iRODS
    ./irodsctl restart

    export PATH=${IRODS_RIP_DIR}/iRODS/clients/icommands/bin:$PATH

    test_resource=testResc
    test_vault=${IRODS_RIP_DIR}/iRODS/TestVault

    sudo mkdir -p $test_vault
    sudo chown -R $USER:$USER $test_vault

    iadmin mkresc testResc 'unix file system' cache `hostname --fqdn` $test_vault
    iadmin asq 'select alias,sqlStr from R_SPECIFIC_QUERY where alias = ?' findQueryByAlias
}

configure_postgres_4_x_x() {
    sudo -E -u postgres createuser -D -R -S irods
    sudo -E -u postgres createdb -O irods ICAT
    sudo -E -u postgres sh -c "echo \"ALTER USER irods WITH PASSWORD 'irods'\" | psql"
}

configure_checksum_4_x_x() {
    sudo jq -f ${BUILD_DIR}/config/server_config.delta /etc/irods/server_config.json > server_config.tmp
    sudo mv server_config.tmp /etc/irods/server_config.json
    sudo /etc/init.d/irods restart
}

configure_resources_4_x_x() {
    test_resource=testResc
    test_vault=/var/lib/irods/iRODS/TestVault
    test_password=testpass

    sudo -E su irods -c "mkdir -p $test_vault"
    sudo -E su irods -c "iadmin mkresc unixfs unixfilesystem `hostname --fqdn`:$test_vault"

    sudo -E su irods -c "iadmin mkresc $test_resource replication"
    sudo -E su irods -c "iadmin addchildtoresc $test_resource unixfs"

    sudo -E su irods -c "iadmin mkuser $USER rodsadmin"
    sudo -E su irods -c "iadmin moduser $USER password $test_password"
}

configure_login_4_x_x() {
    mkdir $HOME/.irods
    sed -e "s#__USER__#$USER#" -e "s#__HOME__#$HOME#" < ${BUILD_DIR}/config/irods_environment.json > $HOME/.irods/irods_environment.json
    cat $HOME/.irods/irods_environment.json

    echo $test_password | script -q -c "iinit" /dev/null
}

configure_4_1_x() {
    configure_postgres_4_x_x

    sudo /var/lib/irods/packaging/setup_irods.sh < ${BUILD_DIR}/config/setup_irods.sh.in

    configure_checksum_4_x_x
    configure_resources_4_x_x
    configure_login_4_x_x
}

configure_4_2_x() {
    configure_postgres_4_x_x

    sudo python /var/lib/irods/scripts/setup_irods.py < ${BUILD_DIR}/config/setup_irods.py.in

    configure_checksum_4_x_x
    configure_resources_4_x_x
    configure_login_4_x_x
}

case $IRODS_VERSION in

    3.3.1)
        configure_common
        configure_3_3_1
        ;;

    4.1.*)
        configure_common
        configure_4_1_x
        ;;

    4.2.*)
        configure_common
        configure_4_2_x
        ;;

    *)
        echo Unknown iRODS version $IRODS_VERSION
        exit 1
esac
