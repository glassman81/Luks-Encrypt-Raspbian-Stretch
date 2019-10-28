#https://github.com/johnshearing/MyEtherWalletOffline/blob/master/Air-Gap_Setup.md#setup-luks-full-disk-encryption
#https://robpol86.com/raspberry_pi_luks.html
#https://www.howtoforge.com/automatically-unlock-luks-encrypted-drives-with-a-keyfile

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

apt-get install busybox-static cryptsetup initramfs-tools -y
apt-get install expect --no-install-recommends -y
apt-get autoremove -y
cp /boot/firmware/install/initramfs-rebuild /etc/kernel/postinst.d/initramfs-rebuild
cp /boot/firmware/install/resize2fs /etc/initramfs-tools/hooks/resize2fs
chmod +x /etc/kernel/postinst.d/initramfs-rebuild
chmod +x /etc/initramfs-tools/hooks/resize2fs

echo 'CRYPTSETUP=y' | tee --append /etc/cryptsetup-initramfs/conf-hook > /dev/null
mkinitramfs -o /boot/firmware/initrd.img

# The above was likely the first time mkinitramfs was invoked, so the following
# statement will overwrite the unwanted Ubuntu default backup if it exists
INITRDBAK="$(ls /boot/initrd.img-*)"
if [ -z "$INITRDBAK" ]; then
   cp /boot/firmware/initrd.img /boot/initrd.img.old
else
   cp /boot/firmware/initrd.img $INITRDBAK
fi

lsinitramfs /boot/firmware/initrd.img | grep -P "sbin/(cryptsetup|resize2fs|fdisk|dumpe2fs|expect|sha1sum)"
lsinitramfs /boot/firmware/initrd.img | grep -P "bin/(sha1sum)"
#Make sure you see sbin/resize2fs, sbin/cryptsetup, and sbin/fdisk in the output.

echo 'initramfs initrd.img followkernel' | tee --append /boot/firmware/usercfg.txt > /dev/null

sed -i '$s/$/ cryptdevice=\/dev\/mmcblk0p2:sdcard/' /boot/firmware/nobtcmd.txt
sed -i '$s/$/ cryptdevice=\/dev\/mmcblk0p2:sdcard/' /boot/firmware/btcmd.txt

ROOT_CMD="$(sed -n 's|^.*root=\(\S\+\)\s.*|\1|p' /boot/firmware/nobtcmd.txt)"
sed -i -e "s|$ROOT_CMD|/dev/mapper/sdcard|g" /boot/firmware/nobtcmd.txt
sed -i -e "s|$ROOT_CMD|/dev/mapper/sdcard|g" /boot/firmware/btcmd.txt

FSTAB_CMD="$(blkid | sed -n '/dev\/mmcblk0p2/s/.*\ PARTUUID=\"\([^\"]*\)\".*/\1/p')"
sed -i -e "s|PARTUUID=$FSTAB_CMD|/dev/mapper/sdcard|g" /etc/fstab

echo 'sdcard /dev/mmcblk0p2 none luks' | tee --append /etc/crypttab > /dev/null

echo "Done. Reboot with: sudo reboot"
