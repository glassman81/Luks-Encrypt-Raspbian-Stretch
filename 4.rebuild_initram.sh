#!/bin/sh

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

mkinitramfs -o /boot/firmware/initrd.img
lsinitramfs /boot/firmware/initrd.img |grep -P "sbin/(cryptsetup|resize2fs|fdisk|dumpe2fs|expect|sha1sum)"
lsinitramfs /boot/firmware/initrd.img | grep -P "bin/(sha1sum)"

# As before, we're overwriting the default backup location of initrd
INITRDBAK="$(ls /boot/initrd.img-*)"
cp /boot/firmware/initrd.img $INITRDBAK
