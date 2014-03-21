#!/bin/bash

set -e # exit on first error

if [ "$1" == "-d" ]; then
    shift
    make clean > /dev/null
    make debug > /dev/null
else
    make > /dev/null
fi

./compilador $1
as --32 mepa.s -o mepa.o
ld -m elf_i386 -L/usr/lib32 mepa.o -o mepa -lc -dynamic-linker /lib/ld-linux.so.2
./mepa