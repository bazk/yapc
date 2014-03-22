#!/bin/bash

if [ $# -ne 1 ]; then
    echo -e "Usage:\n\t$0 INPUT" >&2
    exit 1
fi

file="$1"

if [ ! -f ${file} ]; then
    echo -e "error: cannot open ${file} for reading" >&2
    exit 2
fi

sed -e '$a\' ${file} | while IFS='' read -r line; do
    if ! echo $line | grep "write" >/dev/null; then
        echo "$line"
        continue
    fi

    begin=$(echo "$line" | sed 's/^\( *write *(\).*\().*\)$/\1/g')
    begin=$(echo "$begin" | sed 's/write/writeln/g')
    end=$(echo "$line" | sed 's/^\( *write *(\).*\().*\)$/\2/g')
    params=$(echo "$line" | sed 's/.*write *(\(.*\)).*/\1/g')
    params=$(echo "$params" | sed 's/,/\n/g')
    count=$(echo "$params" | wc -l)

    i=0
    for p in $params; do
        i=$((i+1))

        if [ $i -lt $count ]; then
            echo "$begin$p);"
        else
            echo "$begin$p$end"
        fi
    done
done