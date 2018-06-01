#!/bin/sh

WHITE="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
CYAN="\033[36m"

info()
{
	echo -e "$GREEN[info]\t$WHITE $@$WHITE"
}

debug()
{
	echo -e "$CYAN[debug]\t$WHITE $@$WHITE"
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


# Returns real name subvolume: .<name>.ecryptfs
getVolume() {
	base=`basename $1`
	dir=`dirname $1`
	realpath "$dir/.$base.ecryptfs"
}

# Init ecryptfs conf for volume
ecryptfs_init() {
	name=$1
	volume=$2
	enc_root="$volume/root"
	enc_sig="$volume/sig"

	safe mkdir -p "$name"
	debug "Mount dir $name created"

	safe mkdir -p "$enc_root"
	debug "Ecryptfs root $enc_root created"

	echo "Passphrase:"
	pass=`ecryptfs-add-passphrase | perl -ne 'print $1 if /\[(.*)\]/'`

	echo "Passphrase: (verify)"
	pass2=`ecryptfs-add-passphrase | perl -ne 'print $1 if /\[(.*)\]/'`

	[ $pass = $pass2 ] || error 'Passphrase mismatch'

	echo -e "$pass\n$pass" > $enc_sig
	debug "Ecryptfs configuration written"

	safe sudo chown -R $USER:users $name
	safe sudo chown -R $USER:users $volume
	safe sudo chmod 500 $name
	debug "User rights setted ($USER)"
}

# Try to mount with kernel keyring
# If failed, retry after adding passphrase
ecryptfs_mount() {
	name=`realpath $1`
	volume=`getVolume $name`
	enc_root="$volume/root"
	enc_conf="$volume/conf"
	enc_sig="$volume/sig"

	safe mkdir -p ~/.ecryptfs

	[ -L ~/.ecryptfs/tmp.sig ] && safe rm ~/.ecryptfs/tmp.sig

	safe ln -s $enc_sig ~/.ecryptfs/tmp.sig
	echo "$enc_root $name ecryptfs" > ~/.ecryptfs/tmp.conf
	debug "Ecryptfs configuration written"

	mount.ecryptfs_private tmp > /dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo 'Passphrase:'
		ecryptfs-add-passphrase > /dev/null
		safe mount.ecryptfs_private tmp
	fi

	safe rm ~/.ecryptfs/tmp.sig
	safe rm ~/.ecryptfs/tmp.conf

	debug "Volume mounted"
}

ecryptfs_umount() {
	name=`realpath $1`
	volume=`getVolume $name`
	enc_root="$volume/root"
	enc_conf="$volume/conf"
	enc_sig="$volume/sig"

	[ -L ~/.ecryptfs/tmp.sig ] && safe rm ~/.ecryptfs/tmp.sig

	safe ln -s $enc_sig ~/.ecryptfs/tmp.sig
	echo "$enc_root $name ecryptfs" > ~/.ecryptfs/tmp.conf
	debug "Ecryptfs configuration linked"

	safe umount.ecryptfs_private -f tmp

	safe rm ~/.ecryptfs/tmp.sig
	safe rm ~/.ecryptfs/tmp.conf

	debug "Volume umounted"

	echo "Don't forget to clear your keys: \"keyctl clear @u\""
}

ecryptfs_home() {
	name=`realpath $1`
	volume=`getVolume $name`
	enc_root="$volume/root"
	enc_sig="$volume/sig"

	# TODO: check if ecryptbtrfs volume exists and if unmounted

	pam_mount_file='/etc/security/pam_mount.conf.xml'
	if [ ! -e $pam_mount_file ]; then
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
		debug "$pam_mount_file updated"
	fi

	system_auth_file='/etc/pam.d/system-auth'
	grep -q ecryptfs $system_auth_file
	if [ $? -ne 0 ]; then
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
		info "$system_auth_file updated"
	fi

	safe chmod u+w $HOME
	mkdir -p $HOME/.ecryptfs

	info "Wrapping ecryptfs password"
	safe ecryptfs-wrap-passphrase $HOME/.ecryptfs/wrapped-passphrase
	safe touch $HOME/.ecryptfs/auto-mount

	echo "Setting user pam conf"
	safe cat << EOF > $HOME/.pam_mount.conf.xml
<pam_mount>
    <volume noroot="1" fstype="ecryptfs" path="$enc_root" mountpoint="$name"/>
</pam_mount>
EOF

	key=`head -n 1 $enc_sig`
	safe sudo sh -c "echo '$enc_root $name ecryptfs rw,user,noauto,exec,key=passphrase,ecryptfs_sig=$key,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_passthrough,ecryptfs_fnek_sig=$key,ecryptfs_unlink_sigs 0 0' >> /etc/fstab"
	debug "Fstab updated"

	safe chmod 500 $HOME
}

