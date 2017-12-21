#!/bin/bash

ERROR_COUNT=0

for test in tests/*.sql
do
	if psql < "$test" | grep ERROR; then
		ERROR_COUNT=$((ERROR_COUNT+1))
	fi
done

if [[ $ERROR_COUNT -ne 0 ]]; then
	echo $ERROR_COUNT tests failed
	exit 1
else
	echo All tests passed.
fi
