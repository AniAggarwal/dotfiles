#!/usr/bin/bash
# Author: www.github.com/AniAggarwal

# This script will set up your account for you.
# Make sure to run: chmod +x account-setup.sh
# Then run ./account-setup.sh
# This will allow this file to run and setup your account.

echo 'Enter your section number in the form 0101 or similar and hit enter:'
read section
username="$(whoami)"

# compute the semester based on UMD schedule
days="$(date +'%j')"

if [ $days -le 23 ]; then
    semester="winter"
elif [ $days -le 144 ]; then
    semester="spring"
elif [ $days -le 230 ]; then
    semester="summer"
else
    semester="fall"
fi

year="$(date +"%Y")"


echo "Detected that you are $username and are in ${semester}${year}."
echo "If this is not correct, please open this file and modifiy the code yourself as neccesary."


if ! [ -e "/afs/glue/class/$semester$year/cmsc/216/$section/student/$username" ]; then
    echo 'Section was not found. Please check your section number or modifiy this code as neccesary yourself.'
    exit 1
fi

# create sym links
echo 'Creating sym links...'
personal="${HOME}/216"
public="${HOME}/216public"

if ! [ -L "${personal}" ]; then
    echo "Creating a sym link for ~/216 ..."
    ln -s "/afs/glue/class/$semester$year/cmsc/216/$section/student/$username" "${personal}"
fi

if ! [ -L "${public}" ]; then
    echo "Creating a sym link for ~/216public ..."
    ln -s "/afs/glue/class/$semester$year/cmsc/216/0101/public" "${public}"
fi


append_to_file () {
  line="$1"
  file="$2"

  if [ ! -f "$file" ]; then
    echo "Error: file '$file' does not exist."
    exit 1
  fi

  if [ ! -r "$file" ]; then
    echo "Error: file '$file' is not readable."
    exit 1
  fi

  grep -q "$line" "$file" || echo "$line" >> "$file"
}


echo 'Appending to neccesary files...'
append_to_file '(load "/afs/glue/class/spring2023/cmsc/216/0101/public/.216.elc" nil t)' "${HOME}/.emacs"
append_to_file 'setenv PATH "/afs/glue/class/spring2023/cmsc/216/0101/public/bin:${PATH}"' "${HOME}/.path"
append_to_file 'setenv PATH "~/.local/bin:${PATH}"' "${HOME}/.path"
append_to_file 'source ~/216public/.216settings' "${HOME}/.cshrc.mine"

echo 'Done! Checking if account is setup correctly...'
check-account-setup
