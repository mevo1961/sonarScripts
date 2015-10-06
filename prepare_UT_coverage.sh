#!/bin/bash

set -x
for target in fsmr3 fsmr4 
do
    covFile=UT_${target}_coverage.xml
    if [[ -e ${covFile}.gz ]] ; then
        gunzip -f ${covFile}.gz
    fi
    if [[ -e ${covFile} ]] ; then
	tempFile=$(mktemp)
	sed -e 's/filename=".*src-fsmddal\//filename="/' -e 's/__unity_unittest\///' ${covFile} > ${tempFile}
	# rm ${covFile}
        mv ${tempFile} ${covFile}
    fi
done
