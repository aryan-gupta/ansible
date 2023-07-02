HOST="graviton"

sync

umount /mnt/home -rf
umount /mnt/boot -rf
umount /mnt -rf

# lvchange -an /dev/mapper/kvm_lvg01-home
# lvchange -an /dev/mapper/kvm_lvg01-root
# vgchange -an kvm_lvg01

lvremove -ff "$HOST""_lvg01-home"
lvremove -ff "$HOST""_lvg01-root"
vgremove -ff "$HOST""_lvg01"
pvremove -y -ff "/dev/mapper/""$HOST""_crypt"

dd if=/dev/zero of="/dev/mapper/""$HOST""_crypt" bs=1M count=16

cryptsetup close "$HOST""_crypt"
#cryptsetup -q luksErase /dev/nvme0n1p2
cryptsetup -q luksErase /dev/sda2
dmsetup remove "$HOST""_crypt"
dmsetup remove "$HOST""_lvg01-home"
dmsetup remove "$HOST""_lvg01-root"

#dd if=/dev/zero of=/dev/nvme0n1p2 bs=1M count=32
#dd if=/dev/zero of=/dev/nvme0n1p1 bs=1M count=16
#dd if=/dev/zero of=/dev/nvme0n1  bs=1M count=16
dd if=/dev/zero of=/dev/sda  bs=1M count=1024

rm -f "/dev/mapper/""$HOST""_crypt"
#rm -f /dev/nvme0n1p1
#rm -f /dev/nvme0n1p2

lvmdiskscan
partprobe

# clear
lsblk
