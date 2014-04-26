#!/bin/bash

stop_on_fail=0
if [ "$1" == "--stop-on-fail" -o "$1" == "-f" ]; then
    stop_on_fail=1
fi

outdir="/tmp/yapc-test"
mkdir -p ${outdir}

red="\e[31m"
green="\e[32m"
bold="\e[1m"
reset="\e[0m"

function run() {
    as --32 mepa.s -o mepa.o && \
    ld -m elf_i386 -L/usr/lib32 mepa.o -o mepa -lc -dynamic-linker /lib/ld-linux.so.2 && \
    ./mepa && \
    return 0

    return 1
}

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

    ./compilador tests/${test} >${outdir}/${test}.compile-out 2>&1
    ret=$?

    if echo ${test} | egrep "^[0-9]+-fail" >/dev/null; then
        if [ ${ret} -eq 0 ]; then
            fail
            echo "error: compiling did not failed as it was supposed to"
            return 1
        else
            success
            return 0
        fi
    fi

    if [ ${ret} -ne 0 ]; then
        fail
        echo "error: compiling failed with return code = ${ret}"
        cat ${outdir}/${test}.compile-out
        echo
        return 1
    fi

    if [ -f "tests/${test/.pas/.mepa}" ]; then
        if ! diff -Z MEPA tests/${test/.pas/.mepa} >${outdir}/${test}.mepa.diff; then
            fail
            echo "error: mepa differs:"
            cat ${outdir}/${test}.mepa.diff
            echo
            return 2
        fi
    fi

    run < ${infile} >${outdir}/${test}.out 2>${outdir}/${test}.err
    ret=$?

    if [ ${ret} -ne 0 ]; then
        fail
        echo "error: execution failed"
        cat ${outdir}/${test}.err
        echo
        return 1
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

make
ret=$?
if [ $ret -ne 0 ]; then
    echo "error: failure at building the compiler"
    exit $ret
fi

begin=$(date +%s)
count=0
suc=0
for t in tests/*.pas; do
    if dotest $(basename $t); then
        suc=$((suc+1))
    elif [ ${stop_on_fail} -eq 1 ]; then
        break
    fi

    count=$((count+1))
done
end=$(date +%s)

echo
echo -e "$count tests executed in $((end-begin)) seconds, ${green}${bold}${suc}${reset} suceeded, ${red}${bold}$((count-suc))${reset} failed."