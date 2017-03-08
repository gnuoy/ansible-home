#!/bin/bash

servers=$(lxc list | awk '/ans-/ {print $2}' | paste -sd ' ')
for server in $servers; do
    lxc stop $server
    lxc delete $server
done
