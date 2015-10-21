#!/bin/bash

# set -x
# added comment
for target in fsmr3 fsmr4 
do
    covFile=SCT_${target}_coverage.xml
    if [[ -e ${covFile}.gz ]] ; then
        gunzip -f ${covFile}.gz
    fi
    if [[ -e ${covFile} ]] ; then
	tempFile=$(mktemp)
        sed -e 's:fsmddal/:src/:' ${covFile}  >  ${tempFile}
        mv ${tempFile} ${covFile}
    fi
done
