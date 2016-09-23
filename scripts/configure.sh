#!/bin/bash

set -e -x

IRODS_VERSION=${IRODS_VERSION:=4.1.9}

configure_common() {
    return
}

configure_3_3_1() {
    # The iRODS 3.3.1 setup script has created the irods user, the
    # irods database user and ICAT database already.
    cd ./irods-legacy/iRODS
    ./irodsctl restart
    return
}

configure_4_1_x() {
    sudo -E -u postgres createuser -D -R -S irods
    sudo -E -u postgres createdb -O irods ICAT
    sudo -E -u postgres sh -c "echo \"ALTER USER irods WITH PASSWORD 'irods'\" | psql"

    sudo /var/lib/irods/packaging/setup_irods.sh < ./config/setup_irods.sh.in
    sudo jq -f ./config/server_config.delta /etc/irods/server_config.json > server_config.tmp
    sudo mv server_config.tmp /etc/irods/server_config.json
    sudo /etc/init.d/irods restart

    test_resource=testResc
    test_password=testpass
    test_vault=/var/lib/irods/iRODS/Test

    sudo -E su irods -c "mkdir -p $test_vault"
    sudo -E su irods -c "iadmin mkresc unixfs unixfilesystem `hostname --fqdn`:$test_vault"

    sudo -E su irods -c "iadmin mkresc $test_resource replication"
    sudo -E su irods -c "iadmin addchildtoresc $test_resource unixfs"

    sudo -E su irods -c "iadmin mkuser $USER rodsadmin"
    sudo -E su irods -c "iadmin moduser $USER password $test_password"

    mkdir $HOME/.irods
    sed -e "s#__USER__#$USER#" -e "s#__HOME__#$HOME#" < ./config/irods_environment.json > $HOME/.irods/irods_environment.json
    cat $HOME/.irods/irods_environment.json

    echo $test_password | script -q -c "iinit"
}

case $IRODS_VERSION in

    3.3.1)
        configure_common
        configure_3_3_1
        ;;

    4.1.9)
        configure_common
        configure_4_1_x
        ;;

    *)
        echo Unknown iRODS version $IRODS_VERSION
        exit 1
esac
