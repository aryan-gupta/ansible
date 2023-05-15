HOST="boson"

sync

umount /mnt/home -rf
umount /mnt/boot -rf
umount /mnt -rf

# lvchange -an /dev/mapper/kvm_lvg01-home
# lvchange -an /dev/mapper/kvm_lvg01-root
# vgchange -an kvm_lvg01

lvremove -ff boson_lvg01-home
lvremove -ff boson_lvg01-root
vgremove -ff boson_lvg01
pvremove -y -ff /dev/mapper/boson_crypt

dd if=/dev/zero of=/dev/mapper/boson_crypt bs=1M count=16

cryptsetup close boson_crypt
cryptsetup -q luksErase /dev/nvme0n1p2
dmsetup remove boson_crypt
dmsetup remove boson_lvg01-home
dmsetup remove boson_lvg01-root

dd if=/dev/zero of=/dev/nvme0n1p2 bs=1M count=32
dd if=/dev/zero of=/dev/nvme0n1p1 bs=1M count=16
dd if=/dev/zero of=/dev/nvme0n1  bs=1M count=16

rm -f /dev/mapper/boson_crypt
rm -f /dev/nvme0n1p1
rm -f /dev/nvme0n1p2

lvmdiskscan
partprobe

# clear
lsblk