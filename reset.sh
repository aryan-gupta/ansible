#HOST="graviton"
HOST="$1"

sync

umount /mnt/home -rf
umount /mnt/data -rf
umount /mnt/boot -rf
umount /mnt/efi -rf
umount /mnt/var -rf
umount /mnt -rf

# lvchange -an /dev/mapper/kvm_lvg01-home
# lvchange -an /dev/mapper/kvm_lvg01-root
# vgchange -an kvm_lvg01

LVM="_lv"

lvremove -ff "$HOST""$LVM""-home"
lvremove -ff "$HOST""$LVM""-data"
lvremove -ff "$HOST""$LVM""-root"
lvremove -ff "$HOST""$LVM""-var"
vgremove -ff "$HOST""$LVM"""
pvremove -y -ff "/dev/mapper/""$HOST""_crypt"

dd if=/dev/zero of="/dev/mapper/""$HOST""_crypt" bs=1M count=32

cryptsetup close "$HOST""_crypt"
#cryptsetup -q luksErase /dev/nvme0n1p2
#cryptsetup -q luksErase /dev/nvme0n1p2
#cryptsetup -q luksErase /dev/sda2
dmsetup remove "$HOST""$LVM""-home"
dmsetup remove "$HOST""$LVM""-data"
dmsetup remove "$HOST""$LVM""-root"
dmsetup remove "$HOST""$LVM""-var"
dmsetup remove "$HOST""_crypt"

# dd if=/dev/zero of=/dev/nvme0n1p2 bs=1M count=32
# dd if=/dev/zero of=/dev/nvme0n1p1 bs=1M count=32
# dd if=/dev/zero of=/dev/nvme0n1  bs=1M count=32
#dd if=/dev/zero of=/dev/sda  bs=1M count=1024
dd if=/dev/zero of=/dev/vda2  bs=1M count=32
dd if=/dev/zero of=/dev/vda1  bs=1M count=32
dd if=/dev/zero of=/dev/vda  bs=1M count=32

rm -f "/dev/mapper/""$HOST""_crypt"
# rm -f /dev/nvme0n1p1
# rm -f /dev/nvme0n1p2
rm -f /dev/vda1
rm -f /dev/vda2

lvmdiskscan
partprobe

# clear
lsblk
