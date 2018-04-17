#!/bin/bash

# git账号@前面的英文全拼
username="wangyichen"
# 项目组名，参考git迁移.xlsx中的“项目组名”字段
team_name="dating"
# 工程名称，参考git迁移.xlsx中的“项目名”字段
project_name="hall"
# git主工程地址
pro_git_repo="http://192.168.10.7:8090/client/projects/dating/hall/project.git"

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

git clone --recursive $pro_git_repo $project_name
cd $project_name
git checkout -b develop remotes/origin/develop
sudo chmod -R 775 .git

echo clone finish
