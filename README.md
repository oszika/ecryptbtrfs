# ecryptbtrfs #
Using encryption over btrfs

## Selected scheme ##
This solution uses ecryptfs filesystem over btrfs subvolume:
  * \<.volname.ecryptfs\>: btrfs subvolume & ecryptfs root
  * \<volname\>: ecryptfs mount path

## Create encrypted volume ##
`$ ecryptbtrfs.sh create /volumes/voltest`
```
[info]	 Creating dir /volumes/voltest
[info]	 Creating subvolume /volumes/.voltest.ecryptfs
Create subvolume '/volumes/.voltest.ecryptfs'
Passphrase:
Passphrase: (verify)
[info]	 Adding to fstab
[info]	 Setting user rights (*user*)
```

## Mount encrypted volume ##
`$ ecryptbtrfs.sh mount /volumes/voltest`

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
