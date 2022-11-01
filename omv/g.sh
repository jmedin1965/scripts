

ls /dev/sde3 
ls /dev/disk/by-id/scsi-35000c500ed7b5d81-part3
zpool offline rpool /dev/sde3 
zpool replace -f rpool /dev/sde3 /dev/disk/by-id/scsi-35000c500ed7b5d81-part3
