#!/usr/bin/env bash

usage() {
    echo
    echo "Usage $0 [-m] [-l] filename"
    echo "  checks if the supplied filename has changed from a reference point, where it can be either:"
    echo "  -m       : master branch "
    echo "  -l       : last sync from jenkins. "
    echo "  filename : ideally, the full path from top of git directory to avoid ambiguity"
    echo
    echo " Return : "
    echo "   0    : yes, file has changed"
    echo "   1    : no, file hasn't changed"
    exit -1
}

mode=

while getopts "ml" OPTION
do
    case $OPTION in
        l)
            mode="last"
            ;;
        m)
            mode="master"
            ;;
        *)
            usage
            ;;
    esac
done

shift $((OPTIND-1))

if [[ $# != 1 ]]; then
    usage
fi

filename=$1


if [[ -z $mode ]]; then
    echo
    echo "Either -l or -m should be selected."
    usage
fi


branch=
if [[ $mode == "master" ]]; then

    if [[ -n $ghprbSourceBranch ]]; then
        branch=$ghprbSourceBranch
    elif [[ -n $GIT_BRANCH ]]; then
        branch=$GIT_BRANCH
    else
        branch=`git branch |grep \* | cut -d' ' -f2`
    fi

    echo "diff master - current branch: $branch"
    file_changed=`git diff --name-status master..${branch} | grep ${filename} | awk '{print $2}'`

    if [[ -n $file_changed ]]; then
        exit 0
    else
        exit 1
    fi

fi

if [[ $mode == "last" ]]; then

    if [[ -z $JENKINS_HOME ]]; then
        echo
        echo "Warning: This script should be running inside Jenkins. You will get incorrect result."
        echo
        exit -1
    fi

    echo "diff prev commit - current commit: $GIT_PREVIOUS_COMMIT : $GIT_COMMIT"

    git log  --format="format:hash:%H" --name-status ${GIT_PREVIOUS_COMMIT}..${GIT_COMMIT}

    echo "$filename"
    entry=`git log  --format="format:hash:%H" --name-status ${GIT_PREVIOUS_COMMIT}..${GIT_COMMIT} |grep ${filename}`
    change_mode=`echo $entry | awk '{print $1}'`
    if [[ $change_mode == "M" ]]; then
        exit 0
    else
        exit 1
    fi
fi

exit -1
