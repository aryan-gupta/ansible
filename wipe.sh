head -c 1052672 /dev/urandom > /dev/vda2
sync
dd if=/dev/zero of=/dev/vda bs=1K count=32
sync
reboot