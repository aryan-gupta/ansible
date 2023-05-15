# remount cowspace so we can install ansible and git
# https://github.com/zxiiro/ansible-arch-install

WIFI_NAME=""

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo "./setup.sh HOSTNAME"
    exit 1
fi

if [ $1 = "boson" ]; then
	iwctl station wlan0 scan
	sleep 2
	iwctl station wlan0 connect $WIFI_NAME
	sleep 2
	if ping -c 1 8.8.8.8
	then
		echo "Connected"
	else
		exit 1
	fi
fi

mount -o remount,size=1G /run/archiso/cowspace

pacman -Sy ansible-core ansible git efibootmgr --needed --noconfirm

ansible-playbook playbook.yml --extra-vars "hostname=$1"


# install dotfiles:
# ansible-playbook playbook.yml --tags "user" --extra-vars="hostname=$1"
# ansible-playbook playbook.yml --tags "user" --extra-vars="hostname=$1" --check