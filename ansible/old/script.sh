#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "Usage: script --list"
    exit 1
fi
if [ $1 = "--list" ]
  then
    cat ./inventory.json
fi
