#!/bin/bash

## @fn      _prepare_SCT_coverage()
#  @brief   modify the coverage file for use with sonar runner
#  @param   {target} target of the coverage file, either FSM-r3 or FSM-r4
#  @return  <none>
_prepare_SCT_coverage() {
    local target=${1:-FSM-r3}
    covFile=SCT_${target}_coverage.xml

    if [[ -e ${covFile}.gz ]] ; then
        gunzip -f ${covFile}.gz
    fi

    if [[ -e ${covFile} ]] ; then
        sed -i -e 's:fsmddal/:src/ddal/:' ${covFile}
        chmod 666 ${covFile}
    fi

    return 0
}
