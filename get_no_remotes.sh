#!/usr/bin/env bash

for i in `ls`; do

	if [ -d $i ]; then 
		cd $i
		output=`git remote`
		
		if [ -z "$output" ]; then
			echo $i
		fi
		
		cd ..
	fi
done