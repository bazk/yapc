#!/bin/bash

set -e # exit on first error

make debug > /dev/null
./compilador $1
as --32 mepa.s -o mepa.o
ld -m elf_i386 -L/usr/lib32 mepa.o -o mepa -lc -dynamic-linker /lib/ld-linux.so.2
./mepa