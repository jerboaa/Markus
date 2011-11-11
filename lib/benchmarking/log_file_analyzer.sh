#!/bin/bash

if [ $# -lt 1 ]; then
	echo "usage: $0 {path-to-result-log-tree}" 1>&2
	exit 1
fi

LOG_TREE=$1

grep -r "ELAPSED TIME" $LOG_TREE | sed 's/.*ELAPSED TIME+++ \(.*\) +++/\1/g' > $LOG_TREE/request_times.txt

ruby request_time_analyzer.rb $LOG_TREE/request_times.txt
