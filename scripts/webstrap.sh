#!/bin/sh

this_repo="https://github.com/aryan-gupta/ansible"
repo_path="/tmp/ansible"
secrets_file="/tmp/ansible/group_vars/all_secret.yml"

if [ $# -eq 0 ]; then
    echo -n "Host Name: "
    read host
fi

if ping -c 1 "8.8.8.8"; then
    echo "Connected"
else
    # attempt to connect to the internet if possible
    iwctl station wlan0 scan
    sleep 5
    echo -n "Network Name: "
    read network
    iwctl station wlan0 connect $network
    sleep 10

    # check if success, exit if not
    if ping -c 1 "8.8.8.8"; then
        echo "Connected"
    else
        echo "Please connect to the internet before running build script"
        exit 1
    fi
fi

# setup archiso boot
# remount cowspace so we can install ansible and git
# https://github.com/zxiiro/ansible-arch-install
mount -o remount,size=1G /run/archiso/cowspace
timedatectl set-timezone "America/New_York"
sleep 10
timedatectl # verify date is correct for keys below

# init pacman and pacman keys
pacman-key --init
pacman-key --populate archlinux

# install packages we need
pacman -Sy ansible-core ansible git efibootmgr python python-passlib python-jinja python-yaml python-markupsafe --needed --noconfirm

git clone $this_repo $repo_path
cd $repo_path

while [ ! -f "$secrets_file" ]
do
    echo "[ERROR]: $secrets_file doesnt exist."
    echo "Waiting on secrets file."
    echo "This will be removed when screts manegment"
    echo "isnt scp'ing it into the test VM"
    echo "sleeping 5 more seconds"
    echo "\n\n\n"
    sleep 5

done

# if we are in a ssh shell, then delete the password (as a test)
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  SESSION_TYPE=remote/ssh
# many other tests omitted
else
  case $(ps -o comm= -p "$PPID") in
    sshd|*/sshd) SESSION_TYPE=remote/ssh;;
  esac
fi

if [ "$SESSION_TYPE" = "remote/ssh" ]; then
    passwd -d `whoami`
fi

./setup.sh $host
