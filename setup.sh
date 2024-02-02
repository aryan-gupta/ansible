
if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo "./setup.sh HOSTNAME"
    exit 1
fi

if ping -c 1 "8.8.8.8"; then
    echo "Connected"
else
    # attempt to connect to the internet if possible
    ./network.sh
    sleep 10

    # check if success, exit if not
    if ping -c 1 "8.8.8.8"; then
        echo "Connected"
    else
        echo "Please connect to the internet before running build script"
        exit 1
    fi
fi

# https://stackoverflow.com/questions/369758
user_password=$(awk -F ' ' '{print $2}' group_vars/all_secret.yml | head -1 | xargs echo -n)

# setup archiso boot
# remount cowspace so we can install ansible and git
# https://github.com/zxiiro/ansible-arch-install
mount -o remount,size=1G /run/archiso/cowspace
timedatectl set-timezone "America/New_York"

# WARNING: running this command will WIPE THE DISK
# move to ansible
./reset.sh $1

# init pacman and pacman keys
pacman-key --init
pacman-key --populate archlinux

# install packages we need
pacman -Sy ansible-core ansible git efibootmgr python python-passlib python-jinja python-yaml python-markupsafe --needed --noconfirm

HOSTNAME_PARAM=" --extra-vars 'hostname=$1' "
BECOME_PARAM=" --extra-vars 'ansible_become_pass=$user_password' " # @TODO needs to be removed
EXVAR_PARAM=" --extra-vars '@host_vars/$1.yml' --extra-vars '@group_vars/all_secret.yml' "
[ -z "$2" ] && RESUME_PARAM=" --start-at-task='$2' "

# run ansible playbook
export ANSIBLE_LOG_PATH="./logs/ansible-$(date +%Y-%m-%d-%H-%M-%s).log"
ansible-playbook playbook.yml $HOSTNAME_PARAM $BECOME_PARAM $EXVAR_PARAM $RESUME_PARAM
