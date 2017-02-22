#!/bin/bash

# this script creates hmtl dirs for normal and blacklisted coverage
# The directories 'html' and 'html_blacklisted' will be created
# A link to a build directory must be passed as parameter where 'src/ddal' can be found

_getLcovFilesFromJenkins() {
    wget --no-proxy --no-check-certificate https://lfs-ci.int.net.nokia.com/job/LFS_CI_-_master_-_CoverageTest_-_FSM-r3_-_FSMF/ws/workspace/bld/bld-test-artifacts/results/lcov.LFS_CI_-_master_-_CoverageTest_-_FSM-r3_-_FSMF.out
    wget --no-proxy --no-check-certificate https://lfs-ci.int.net.nokia.com/job/LFS_CI_-_master_-_CoverageTest_-_FSM-r3_-_FSIH/ws/workspace/bld/bld-test-artifacts/results/lcov.LFS_CI_-_master_-_CoverageTest_-_FSM-r3_-_FSIH.out
    wget --no-proxy --no-check-certificate https://lfs-ci.int.net.nokia.com/job/LFS_CI_-_master_-_CoverageTest_-_FSM-r4_-_FCTJ/ws/workspace/bld/bld-test-artifacts/results/lcov.LFS_CI_-_master_-_CoverageTest_-_FSM-r4_-_FCTJ.out
    lcov -a lcov.LFS_CI_-_master_-_CoverageTest_-_FSM-r3_-_FSMF.out -a lcov.LFS_CI_-_master_-_CoverageTest_-_FSM-r3_-_FSIH.out -o FSM-r3.lcov
    lcov -a lcov.LFS_CI_-_master_-_CoverageTest_-_FSM-r4_-_FCTJ.out                                                            -o FSM-r4.lcov
    sed -i -e 's,^SF:.*src-fsmddal,SF:ddal,' FSM-r3.lcov
    sed -i -e 's,^SF:.*src-fsmddal,SF:ddal,' FSM-r4.lcov
}

_getExclusionListsFromJenkins () {
    wget --no-proxy --no-check-certificate https://lfs-ci.int.net.nokia.com/userContent/sonar/UT/FSM-r3/FSM-r3_exclusions.txt
    wget --no-proxy --no-check-certificate https://lfs-ci.int.net.nokia.com/userContent/sonar/UT/FSM-r4/FSM-r4_exclusions.txt
}

_createLcovPattern() {
    target=${1}

    sed -i -e 's:^**/ddal:ddal:' -e 's: ,\\::' -e 's:\*\*:\*:' ${target}_exclusions.txt
    pattern=
    while read -r line
    do
        pattern="${pattern} ${line}"
    done < ./${target}_exclusions.txt

    echo ${pattern}
}

_createBlacklistedLcovFiles() {
    for target in FSM-r3 FSM-r4 
    do
       pattern=$(_createLcovPattern ${target}) 
       echo lcov pattern = ${pattern}
       lcov -r ${target}.lcov ${pattern} -o ${target}_blacklisted.lcov  
    done
}

_createHtml() {
    local buildDir=${1}
    for target in FSM-r3 FSM-r4
    do
        mkdir -p html/${target}
        mv ${target}.lcov html/${target}
        echo "now copying ${buildDir}/src/ddal to html/${target}"
        cp -R ${buildDir}/src/ddal html/${target}
        cd html/${target}
        genhtml -p $(pwd)/ddal ${target}.lcov
        cd ../..
    done
}

_createHtmlBlacklisted() {
    local buildDir=${1}
    for target in FSM-r3 FSM-r4
    do
        mkdir -p html_blacklisted/${target}
        mv ${target}_blacklisted.lcov html_blacklisted/${target}
        echo "now copying ${buildDir}/src/ddal to html_blacklisted/${target}"
        cp -R ${buildDir}/src/ddal html_blacklisted/${target}
        cd html_blacklisted/${target}
        genhtml -p $(pwd)/ddal ${target}_blacklisted.lcov
        cd ../..
    done
}

_cleanupOldStuff() {
    rm -f *exclusions*
    rm -f *lcov*
    rm -rf html
    rm -rf html_blacklisted
}


buildDir=${1}
_cleanupOldStuff
_getLcovFilesFromJenkins
_getExclusionListsFromJenkins
_createBlacklistedLcovFiles
_createHtml ${buildDir}
_createHtmlBlacklisted ${buildDir}

