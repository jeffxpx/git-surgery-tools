#!/usr/bin/env bash

for i in `ls -a`; do
	if [ -d $i ] && [ $i != "." ] && [ $i != ".." ]; then
		cd $i
		original=`git config remote.origin.url`

		updated=`echo $original | sed 's/^https:\/\/.*@bitbucket.org\/\(.*\)$/git@bitbucket.org:\1/g' | sed 's/^https:\/\/bitbucket.org\/\(.*\)$/git@bitbucket.org:\1/g'`
		
		if [ "$original" != "$updated" ]; then 
			git remote rename origin old
		
			git remote add origin $updated
		
			echo "Updated $i -> $updated"	
		fi

		cd ..
	fi
done