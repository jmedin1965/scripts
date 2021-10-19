#!/bin/bash

prog="esptool.py"
dev="/dev/ttyUSB0"
ver="6.5.0"
ver="9.5.0"
type="sonoff.bin"
type="tasmota.bin"
save="image1M.bin"

ans=""

while [ "$ans" != q ]
do

        echo "

dev = $dev

s) save flash to $save
e) erase flash
f) flash with $ver/$type

q) quit
"
        echo -n "which ? "
        read ans

        case "$ans" in
        s)      $prog --port $dev read_flash 0x00000 0x100000 $save;;
        e)      $prog --port $dev erase_flash;;
        f)      $prog --port $dev write_flash -fs 1MB -fm dout 0x0 $ver/$type;;
        esac
done

echo bye

exit 0
esptool.py --port $dev erase_flash

dev=/dev/ttyUSB0
ver=6.5
esptool.py --port $dev write_flash -fs 1MB -fm dout 0x0 $ver/sonoff.bin

dev=/dev/ttyUSB0

esptool.py --port $dev read_flash 0x00000 0x100000 image1M.bin
