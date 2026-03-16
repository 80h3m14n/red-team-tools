#!/bin/bash

# Usage: ./ping_sweep.sh 192.168.1
# Scans IPs from .1 to .254 in the given subnet

NETWORK=$1

for i in $(seq 1 254); do
  ping -c 1 -w 1 "${NETWORK}.$i" > /dev/null 2>&1 && echo "${NETWORK}.$i is up"
done   