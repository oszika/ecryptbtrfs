# ecryptbtrfs #
Using encryption over btrfs

## Selected scheme ##
This solution uses ecryptfs filesystem over btrfs subvolume:
  * <.volname>: btrfs subvolume
  * <.volname.ecryptfs>: ecryptfs root
  * <volname>: ecryptfs mount path

## Create encrypted volume ##
```
$ ecryptbtrfs.sh create /volumes/voltest
[info]	 Creating dir /volumes/voltest
[info]	 Creating subvolume /volumes/.voltest.ecryptfs
Create subvolume '/volumes/.voltest.ecryptfs'
Passphrase:
Passphrase: (verify)
[info]	 Adding to fstab
[info]	 Setting user rights (*user*)
```
