# remount cowspace so we can install ansible and git
# https://github.com/zxiiro/ansible-arch-install

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo "./setup.sh HOSTNAME"
    exit 1
fi

mount -o remount,size=1G /run/archiso/cowspace

pacman -Sy ansible git efibootmgr --needed --noconfirm

ansible-playbook playbook.yml --extra-vars "hostname=$1"