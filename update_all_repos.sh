#!/usr/bin/env bash

for d in $(ls); do
	if [ -d $d ] && [ $d != "." ] && [ $d != ".." ]; then
		cd $d
		
		remoteurl=`git config remote.origin.url`
		
		if [[ "$remoteurl" == *"bitbucket.org"* ]]; then
		
			git fetch -q
			
			logoutput=`git --no-pager log HEAD..origin/master --oneline 2>&1`
			
			if [ $? -ne 0 ]; then
				echo $d has a problem
				# actually don't care in this case...
			elif [ -n "$logoutput" ]; then
				echo -n $d has changes...
				
				mergeoutput=`git merge --ff-only origin/master 2>&1`
				
				if [ $? -ne 0 ]; then
					echo MANUAL MERGE REQUIRED!
				else
					echo Auto-FF merged!
				fi
				
			fi
		else
			echo Skipped $d
		fi
		
		cd ..
	fi
done