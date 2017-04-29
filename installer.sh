#!/bin/sh

WHITE="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
CYAN="\033[36m"

info()
{
	echo -e "$GREEN[info]\t$WHITE $@$WHITE"
}

error()
{
	echo -e "$RED[error]\t$WHITE $@$WHITE" 1>&2
	exit -1
}

safe()
{
	"$@" || error "$@"
}

PREFIX="/usr/local"

# fetch scripts
repo=`safe mktemp -d`

safe git clone https://github.com/oszika/ecryptbtrfs.git $repo
info "Ecryptbtrfs cloned"

safe install -v -m 0755 $repo/ebtrfs $PREFIX/sbin
safe install -v -m 0755 $repo/ecryptfs.sh $PREFIX/sbin
safe install -v -m 0755 $repo/efs $PREFIX/sbin

safe rm -rf $repo
info "Temp dir cleaned"
