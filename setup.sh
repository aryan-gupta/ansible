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
    echo -n "."
    sleep 5
done
echo ""
echo "Found secrets file. Continuing..."
user_password=$(grep "user_password" group_vars/all_secret.yml | awk -F ' ' '{print $2}' | head -1 | xargs echo -n)

# https://stackoverflow.com/questions/29436275
function yes_or_no {
    while true; do
        read -p "$* [y/N]: " yn
        case $yn in
            [Yy]*) return 0  ;;
            [Nn]*) echo "Did not do anything. Continuing..." ; return 1 ;;
            *)     echo "Did not do anything. Defaulting..." ; return 0 ;;
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
yes_or_no "[WARNING] Do you want to WIPE THIS COMPUTER"      && \
yes_or_no "One more time: DELETE ALL DATA on $install_disk?" && \
echo "Wiping... Bye..." && ./scripts/reset.sh $1

# run ansible playbook
mkdir -p logs/
export ANSIBLE_LOG_PATH="./logs/ansible-$(date +%Y-%m-%d-%H-%M-%s).log"

#
# "${@:3}" passes the 3rd argument onwards to ansible
# allows you to do
#
# > ./setup.sh default --start-at-task="START_AT_TASK"
#
# https://stackoverflow.com/questions/3811345/
#
## @TODO remove ansible_become_pass
# @TODO convert all_secrets.yml to simply secrets.yml
# @TODO test other disk provisioning schemas
#

ansible-playbook playbook.yml \
    --extra-vars "ansible_become_pass=$user_password" \
    --extra-vars "@group_vars/all_secret.yml" \
    --extra-vars "@host_vars/$1.yml" \
    --extra-vars "@group_vars/disks.yml" \
        "${@:3}"
