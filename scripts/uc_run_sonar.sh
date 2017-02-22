#!/bin/bash

source ${WORKSPACE}/sonar/scripts/prepare_UT_coverage.sh
source ${WORKSPACE}/sonar/scripts/prepare_SCT_coverage.sh
source ${WORKSPACE}/sonar/scripts/append_exclusions_to_sonar_properties.sh

## @fn      usecase_SONAR_RUN_FSMDDAL()
#  @brief   run sonar-runner on for the targets in $TARGET_LIST
#  @param   <none>
#  @return  <none>
usecase_SONAR_RUN_FSMDDAL() {
    export TARGET_LIST=${TARGET_LIST:-"FSM-r3 FSM-r4 Lionfish"}
    echo TARGET_LIST = ${TARGET_LIST}

    # TODO: make the following paths configurable 
    if $GIT ; then
        export DDAL_PATH=${WORKSPACE}/sonar/build
    else
        export DDAL_PATH=${WORKSPACE}/sonar/src-fsmddal
    fi

    if ${SANDBOX} ; then
        server=lfs-sandbox.emea.nsn-net.net
    else
        server=lfs-ci.int.net.nokia.com
    fi

    wget --no-proxy --no-check-certificate https://${server}/userContent/sonar/SCT/buildName.txt
    read -r buildName <buildName.txt
    echo read build name = ${buildName}

    cd ${DDAL_PATH}
    checkout_ddal_sources ${buildName}

    export CONFIG_PATH=${WORKSPACE}/sonar/config

    rm -rf ${DDAL_PATH}/cobertura
    mkdir -p ${DDAL_PATH}/cobertura
    for target in ${TARGET_LIST}
    do
        run_sonar_single_target ${target} ${buildName}
    done

    return 0
}

## @fn      run_sonar_single_target()
#  @brief   run sonar-runner on the current directory
#  @param   {target}    target for the sonar run, either FSM-r3 or FSM-r4
#  @param   {buildName} build name to be copied into the properties file
#  @return  <none>
run_sonar_single_target() {
    local target=${1}
    local buildName=${2}
    echo target = ${target}
    echo SANDBOX = ${SANDBOX:-false}

    # get coverage data and prepare them for sonar execution
    cd ${DDAL_PATH}/cobertura
    local server=

    if ${SANDBOX} ; then
        server=lfs-sandbox.emea.nsn-net.net
    else
        server=lfs-ci.int.net.nokia.com
    fi
    wget --no-proxy --no-check-certificate https://${server}/userContent/sonar/UT/${target}/coverage.xml.gz
    mv coverage.xml.gz UT_${target}_coverage.xml.gz
    echo now calling _prepare_UT_coverage
    _prepare_UT_coverage ${target}

    wget --no-proxy --no-check-certificate https://${server}/userContent/sonar/SCT/${target}/coverage.xml.gz
    mv coverage.xml.gz SCT_${target}_coverage.xml.gz
    _prepare_SCT_coverage ${target}

    # prepare sonar properties file and run sonar
    cd ${DDAL_PATH}
    local propfile=
    if $GIT ; then
        propfile=${CONFIG_PATH}/sonar-project.properties.git.${target}
    else
        propfile=${CONFIG_PATH}/sonar-project.properties.${target}
    fi
    cp ${propfile} sonar-project.properties
    sed -i -e "s/^sonar.projectVersion=.*/sonar.projectVersion=${buildName}/" sonar-project.properties
    echo set project version to ${buildName} 
    # get the exclusion list and append it to the properties file
    rm -f ${target}_exclusions.txt*
    wget --no-check-certificate https://${server}/userContent/sonar/UT/${target}/${target}_exclusions.txt -e use_proxy=no
    _append_exclusions_to_sonar_properties ${target}_exclusions.txt sonar-project.properties

    # now let the runner run :-)
    /opt/sonar-runner/bin/sonar-runner

    return 0
}

## @fn      checkout_ddal_sources()
#  @brief   check out the ddal sources from the git repo with given build name
#  @param   {buildName} build name to be used for checkout from repository
#  @return  <none>
checkout_ddal_sources() {

    local buildName=${1}
    cd ${WORKSPACE}/sonar/build
    ./bootstrap
    echo executing checkout command git checkout $buildName 
    git checkout ${buildName}
    ./repo fetch ddal

    return 0
}

