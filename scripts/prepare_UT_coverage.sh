#!/bin/bash

## @fn      _prepare_UT_coverage()
#  @brief   modify the coverage file for use with sonar runner
#  @param   {target} target of the coverage file, either FSM-r3 or FSM-r4
#  @return  <none>
_prepare_UT_coverage() {
    local target=${1:-FSM-r3}
    covFile=UT_${target}_coverage.xml
    echo preparing coverage file ${covFile} for use in Sonar

    if [[ -e ${covFile}.gz ]] ; then
        gunzip -f ${covFile}.gz
    fi

    if [[ -e ${covFile} ]] ; then
        # sed -i -e 's:/src-fsmddal/src/\([^-/]\+\)[^/]*:/src-fsmddal/src/\1:' -e 's:filename=".*src-fsmddal/src/:filename="src/ddal/:' -e 's:__unity_unittest/::' ${covFile}
        chmod 666 ${covFile}
    fi

    return 0
}
