# Luks-Encrypt-Ubuntu-RPi-arm64
Scripts to luks encrypt the root partition of a 64-bit Ubuntu 19.10 Server installation for Raspberry Pi 3/4.

INSTALLATION

The following script prepares the environment by adding new applications to initramfs to make the job easier and prepares the needed files for LUKS

`sudo bash ./1.disk_encrypt.sh`

Make sure you see sbin/resize2fs, sbin/cryptsetup, and sbin/fdisk in the output. If it is not, run the above step again.

`sudo reboot`

Now we're going to be dropped to the initramfs shell, this is normal. In this shell, run the following commands.

`mkdir /tmp/boot`

`mount /dev/mmcblk0p1 /tmp/boot/`

The following script copies all your data to the flash drive because Luks deletes everything when it's encrypting the partition. At this point, make sure that you have your flash drive PLUGGED IN. As a side note, when LUKS encrypts the root partition it will ask you to type YES (in uppercase) then the decryption password twice (watch out if you used CAPS LOCK to type the YES), so add a new strong password to your liking. Finally, LUKS will ask for the decryption password again so we can copy the data back from the flash drive to the root partition.

`/tmp/boot/install/2.disk_encrypt_initramfs.sh`

`reboot -f`

We're dropped again to the initramfs, this is still normal

`mkdir /tmp/boot`

`mount /dev/mmcblk0p1 /tmp/boot/`

After running the following script, type in your decryption password again to unlock your drive. Once done, type "exit" to resume booting normally.

`/tmp/boot/install/3.luks_open.sh`

`exit`

Open a terminal window and execute the following command. At this point all the data is encrypted already, we just need to rebuild the initramfs.

`sudo bash /boot/firmware/install/4.rebuild_initram.sh`

From now on, you are now prompted for a password at boot.
