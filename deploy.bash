#! /bin/bash

cd=${PWD##*/} 

# determine slug
[ -f ./slug ] && slug=$(<./slug)
if [ -z $slug ]; then
    slug="$cd"
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
    [ -f "$cd.php" ] && mainfile="$cd.php"
    echo "Is the plugin's main file \"$mainfile\"?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) echo -e "Enter main file's name: \c"; read mainfile; break;;
        esac
    done
    echo "$mainfile">./mainfile
fi


