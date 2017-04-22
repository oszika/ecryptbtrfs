# ecryptbtrfs #
Using encryption over btrfs

## Selected scheme ##
This solution uses ecryptfs filesystem over btrfs subvolume:
  * \<volname\>: ecryptfs mount path
  * .\<volname\>.ecryptfs: btrfs subvolume & ecryptfs root
  * .\<volname\>.ecryptfs.conf: ecryptfs configuration
  * .\<volname\>.ecryptfs.sig: key signature
  * /etc/fstab: used to mount home encrypted volumes

## Create encrypted volume ##
`$ ecryptbtrfs.sh create /volumes/voltest`
```
Create subvolume '/volumes/.voltest.ecryptfs'
[debug]	 Subvolume /volumes/.voltest.ecryptfs created
[debug]	 Mount dir /volumes/voltest created
Passphrase:
Passphrase: (verify)
[debug]	 Ecryptfs configuration written
[debug]	 User rights setted (user)
```

## Mount/Umount encrypted volume ##
```
$ ecryptbtrfs.sh mount /volumes/voltest
$ ecryptbtrfs.sh umount /volumes/voltest
```

## Check encrypted volume ##
```
$ echo pouet > /volumes/voltest/pouet

$ ls /volumes/voltest/
/volumes/voltest/pouet

$ ls /volumes/.voltest.ecryptfs/
ECRYPTFS_FNEK_ENCRYPTED.FWaEAm4HEfHTMUQRparKutvJjA2s-IhrvvEwRlFqpRonsgrxKUmz3XSAf---
```

## List encrypted volumes ##
`$ sudo ecryptbtrfs.sh list /`
```
ID 312 gen 4533 parent 5 top level 5 path volumes/voltest
```

## Create home encrypted volume ##
You need to create encrypted volume using sudo to write on /home.
```
$ sudo ecryptbtrfs.sh create /home/toto
```

Reset owner
```
$ sudo chown toto /home/.toto.ecryptfs*
$ sudo chown toto /home/toto
```

Setting volume to be auto mounted at login
```
$ ecryptbtrfs.sh home /home/toto
```
```
[info]	 Wrapping ecryptfs password
Passphrase to wrap:
Wrapping passphrase:
Setting user pam conf
[debug]	 Fstab updated
```
