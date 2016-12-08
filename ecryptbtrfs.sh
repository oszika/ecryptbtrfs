#!/bin/sh

WHITE="\033[0m"
RED="\033[31m"
GREEN="\033[32m"

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

create() {
	name=$1
	base=`basename $name`
	dir=`dirname $name`
	volume="$dir/.$base.ecryptfs"

	info "Create dir $name"
	safe mkdir -p "$name"

	info "Create subvolume $volume"
	safe btrfs subvolume create "$volume"
}

cmd=$1

case "$cmd" in
	"create")
		create $2
	;;
esac
