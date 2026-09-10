#!/bin/bash

echo "Running TC01 - No arguments"

#Run the script and capture the output
actual=$(./loganalyze.sh)

#Capture the exit code
status=$?

#Expected output
expected=$(pwd)

#check exit code
if [ "$status" -ne 0 ]; then
    echo "[FAIL] Expected exit code: 0"
    exit 1
fi

#check output contains current directory
if [ "$actual" != "$expected" ]; then
    echo "[FAIL] Expected output: $expected"
    exit 1
fi

echo "[PASS] TC01"
exit 0


