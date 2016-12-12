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

getVolume() {
	base=`basename $1`
	dir=`dirname $1`
	echo "$dir/.$base.ecryptfs"
}

create() {
	name=`realpath $1`
	volume=`getVolume $name`

	info "Creating dir $name"
	safe mkdir -p "$name"

	info "Creating subvolume $volume"
	safe btrfs subvolume create "$volume"

	echo "Passphrase:"
	pass=`ecryptfs-add-passphrase | perl -ne 'print $1 if /\[(.*)\]/'`

	echo "Passphrase: (verify)"
	pass2=`ecryptfs-add-passphrase | perl -ne 'print $1 if /\[(.*)\]/'`

	[ $pass = $pass2 ] || error 'Passphrase mismatch'

	info "Adding to fstab"
	safe sudo sh -c "echo '$volume $name ecryptfs rw,user,noauto,exec,key=passphrase,ecryptfs_sig=$pass,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_passthrough,ecryptfs_fnek_sig=$pass,ecryptfs_unlink_sigs 0 0' >> /etc/fstab"

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

home() {
	name=`realpath $1`
	volume=`getVolume $name`

	# TODO: check if ecryptbtrfs volume exists and if unmounted

	pam_mount_file='/etc/security/pam_mount.conf.xml'
	if [ ! -e $pam_mount_file ]; then
		info "Updating $pam_mount_file"
		safe sudo sh -c 'cat << EOF > '$pam_mount_file'
<?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE pam_mount SYSTEM "pam_mount.conf.xml.dtd">
<pam_mount>
        <debug enable="0" />
        <mntoptions allow="nosuid,nodev,loop,encryption,fsck,nonempty,allow_root,allow_other" />
        <mntoptions require="" />
        <logout wait="0" hup="0" term="0" kill="0" />
        <mkmountpoint enable="1" remove="true" />
        <lclmount>mount -i %(VOLUME) "%(before=\"-o\" OPTIONS)"</lclmount>
        <luserconf name=".pam_mount.conf.xml" />
</pam_mount>
EOF'
	fi

	system_auth_file='/etc/pam.d/system-auth'
	grep -q ecryptfs $system_auth_file
	if [ $? -ne 0 ]; then
		info "Updating $system_auth_file"
		safe sudo cp $system_auth_file $system_auth_file.old
		safe sudo sh -c 'cat << EOF > '$system_auth_file'
#%PAM-1.0

auth      required  pam_unix.so     try_first_pass nullok
auth      required  pam_ecryptfs.so unwrap
auth      optional  pam_mount.so
auth      optional  pam_permit.so
auth      required  pam_env.so

account   required  pam_unix.so
account   optional  pam_permit.so
account   required  pam_time.so

password  optional  pam_ecryptfs.so
password  optional  pam_mount.so
password  required  pam_unix.so     try_first_pass nullok sha512 shadow
password  optional  pam_permit.so

session   optional  pam_mount.so
session   required  pam_limits.so
session   required  pam_unix.so
session   optional  pam_ecryptfs.so unwrap
session   optional  pam_permit.so
EOF'
	fi

	safe chmod u+w $HOME
	mkdir -p $HOME/.ecryptfs

	info "Wrapping ecryptfs password"
	safe ecryptfs-wrap-passphrase $HOME/.ecryptfs/wrapped-passphrase
	safe touch $HOME/.ecryptfs/auto-mount

	echo "Setting user pam conf"
	safe cat << EOF > $HOME/.pam_mount.conf.xml
<pam_mount>
    <volume noroot="1" fstype="ecryptfs" path="$volume" mountpoint="$name"/>
</pam_mount>
EOF
	safe chmod 500 $HOME
}

[ "$USER" = "root" ] && error "Do not be root!"

cmd=$1

case "$cmd" in
	"create")
		create $2
		;;
	"mount")
		mount $2
		;;
	"home")
		home $2
		;;
esac
