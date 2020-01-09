#!/bin/sh
pid=$1
[[ $pid ]] && kill -9 $(pstree $pid -p|grep -oE "\([0-9]+\)"|grep -oE "[0-9]+")