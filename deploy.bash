#! /bin/bash

set -o xtrace

cd_name=${PWD##*/} 
cd_full_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
git_dir="$cd_full_path/.git"
[ ! -d "$git_dir" ] && { echo "This directory does not contain a git repository; exiting..."; exit 1; }

# determine where to create SVN repository
[ -f ./svn_dir ] && svn_dir=$(<./svn_dir)
if [ -z "$svn_dir" -o ! -d "$svn_dir" ]; then
    echo "Please enter the name of the folder to use for the SVN repository: "
    read svn_dir;
    mkdir "$svn_dir"
    echo "$svn_dir">./svn_dir
fi

cd "$svn_dir"

# determine slug
[ -f ./slug ] && slug=$(<./slug)
if [ -z $slug ]; then
    slug="$cd_name"
    echo "Is your SVN slug \"$slug\"?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) echo -e "Plugin Slug: \c"; read slug; break;;
        esac
    done
    echo "$slug">./slug
fi

# determine SVN user name
[ -f ./username ] && username=$(<./username)
if [ -z $username ]; then
    echo "Please enter your SVN user name: "
    read username;
    echo "$username">./username
fi

# determine main plugin file
[ -f ./mainfile ] && mainfile=$(<./mainfile)
if [ -z "$mainfile" ]; then
    [ -f "../$cd_name.php" ] && mainfile="$cd_name.php"
    echo "Is the plugin's main file \"$mainfile\"?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) echo -e "Enter main file's name: \c"; read mainfile; break;;
        esac
    done
    [ ! -f "../$mainfile" ] && { echo "File \"$mainfile\" not found. Exiting..."; exit 1; }
    echo "$mainfile">./mainfile
fi

svn_url="http://plugins.svn.wordpress.org/$slug/"

# make sure versions in readme.txt and main php file match
readme_version=$(grep "^Stable tag" $cd_full_path/readme.txt | awk -F' ' '{print $3}')
main_file_version=$(grep "^Version" $cd_full_path/$mainfile | awk -F' ' '{print $2}')
echo "readme version: $readme_version"
echo "main php version: $main_file_version"
[ "$readme_version" != "$main_file_version" ] && { echo "Versions don't match. Exiting..."; exit 2; }

# make sure SVN repository is checked out
cd "$cd_full_path"
if [ "$(cd $svn_dir; svn info >/dev/null 2>&1; echo $?)" -ne 0 ]; then
    echo "$svn_dir does not contain a SVN repo - checking out from $svn_url..."
    svn co "$svn_url" "$svn_dir"
    [ $? -ne 0 ] && { echo "Looks like SVN URL is wrong ($svn_url), please make sure the wordpress slug is correct."; exit 3; }
fi

# commit message - all git commit messages since latest tag - or first commit, if no tags
cd "$cd_full_path"
from=$(git describe --abbrev=0 --tags 2>&1)
[ $? -ne 0 ] && from=$(git log --format=%H | tail -1)
git log --pretty=oneline $from.. | cut -d " " -f 2- >$svn_dir/message.txt

# tag and push git to origin
echo "Creating new git tag: $readme_version"
git tag -a "$readme_version" -m"Version $readme_version"
echo "Pushing latest commit to git origin, with tags"
#git push origin master
#git push origin master --tags

# update SVN trunk
echo "Copying git HEAD into SVN trunk, and SVN add new/modified files..."
git checkout-index -a -f --prefix="$svn_dir/trunk/"
cd "$cd_full_path/$svn_dir/trunk"
if [ -n "$(svn status)" ]; then
    [ -n "$(svn status | grep '^?')" ] && svn status | grep "^?" | awk '{print $2}' | xargs svn add
fi
$(svn commit --username=$username --file ../message.txt)

# generate SVN tag
cd "$cd_full_path/$svn_dir"
[ ! -d tags ] && mkdir tags
if [ ! -d "tags/$readme_version" ]; then
    svn copy trunk/ "tags/$readme_version/"
    cd "$cd_full_path/$svn_dir/tags/$readme_version"
    $(svn commit --username=$username -m "Version $readme_version")
else
    echo "Tag $readme_version already exists - not overrwriting."
fi
