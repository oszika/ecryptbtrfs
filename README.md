# ecryptbtrfs #
Using encryption over btrfs

## Selected scheme ##
This solution uses ecryptfs filesystem over btrfs subvolume:
  * \<volname\>: ecryptfs mount path
  * .\<volname\>.ecryptfs: btrfs subvolume
  * .\<volname\>.ecryptfs/root: ecryptfs root
  * .\<volname\>.ecryptfs/sig: key signature
  * /etc/fstab: used to mount home encrypted volumes

## Create encrypted volume ##
`$ ecryptbtrfs.sh create /volumes/voltest`
```
./ecryptbtrfs.sh create /volumes/voltest
Create subvolume '/volumes/.voltest.ecryptfs'
[debug]	 Subvolume /volumes/.voltest.ecryptfs created
[debug]	 Mount dir /volumes/voltest created
[debug]	 Ecryptfs root /volumes/.voltest.ecryptfs/root created
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

$ ls /volumes/.voltest.ecryptfs/root
ECRYPTFS_FNEK_ENCRYPTED.FWaEAm4HEfHTMUQRparKutvJjA2s-IhrvvEwRlFqpRonsgrxKUmz3XSAf---
```

## List encrypted volumes ##
`$ sudo ecryptbtrfs.sh list /`
```
ID 312 gen 4533 parent 5 top level 5 path volumes/voltest
```

## Take snapshot ##
`./ecryptbtrfs.sh snapshot -r /volumes/voltest /volumes/voltest.$(date +%Y-%m-%d-%H:%M:%S)`
```
Create a readonly snapshot of '/volumes/.voltest' in '/volumes/.voltest.2017-04-23-10:03:40.ecryptfs'
```

## Create home encrypted volume ##
You need to create encrypted volume using sudo to write on /home.
```
$ sudo ecryptbtrfs.sh create /home/toto
```

Reset owner
```
$ sudo chown -R toto /home/.toto
$ sudo chown -R toto /home/toto
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
