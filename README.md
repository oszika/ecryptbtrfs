# ebtrfs/efs #
Using encryption over btrfs (or any filesystem without snapshot feature)

## Selected scheme ##
This solution uses ecryptfs filesystem over btrfs subvolume:
  * \<volname\>: ecryptfs mount path
  * .\<volname\>.ecryptfs: btrfs subvolume (or simple dir)
  * .\<volname\>.ecryptfs/root: ecryptfs root
  * .\<volname\>.ecryptfs/sig: key signature
  * /etc/fstab: used to mount home encrypted volumes

## Scripts ##
  * ebtrfs: ecryptfs over btrfs
  * efs: ecryptfs over any filesystem
With ebtrfs, subvolumes are encrypted. Otherwise, a simple dir is used.

## Create encrypted volume ##
`$ ebtrfs create /volumes/voltest`
```
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
$ ebtrfs mount /volumes/voltest
$ ebtrfs umount /volumes/voltest
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
`$ sudo ebtrfs list /`
```
ID 312 gen 4533 parent 5 top level 5 path volumes/voltest
```

## Take snapshot ##
`ebtrfs snapshot -r /volumes/voltest /volumes/voltest.$(date +%Y-%m-%d-%H:%M:%S)`
```
Create a readonly snapshot of '/volumes/.voltest' in '/volumes/.voltest.2017-04-23-10:03:40.ecryptfs'
```

## Create home encrypted volume ##
You need to create encrypted volume using sudo to write on /home.
```
$ sudo ebtrfs create /home/toto
```

Reset owner
```
$ sudo chown -R toto /home/.toto
$ sudo chown -R toto /home/toto
```

Setting volume to be auto mounted at login
```
$ ebtrfs home /home/toto
```
```
[info]	 Wrapping ecryptfs password
Passphrase to wrap:
Wrapping passphrase:
Setting user pam conf
[debug]	 Fstab updated
```
