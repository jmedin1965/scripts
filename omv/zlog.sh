#!/bin/bash

# slog = 5 seconds worth of link speed = @ x 10gb = aboyt 13G or 10G
# l2arc = bigger and is just a read cache

zpool add rpool log   nvme-eui.00a07559d0000064-part1
zpool add rpool cache nvme-eui.00a07559d0000064-part2

#Disk /dev/nvme0n1: 232.89 GiB, 250059350016 bytes, 488397168 sectors
#Disk model: CT250P2SSD8                             
#Units: sectors of 1 * 512 = 512 bytes
#Sector size (logical/physical): 512 bytes / 512 bytes
#I/O size (minimum/optimal): 512 bytes / 512 bytes
#Disklabel type: dos
#Disk identifier: 0xef7c5534
#
#Device         Boot    Start       End   Sectors   Size Id Type
#/dev/nvme0n1p1          2048  20973567  20971520    10G bf Solaris
#/dev/nvme0n1p2      20973568 488397167 467423600 222.9G bf Solaris


