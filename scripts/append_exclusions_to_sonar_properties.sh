#!/bin/bash

## @fn      _append_exclusions_to_sonar_properties()
#  @brief   append the contents of the exclusion list to the sonar properties file
#  @param   <none>
#  @return  <none>
_append_exclusions_to_sonar_properties() {
    local infile=${1:-fsmr3_exclusions.txt}
    local outfile=${2:-sonar-project.properties}

    echo "getting exclusion list from $infile and appending it to $outfile ..."
    echo 'sonar.exclusions= \' >> "$outfile"

    # if $GIT ; then
    #     # adapt paths in infile
    #     sed -i -e 's:/src/:/src/ddal/:' ${infile}
    # fi

    local old=
    local new=

    if $GIT ; then
        old=/src/
        new=/src/ddal/
    fi

    while read -r line
    do
        # write line to outfile, replacing /src/ with /src/ddal/ if $GIT is true
        echo "	${line/$old/$new}" >> "$outfile"
    done < "$infile"

    return 0
}
