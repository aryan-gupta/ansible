#!/bin/sh

HOST="$1"

sync

umount /mnt/home -rf
umount /mnt/data -rf
umount /mnt/boot -rf
umount /mnt/efi -rf
umount /mnt/var -rf
umount /mnt -rf

LVM="_lv"
lvremove -ff "$HOST""$LVM""-home"
lvremove -ff "$HOST""$LVM""-data"
lvremove -ff "$HOST""$LVM""-root"
lvremove -ff "$HOST""$LVM""-var"
vgremove -ff "$HOST""$LVM"""
pvremove -y -ff "/dev/mapper/""$HOST""_crypt"

dd if=/dev/zero of="/dev/mapper/""$HOST""_crypt" bs=1M count=32

cryptsetup close "$HOST""_crypt"
dmsetup remove "$HOST""$LVM""-home"
dmsetup remove "$HOST""$LVM""-data"
dmsetup remove "$HOST""$LVM""-root"
dmsetup remove "$HOST""$LVM""-var"
dmsetup remove "$HOST""_crypt"
rm -f "/dev/mapper/""$HOST""_crypt"

install_disk=$(grep "install_disk" host_vars/$HOST.yml | awk -F ' ' '{print $2}' | head -1 | xargs echo -n)
part_postfix=$(grep "part_postfix" host_vars/$HOST.yml | awk -F ' ' '{print $2}' | head -1 | xargs echo -n)

dd if=/dev/zero of="$install_disk$part_postfix""1"  bs=1M count=32
dd if=/dev/zero of="$install_disk$part_postfix""2"  bs=1M count=32
dd if=/dev/zero of="$install_disk$part_postfix"     bs=1M count=32

rm -f "$install_disk$part_postfix""1"
rm -f "$install_disk$part_postfix""2"

lvmdiskscan
partprobe

# clear
lsblk
