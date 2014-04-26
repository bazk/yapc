#!/bin/bash

#!/bin/bash

outdir="/tmp/yapc-create-outputs"
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
    echo -n "creating output for ${test}..."

    if [ -f "tests/${test/.pas/.fpc-incompatible}" ] || [ -f "tests/${test/.pas/.no-gen-output}" ]; then
        # no output necessary
        success
        return 0
    fi

    if echo ${test} | egrep "^[0-9]+-fail" >/dev/null; then
        # no output necessary
        success
        return 0
    fi

    ./yapc-to-fpc.py tests/${test} > ${outdir}/${test}

    fpc ${outdir}/${test} >${outdir}/${test}.fpc-out 2>&1
    ret=$?

    if [ ${ret} -ne 0 ]; then
        fail
        echo "error: compiling failed with return code = ${ret}"
        cat ${outdir}/${test}.fpc-out
        echo
        return 1
    fi

    infile="/dev/null"

    if grep "read" tests/${test} >/dev/null; then
        if [ ! -f tests/${test/.pas/.in} ]; then
            fail
            echo "error: missing input file"
            return 1
        fi

        infile="tests/${test/.pas/.in}"
    fi

    ${outdir}/${test/.pas/}  < ${infile} > ${outdir}/${test/.pas/.out} 2>${outdir}/${test/.pas/.err}
    ret=$?

    if [ ${ret} -ne 0 ]; then
        fail
        echo "error: execution failed with return code = ${ret}"
        cat ${outdir}/${test/.pas/.err}
        echo
        return 1
    fi

    cp ${outdir}/${test/.pas/.out} tests/${test/.pas/.out}

    success
    return 0
}

read -p "Are you sure, this will replace current test outputs? [y/N] " yn
case $yn in
    [Yy]* ) ;;
    * )     exit 0;;
esac

for t in tests/*.pas; do
    if ! dotest $(basename $t); then
        exit 1
    fi
done
