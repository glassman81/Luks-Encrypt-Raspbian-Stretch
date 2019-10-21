#!/bin/sh

#mkdir /tmp/boot
#mount /dev/mmcblk0p1 /tmp/boot/
#/tmp/boot/install/3.disk_encrypt_initramfs.sh

e2fsck -f /dev/mmcblk0p2
resize2fs -fM /dev/mmcblk0p2

BLOCK_COUNT="$(dumpe2fs /dev/mmcblk0p2 | sed "s/ //g" | sed -n "/Blockcount:/p" | cut -d ":" -f 2)"
echo "Block count: $BLOCK_COUNT"
SHA1SUM_ROOT="$(dd bs=4k count=$BLOCK_COUNT if=/dev/mmcblk0p2 | sha1sum)"
dd bs=4k count=$BLOCK_COUNT if=/dev/mmcblk0p2 of=/dev/sda
SHA1SUM_EXT="$(dd bs=4k count=$BLOCK_COUNT if=/dev/sda | sha1sum)"

if [ "$SHA1SUM_ROOT" == "$SHA1SUM_EXT" ]; then
	echo "1.Sha1sums match."
	cryptsetup --cipher aes-cbc-essiv:sha256 luksFormat /dev/mmcblk0p2
	cryptsetup luksOpen /dev/mmcblk0p2 sdcard
	dd bs=4k count=$BLOCK_COUNT if=/dev/sda of=/dev/mapper/sdcard
	NEWBLOCK_COUNT="$(dumpe2fs /dev/mapper/sdcard | sed "s/ //g" | sed -n "/Blockcount:/p" | cut -d ":" -f 2)"
	SHA1SUM_NEWROOT="$(dd bs=4k count=$NEWBLOCK_COUNT if=/dev/mapper/sdcard | sha1sum)"
	if [ "$SHA1SUM_NEWROOT" == "$SHA1SUM_EXT" ]; then
		echo "2.Sha1sums match."
		e2fsck -f /dev/mapper/sdcard
		resize2fs -f /dev/mapper/sdcard
		echo "Done. Reboot and rebuild initramfs."
		#poweroff -f
		#reboot -f
	else
		echo "2.Sha1sums error."
	fi
else
	echo "1.Sha1sums error."
fi
