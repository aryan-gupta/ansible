sync

umount /mnt/home -rf
umount /mnt/boot -rf
umount /mnt -rf

# lvchange -an /dev/mapper/kvm_lvg01-home
# lvchange -an /dev/mapper/kvm_lvg01-root
# vgchange -an kvm_lvg01

lvremove -ff kvm_lvg01-home
lvremove -ff kvm_lvg01-root
vgremove -ff kvm_lvg01
pvremove -y -ff /dev/mapper/kvm_crypt

dd if=/dev/zero of=/dev/mapper/kvm_crypt bs=1M count=16

cryptsetup close kvm_crypt
cryptsetup -q luksErase /dev/vda2
dmsetup remove kvm_crypt
dmsetup remove kvm_lvg01-home
dmsetup remove kvm_lvg01-root

dd if=/dev/zero of=/dev/vda2 bs=1M count=32
dd if=/dev/zero of=/dev/vda1 bs=1M count=16
dd if=/dev/zero of=/dev/vda  bs=1M count=16

rm -f /dev/mapper/kvm_crypt
rm -f /dev/vda1
rm -f /dev/vda2

lvmdiskscan
partprobe

# clear
lsblk