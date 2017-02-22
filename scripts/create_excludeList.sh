#!/bin/bash

echo "Now creating exclusion list for Sonar ..."
DIR=../
SONARDIR=${WORKSPACE:-"$HOME"/workspace/}/sonar
SRCDIR="$SONARDIR"/src-fsmddal/src

echo searching C files in src
echo ignoring  tools DSDT fpa_test
# the dirs ignored here get a special treatment below
( cd $(dirname "$SRCDIR") && find $(basename "$SRCDIR") -name '*.c' ) | egrep -v '/stubs/|/tools/|/DSDT/|/fpa_test/' | sort > __temp1


TARGET_TYPE=${TARGET_TYPE-empty}
case "${TARGET_TYPE}" in
    "FSM-r3" ) TARGET=fct ;;
    "FSM-r4" ) TARGET=fsm4_arm ;;
    * )
        echo TARGET_TYPE not found: ${TARGET_TYPE}
        exit 1 
    ;;
esac


LIBDIR="$SONARDIR"/src-fsmddal/build/${TARGET}/src

ar t "$LIBDIR"/libFSMDDAL.a  > __temp2

sed -i -e 's/\.o/\.c/' __temp2

# remove some files that should always be blacklisted
sed -i -e '/_stubs.c/d' -e '/^_version.c/d' -e '/fpa_test.c/d' -e '/ddal_auth_set_user_password_pam_pass_non_interractive.c/d' __temp2

RESFILE="${TARGET_TYPE}_exclusions.txt"

grep -v -f __temp2 __temp1 | sort > "$RESFILE"

# add additional directories that should be left out completely
for dir in tools/** stubs/** lx2/DSDT/** **/*.h
do
    echo "src/$dir" >> "$RESFILE"
done

sed -i -e '$!s/$/ ,\\/' -e 's/^/**\//' "$RESFILE" 

rm -f __temp*
