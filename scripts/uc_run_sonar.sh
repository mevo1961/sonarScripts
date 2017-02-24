#!/bin/bash

## @fn      usecase_SONAR_RUN_FSMDDAL()
#  @brief   get coverage data from jenkins and run sonar-runner for the targets in $TARGET_LIST
#  @param   <none>
#  @return  <none>
usecase_SONAR_RUN_FSMDDAL() {
    export TARGET_LIST=${TARGET_LIST:-"FSM-r3 FSM-r4 Lionfish"}
    echo TARGET_LIST = ${TARGET_LIST}

    # TODO: make the following paths configurable 
    export CONFIG_DIR=${SONAR_ROOT}/config
    export BUILD_DIR=${WORKSPACE}/build
    export SONAR_DIR=${WORKSPACE}

    mkdir -p ${SONAR_DIR}
    cd ${SONAR_DIR}

    # get sonar files either from sandbox or from production jenkins
    export SERVER=
    if ${SANDBOX} ; then
        SERVER=lfs-sandbox.emea.nsn-net.net
    else
        SERVER=lfs-ci.int.net.nokia.com
    fi

    wget --no-proxy --no-check-certificate https://${SERVER}/userContent/sonar/SCT/buildName.txt
    read -r buildName <buildName.txt
    echo read build name = ${buildName}

    _checkout_ddal_sources ${buildName}

    for target in ${TARGET_LIST}
    do
        run_sonar_single_target ${target} ${buildName}
    done

    return 0
}

## @fn      run_sonar_single_target()
#  @brief   run sonar-runner for a given target
#  @param   {target}    target for the sonar run, either FSM-r3 or FSM-r4
#  @param   {buildName} build name to be copied into the properties file
#  @return  <none>
run_sonar_single_target() {
    local target=${1}
    local buildName=${2}

    # get coverage data and prepare them for sonar execution
    mkdir -p ${SONAR_DIR}/cobertura
    cd ${SONAR_DIR}

    _get_coverage_files_from_jenkins ${target}

    # prepare sonar properties file and run sonar
    _prepare_properties_file ${target} ${buildName}

    # now let the runner run :-)
    /opt/sonar-runner/bin/sonar-runner

    return 0
}

## @fn      _checkout_ddal_sources()
#  @brief   check out the ddal sources from the git repo with given build name
#  @param   {buildName} build name to be used for checkout from repository
#  @return  <none>
_checkout_ddal_sources() {

    local buildName=${1}
    local curDir=$(pwd)

    cd ${BUILD_DIR}
    ./bootstrap
    echo executing checkout command git checkout $buildName 
    git checkout ${buildName}
    ./repo fetch ddal
    mkdir ${WORKSPACE}/src
    mv ${BUILD_DIR}/src/ddal ${WORKSPACE}/src
    rm -rf ${BUILD_DIR}
    cd ${curDir}

    return 0
}

## @fn      _get_coverage_files_from_jenkins ()
#  @brief   retrieve the coverage.xml files and exclusion lists for UT and SCT from jenkins
#  @param   {target} target of the coverage file, either FSM-r3 or FSM-r4
#  @return  <none>
_get_coverage_files_from_jenkins () {
    local target=${1:-FSM-r3}

    for coverageType in UT SCT
    do
        wget --no-proxy --no-check-certificate https://${SERVER}/userContent/sonar/${coverageType}/${target}/coverage.xml.gz
        mv coverage.xml.gz ${coverageType}_${target}_coverage.xml.gz
        _prepare_coverage_xml ${target}  ${coverageType}
    done

    wget --no-proxy --no-check-certificate https://${SERVER}/userContent/sonar/UT/${target}/${target}_exclusions.txt

    return 0
}

## @fn      _prepare_coverage_xml()
#  @brief   modify the coverage xml file for use with sonar runner
#  @param   {target} target of the coverage file, one of FSM-r3, FSM-r4, or Lionfish
#  @param   {coverageType} type of the coverage file, either SCT or UT
#  @return  <none>
_prepare_coverage_xml() {
    local target coverageType covFile
    target=${1:-FSM-r3}
    coverageType=${2:-UT}
    covFile=${coverageType}_${target}_coverage.xml

    if [[ -e ${covFile}.gz ]] ; then
        gunzip -f ${covFile}.gz
    fi

    if [[ -e ${covFile} ]] ; then
        chmod 666 ${covFile}
    fi

    mv ${covFile} ${SONAR_DIR}/cobertura 

    return 0
}

## @fn      _prepare_properties_file()
#  @brief   prepare the project.properties file for current project
#  @param   {target} target of the coverage file, one of FSM-r3, FSM-r4, or Lionfish
#  @param   {buildName} build name to be set as version in the properties file
#  @return  <none>
_prepare_properties_file() {
    local target buildName propfile
    target=${1:-FSM-r3}
    buildName=${2:-noBuildName}
    propfile=${CONFIG_DIR}/sonar-project.properties.git.${target}

    echo copying ${propfile} to $(pwd)/sonar-project.properties
    cp ${propfile} sonar-project.properties

    # set buildname as version in the properties file
    sed -i -e "s/^sonar.projectVersion=.*/sonar.projectVersion=${buildName}/" sonar-project.properties
    echo set project version to ${buildName}

    # append the exclusion list to the properties file
    _append_exclusions_to_sonar_properties ${target}_exclusions.txt sonar-project.properties

    return 0
}

## @fn      _append_exclusions_to_sonar_properties()
#  @brief   append the contents of the exclusion list to the sonar properties file
#  @param   {infile} name of the exclusions file
#  @param   {outfile} name of the properties file
#  @return  <none>
_append_exclusions_to_sonar_properties() {
    local infile outfile new old

    infile=${1:-fsmr3_exclusions.txt}
    outfile=${2:-sonar-project.properties}
    old=/src/
    new=/src/ddal/

    echo "getting exclusion list from $infile and appending it to $outfile ..."
    echo 'sonar.exclusions= \' >> "$outfile"

    cat "$infile" >> "$outfile"

    return 0
}
