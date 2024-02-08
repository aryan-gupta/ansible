#!/bin/sh

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo "./setup.sh HOSTNAME"
    exit 1
fi

# get the secrets we need
# https://stackoverflow.com/questions/369758
# do not set the user password until the end so this is not needed
# or set it to a temp password then set it to the actual password if ansible cant handle it
# move to ansible once we get the script working
secrets_file="/tmp/ansible/group_vars/all_secret.yml"
#./scripts/secrets.sh $1
echo "==============================================================="
echo "[ERROR]: $secrets_file doesnt exist."
echo "Waiting on secrets file."
echo "This will be removed when screts manegment"
echo "isnt scp'ing it into the test VM"
echo "==============================================================="
while [ ! -f "$secrets_file" ]
do
    sleep 5
done
user_password=$(grep "user_password" group_vars/all_secret.yml | awk -F ' ' '{print $2}' | head -1 | xargs echo -n)

# https://stackoverflow.com/questions/29436275
function yes_or_no {
    while true; do
        read -p "$* [y/N]: " yn
        case $yn in
            [Yy]*) return 0  ;;
            [Nn]*) echo "Did not do anything. Continuing..." ; return  1 ;;
            *)     echo "Did not do anything. Defaulting..."     ;  return 0  ;;
        esac
    done
}

# ansible-playbook playbook.yml \
#     --tags "unmount, dd-lvm, dev-remove, dd-crypt, dms-remove, dd-disks" \
# 	--extra-vars "@group_vars/all_secret.yml" \
# 	--extra-vars "@host_vars/$1.yml"
	# --extra-vars "@group_vars/all.yml" \
install_disk="$(grep "install_disk" host_vars/$1.yml | awk -F ' ' '{print $2}' | head -1 | xargs echo -n)"
echo "==============================================================="
echo "Install Disk: $install_disk"
echo "==============================================================="
# WARNING: running this command will WIPE THE DISK
yes_or_no "Do you want to WIPE THIS COMPUTER" && \
yes_or_no "One more time: DELETE ALL DATA on $install_disk?" && \
echo "Wiping... Bye..." && ./scripts/reset.sh $1

# run ansible playbook
mkdir -p logs/
export ANSIBLE_LOG_PATH="./logs/ansible-$(date +%Y-%m-%d-%H-%M-%s).log"

#
# method to the madness
# $1 should be the hostname
# $2 is the --start-at-task parameter so you can recover from failure quickly
# ${@:3} is the "there are the rest of the parameters I dont know what to do with"
# hopefully you can run this script in these ways:
#
# ./setup.sh default
# ./setup.sh default "START_AT_TASK"
# ./setup.sh default "START_AT_TASK" --extra-vars @extra_vars_file.yml
# ./setup.sh default "START_AT_TASK" --extra-vars @extra_vars_file1.yml --extra-vars @extra_vars_file2.yml
#
# this however is not tested
# ./setup.sh default "" --start-at-task="START_AT_TASK" --extra-vars @extra_vars_file.yml
#
# https://stackoverflow.com/questions/3811345/
#

if [ ! -z "$2" ]; then
    ansible-playbook playbook.yml \
        --start-at-task="$2" \
        --extra-vars "ansible_become_pass=$user_password" \
        --extra-vars "@group_vars/all_secret.yml" \
        --extra-vars "@host_vars/$1.yml" \
        --extra-vars "@group_vars/disks.yml" \
         "${@:3}"
        # --extra-vars "@group_vars/all.yml" \
        # --extra-vars "hostname=$1"\
else
    ansible-playbook playbook.yml \
        --extra-vars "ansible_become_pass=$user_password" \
        --extra-vars "@group_vars/all_secret.yml" \
        --extra-vars "@host_vars/$1.yml" \
        --extra-vars "@group_vars/disks.yml" \
         "${@:3}"
        # --extra-vars "@group_vars/all.yml" \
        # --extra-vars "hostname=$1"\
fi
