#!/bin/bash

submodules=( "ARENA-core:master" "arena-account:main" "arena-persist:master" "arts:master" "arena-runtime-simulated:master")

echo -e "\n###Pulling lastest version of submodules."
for s in "${submodules[@]}"
do
	echo $s
	repo=`echo $s | cut -d':' -f1`
	branch=`echo $s | cut -d':' -f2`
  cd $repo
  git checkout $branch
  git pull
  cd ..
done

echo -e "\n### Want to commit and push the update to the submodules ?"
read -p "Continue? (y/N) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	for s in "${submodules[@]}"
	do
		repo=`echo $s | cut -d':' -f1`
	  git add $repo
	done

	# commit the change in arena-services-docker repo
	git commit -m "Updated submodules to latest commit"
	git push
fi
