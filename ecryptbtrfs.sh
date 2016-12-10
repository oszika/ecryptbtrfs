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
	name=`realpath $1`
	base=`basename $name`
	dir=`dirname $name`
	volume="$dir/.$base.ecryptfs"

	info "Creating dir $name"
	safe mkdir -p "$name"

	info "Creating subvolume $volume"
	safe btrfs subvolume create "$volume"
	safe mkdir -p "$volume/Private"

	echo "Passphrase:"
	pass=`ecryptfs-add-passphrase | perl -ne 'print $1 if /\[(.*)\]/'`

	echo "Passphrase: (verify)"
	pass2=`ecryptfs-add-passphrase | perl -ne 'print $1 if /\[(.*)\]/'`

	[ $pass = $pass2 ] || error 'Passphrase mismatch'

	info "Adding to fstab"
	safe sudo sh -c "echo '$volume/Private $name ecryptfs rw,user,noauto,exec,key=passphrase,ecryptfs_sig=$pass,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_passthrough,ecryptfs_fnek_sig=$pass,ecryptfs_unlink_sigs 0 0' >> /etc/fstab"

	info "Setting user rights ($USER)"
	safe sudo chown -R $USER:users $name
	safe sudo chown -R $USER:users $volume
	safe sudo chmod 500 $name
}

# Try to mount with kernel keyring
# If failed, retry after adding passphrase
mount() {
	name=`realpath $1`

	/usr/bin/mount -i $name > /dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo 'Passphrase:'
		ecryptfs-add-passphrase > /dev/null
		safe /usr/bin/mount -i $name
	fi
}

cmd=$1

case "$cmd" in
	"create")
		create $2
	;;
	"mount")
		mount $2
		;;
esac
