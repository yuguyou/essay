查看硬盘UUID:
```
ls -l /dev/disk/by-uuid/
```

查看挂载数据
```
mount -l
```

挂载刷新
```
mount -a
```

编辑fstab
```
# /dev/sda9
UUID=24871dd3-d131-4144-9e69-f609bfe4a334	/         	ext4      	rw,relatime	0 1

# /dev/sda4
UUID=B9CD-5A6F      	/boot     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2

# /dev/sda11
UUID=4e5a93db-12e9-47f6-b020-03514d3d92c2	/home     	ext4      	rw,relatime	0 2

# /dev/sda10
UUID=a23ffbc4-b4a2-4b9f-bf2e-fc7b640df7a9	none      	swap      	defaults  	0 0

# /dev/sda1 00081974000B332D
# UUID=00081974000B332D /media/c ntfs-3g defaults,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000,windows_names 0 0
UUID=00081974000B332D /media/c ntfs-3g defaults,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000 0 0
# /dev/sda3 0000AAB50001D50D
UUID=0000AAB50001D50D /media/d ntfs-3g defaults,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000 0 0
# /dev/sda5 000571390003ABE6
UUID=000571390003ABE6 /media/e ntfs-3g defaults,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000 0 0
# /dev/sda6 00040F14000792B6
UUID=00040F14000792B6 /media/f ntfs-3g defaults,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000 0 0
# /dev/sda7 ECF4A943F4A910BE
UUID=ECF4A943F4A910BE /media/g ntfs-3g defaults,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000 0 0
# /dev/sda8 362C3A362C39F18B
UUID=362C3A362C39F18B /media/h ntfs-3g defaults,nls=utf8,umask=000,dmask=027,fmask=137,uid=1000,gid=1000 0 0
```
