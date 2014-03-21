#!/bin/bash

outdir="/tmp/yapc-test"
mkdir -p ${outdir}

for t in tests/*.pas; do
    test=$(basename $t)
    echo -n "testing ${test}..."
    ./executa.sh tests/${test} >${outdir}/${test}.out 2>${outdir}/${test}.err
    ret=$?

    echo ${test} | egrep "^[0-9]+-fail" >/dev/null
    should=$?

    if ( [ $should -eq 0 -a ${ret} -ne 0 ] ) || [ ${should} -ne 0 -a  ${ret} -eq 0 ]; then
        echo -e " \e[32m[done]\e[0m"
    else
        echo -e " \e[31m\e[1m[fail]\e[0m"
        echo "return code = ${ret}"
        cat ${outdir}/${test}.err
        echo
    fi
done