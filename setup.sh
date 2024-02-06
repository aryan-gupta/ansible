
if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo "./setup.sh HOSTNAME"
    exit 1
fi

if ping -c 1 "8.8.8.8"; then
    echo "Connected"
else
    # attempt to connect to the internet if possible
    iwctl station wlan0 scan
    sleep 5
    iwctl station wlan0 connect $(cat .network-ssid-secret)
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


git clone https://github.com/aryan-gupta/ansible /tmp/ansible
cd /tmp/ansible
pwd
git checkout develop
sleep 5
#
# =============== ANSIBLE ==================
#


# get the secrets we need
# https://stackoverflow.com/questions/369758
# do not set the user password until the end so this is not needed
# or set it to a temp password then set it to the actual password if ansible cant handle it
# move to ansible once we get the script working
user_password=$(awk -F ' ' '{print $2}' group_vars/all_secret.yml | head -1 | xargs echo -n)
#./secrets.sh $1


# WARNING: running this command will WIPE THE DISK
# ansible-playbook playbook.yml \
#     --tags "unmount, dd-lvm, dev-remove, dd-crypt, dms-remove, dd-disks" \
# 	--extra-vars "@group_vars/all_secret.yml" \
# 	--extra-vars "@host_vars/$1.yml"
	# --extra-vars "@group_vars/all.yml" \
./reset.sh $1

# run ansible playbook
mkdir -p logs/
export ANSIBLE_LOG_PATH="./logs/ansible-$(date +%Y-%m-%d-%H-%M-%s).log"
# echo "ansible-playbook playbook.yml $HOSTNAME_PARAM $BECOME_PARAM $EXVAR_PARAM $RESUME_PARAM"
#  ansible-playbook playbook.yml $RESUME_PARAM $BECOME_PARAM $EXVAR_PARAM $HOSTNAME_PARAM

if [ ! -z "$2" ]; then
    ansible-playbook playbook.yml \
        --start-at-task="$2"
        --extra-vars "ansible_become_pass=$user_password" \
        --extra-vars "@group_vars/all_secret.yml" \
        --extra-vars "@host_vars/$1.yml"
        # --extra-vars "@group_vars/all.yml" \
        # --extra-vars "hostname=$1"\
else
    ansible-playbook playbook.yml \
        --extra-vars "ansible_become_pass=$user_password" \
        --extra-vars "@group_vars/all_secret.yml" \
        --extra-vars "@host_vars/$1.yml"
        # --extra-vars "@group_vars/all.yml" \
        # --extra-vars "hostname=$1"\
fi
