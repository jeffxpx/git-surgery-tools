#!/usr/bin/env bash

for d in $(ls); do
	if [ -d $d ] && [ $d != "." ] && [ $d != ".." ]; then
		cd $d
		git fetch -q
		
		logoutput=`git --no-pager log HEAD..origin/master --oneline`
		
		if [ -n "$logoutput" ]; then
			echo $d has changes
		fi
		
		cd ..
	fi
done