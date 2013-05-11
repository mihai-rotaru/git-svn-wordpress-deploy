#! /bin/bash

cd_name=${PWD##*/} 
git_dir=`pwd`

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

# determine main file
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
    echo "$mainfile">./mainfile
fi


