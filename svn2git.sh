#!/bin/bash

user_file=""
svn_repo=""
git_repo=""
ignore_file=""
need_develop_branch=1
project_name=""

function usage()
{
	echo "usage: svn2git [-h] [-u <user file>] [-s <svn repository>] [-g <git repository>] [-i <git ignore file>] [-D] [-p <project name>]"
	echo "options:"
	echo "-D,		indicate that don't create develop branch"
	echo "-g,		specify git remote repository url, must"
	echo "-h,		show usage"
	echo "-i,		specify git ignore file, optional"
	echo "-s,		specify svn central repository to port, must"
	echo "-u,		specify svn to git user mapping file, optional"
    echo "-p,		specify project name, optional"
}

while getopts "u:s:g:i:p:Dh" opt
do
	case $opt in
		u)
			user_file=$OPTARG
			;;
		s)
			svn_repo=$OPTARG
			;;
		g)
			git_repo=$OPTARG
			;;
		i)
			ignore_file=$OPTARG
			;;
        p)
            project_name=$OPTARG
            ;;
		D)
			need_develop_branch=0
			;;
		h)
			usage
			exit 1
			;;
		\?)
			usage
			exit 1
			;;
	esac
done

if [ -z "$svn_repo" -o -z "$git_repo" ]
then
	echo "please specify svn repository and git repository"
	exit 1
fi

#if [ -z "${ignore_file}" ]
#then
#	read -p "is it ok not to specify ignore file?[Y/N]:" reply
#	if [[ ! $reply =~ Y|y|YES|yes ]]
#	then
#		exit 1
#	fi
#elif [ ! -e "${ignore_file}" ]
#then
#	echo "specified gitignore file does not exist!"
#	exit 1
#fi

echo "mapping svn users to git users..."

tmp_user_file=/tmp/users.tmp
if [ -e "${tmp_user_file}" ]
then
	rm -f ${tmp_user_file} 2>/dev/null
fi

if [ -e "$user_file" ]
then
	cp ${user_file}	${tmp_user_file}
fi

svn log ${svn_repo} --xml | egrep '^<author>' | sort -u | sed -E 's/^<author>(.+)<\/author>$/\1 = \1<\1@ixianlai.com>/' | \
while read line; do egrep -i "^${line}$" "${tmp_user_file}" >/dev/null; if [ $? -ne 0 ];then echo ${line};fi done >> ${tmp_user_file}

echo "cloning svn repository..."

if [ -z "$project_name" ]
then
    project_name=${svn_repo##*/}
fi

git svn clone --no-minimize-url --quiet ${svn_repo} --ignore-paths='(\.sdf$|\.suo$|\.VC\.db$|\.dll$)' \
--authors-file=${tmp_user_file} --no-metadata ${project_name} 1 > /dev/null

if [ $? -ne 0 ]
then
	echo "failed to clone svn repository ${svn_repo}"
	exit 1
fi

if [ -e "${ignore_file}" ]
then
	cp ${ignore_file} ${project_name}/.gitignore
else
    touch ${project_name}/.gitignore
fi

cd ${project_name}

#echo "please check log."
#git log

#read -p "to be continous?[Y/N]:" reply
#if [[ ! $reply =~ Y|y|YES|yes ]]
#then
#	exit 1
#fi

echo "list all branches."
git branch -a

echo "deleting unused remote branches..."
git for-each-ref refs/remotes | cut -d / -f 3- | grep -v @ | while read branchname; do git branch -r -d "$branchname"; done

if [ -e .gitignore ]
then
	echo "add gitignore file"
	git add .gitignore
	git commit -m 'add ignore file'
# else
# 	echo "ignore file does not exist."
# 	exit 1
fi

if [ $need_develop_branch -ne 0 ]
then
	echo "creating develop branch..."
	git branch develop master
fi

echo "please check branches."
git branch -a

#read -p "to be continous?[Y/N]:" reply
#if [[ ! $reply =~ Y|y|YES|yes ]]
#then
#	exit
#fi

echo "adding remote repository..."
git remote add origin ${git_repo}

if [ $? -ne 0 ]
then
	echo "failed to add remote repository. please make sure remote repository url ${git_repo} is correct."
fi

echo "pushing all branches..."
git push -u origin --all

if [ $? -ne 0 ]
then
	echo "failed to push branches to remote repository ${git_repo}."
	exit 1
fi

echo "list all branches once again."
git branch -a

echo "finished to port from svn to git!"
