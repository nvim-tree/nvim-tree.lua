#!/usr/bin/env sh

if [ "${1}" = "/tmp/nvt_func/data/f 1" ]; then
	rm "${1}"
	exit 0
else
	echo -n "synthetic trash failure" >&2
	exit 1
fi
