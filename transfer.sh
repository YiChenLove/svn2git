#!/bin/bash

# git账号@前面的英文全拼
username="wangyichen"
# 项目组名，参考git迁移.xlsx中的“项目组名”字段
team_name="dating"
# 工程名称，参考git迁移.xlsx中的“项目名”字段
project_name="hall"
# svn工程地址
pro_svn_repo="http://192.168.10.4/svn/Department_GameHall/project/client"
# git项目地址
pro_git_repo="http://192.168.10.7:8090/client/projects/dating/hall/project.git"
# cocosstudio svn地址
cstudio_svn_repo="http://192.168.10.4/svn/Department_GameHall/project/share"
# cocosstudio git地址
cstudio_git_repo="http://192.168.10.7:8090/client/projects/dating/hall/cocosstudio.git"
# frameworks项目git地址
frameworks_git_repo="http://192.168.10.7:8090/client/projects/dating/hall/frameworks.git"

submodule_git_repo="http://192.168.10.7:8090/client/projects/submodule.git"




if [ -z "$team_name" -o -z "$project_name" ]
then
	echo "please specify team_name and project_name"
	exit 1
fi

if [ -z "$pro_svn_repo" -o -z "$pro_git_repo" ]
then
	echo "please specify pro_svn_repo and pro_git_repo"
	exit 1
fi

if [ -z "$cstudio_svn_repo" -o -z "$cstudio_git_repo" ]
then
	echo "please specify cstudio_svn_repo and cstudio_git_repo"
	exit 1
fi

git config --global user.name $username
git config --global user.email "$username@ixianlai.com"
git config --global credential.helper osxkeychain

sudo ln -s /Applications/Xcode.app/Contents/Developer/Library/Perl/5.18/darwin-thread-multi-2level/SVN/ /Library/Perl/5.18/SVN
sudo mkdir /Library/Perl/5.18/auto
sudo ln -s /Applications/Xcode.app/Contents/Developer/Library/Perl/5.18/darwin-thread-multi-2level/auto/SVN/ /Library/Perl/5.18/auto/SVN

mkdir $team_name

cd $team_name

if [ -d "$project_name" ]
then
    rm -d -f -r $project_name
fi

echo "start transfer main project"
sh ../svn2git.sh -s $pro_svn_repo -g $pro_git_repo -p $project_name -i ../.gitignore -D
echo "end transfer main project"

if [ $? -ne 0 ]
then
	echo "failed to tranfer"
	exit 1
fi

echo "start commit frameworks"
git clone $frameworks_git_repo frameworks
cp -r $project_name/frameworks/runtime-src frameworks
cp ../.gitignore frameworks/.gitignore
cd frameworks
git add -A
git commit -a -m "frameworks first commit"
git push -u origin --all
cd ..
rm -d -f -r frameworks
echo "end commit frameworks"

echo "start transfer cocosstudio"
sh ../svn2git.sh -s $cstudio_svn_repo -g $cstudio_git_repo -p cocosstudio -i ../.gitignore -D
rm -d -f -r cocosstudio
echo "end transfer cocosstudio"

cd $project_name

if [ -d "frameworks" ]
then
    echo "start delete frameworks"
	rm -d -f -r frameworks
fi

git add -A
git commit -a -m "delete frameworks"
git push -u origin --all

echo "start add cocosstudio submodule"
git submodule add $cstudio_git_repo cocosstudio
git add .
git commit -m "add cocosstudio submodule"
git push -u origin --all
echo "end add cocosstudio submodule"

echo "start add frameworks submodule"
git submodule add $frameworks_git_repo frameworks
git add .
git commit -m "add frameworks submodule"
git push -u origin --all
echo "end add frameworks submodule"

echo "start add submodule submodule"
git submodule add $submodule_git_repo submodule
git add .
git commit -m "add submodule submodule"
git push -u origin --all
echo "end add submodule submodule"

git branch develop master
git commit -m "commit develop branch"
git push -u origin --all
git checkout develop

sudo chmod -R 775 .git

echo conver finish
