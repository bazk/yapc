#!/bin/bash

outdir="/tmp/yapc-test"
mkdir -p ${outdir}

red="\e[31m"
green="\e[32m"
bold="\e[1m"
reset="\e[0m"

function success() {
    echo -e " ${green}[done]${reset}"
}

function fail() {
    echo -e " ${red}${bold}[fail]${reset}"
}

function dotest() {
    test=$1
    echo -n "testing ${test}..."

    infile="/dev/null"
    if grep "read" tests/${test} >/dev/null; then
        if [ ! -f tests/${test/.pas/.in} ]; then
            fail
            echo "error: missing input file"
            return 1
        fi

        infile="tests/${test/.pas/.in}"
    fi

    ./executa.sh tests/${test} < ${infile} >${outdir}/${test}.out 2>${outdir}/${test}.err
    ret=$?

    echo ${test} | egrep "^[0-9]+-fail" >/dev/null
    should=$?

    if [ $should -eq 0 -a ${ret} -eq 0 ]; then
        fail
        echo "error: compiling did not failed as it was supposed to"
        return 1
    elif [ ${should} -ne 0 -a  ${ret} -ne 0 ]; then
        fail
        echo "error: compiling failed with return code = ${ret}"
        cat ${outdir}/${test}.err
        echo
        return 1
    fi

    if [ -f "tests/${test/.pas/.mepa}" ]; then
        if ! diff MEPA tests/${test/.pas/.mepa} >${outdir}/${test}.mepa.diff; then
            fail
            echo "error: mepa differs:"
            cat ${outdir}/${test}.mepa.diff
            echo
            return 2
        fi
    fi

    if [ -f "tests/${test/.pas/.out}" ]; then
        if ! diff ${outdir}/${test}.out tests/${test/.pas/.out} >${outdir}/${test}.out.diff; then
            fail
            echo "error: stdout differs:"
            cat ${outdir}/${test}.out.diff
            echo
            return 3
        fi
    fi

    success
    return 0
}

begin=$(date +%s)
count=0
suc=0
for t in tests/*.pas; do
    if dotest $(basename $t); then
        suc=$((suc+1))
    fi

    count=$((count+1))
done
end=$(date +%s)

echo
echo -e "$count tests executed in $((end-begin)) seconds, ${green}${bold}${suc}${reset} suceeded, ${red}${bold}$((count-suc))${reset} failed."