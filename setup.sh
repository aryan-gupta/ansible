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
user_password=$(grep "user_password" group_vars/all_secret.yml | awk -F ' ' '{print $2}' | head -1 | xargs echo -n)
#./scripts/secrets.sh $1

# https://stackoverflow.com/questions/29436275
function yes_or_no {
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) return 0  ;;
            [Nn]*) echo "Aborted" ; return  1 ;;
        esac
    done
}

# WARNING: running this command will WIPE THE DISK
# ansible-playbook playbook.yml \
#     --tags "unmount, dd-lvm, dev-remove, dd-crypt, dms-remove, dd-disks" \
# 	--extra-vars "@group_vars/all_secret.yml" \
# 	--extra-vars "@host_vars/$1.yml"
	# --extra-vars "@group_vars/all.yml" \
yes_or_no "Do you want to WIPE THIS COMPUTER [y/n]"     && \
    yes_or_no "One more time: DELETE ALL DATA? [y/n]" && \
    ./scripts/reset.sh $1

# run ansible playbook
mkdir -p logs/
export ANSIBLE_LOG_PATH="./logs/ansible-$(date +%Y-%m-%d-%H-%M-%s).log"
if [ ! -z "$2" ]; then
    # https://stackoverflow.com/questions/3811345/
    ansible-playbook playbook.yml \
        --start-at-task="$2" \
        --extra-vars "ansible_become_pass=$user_password" \
        --extra-vars "@group_vars/all_secret.yml" \
        --extra-vars "@host_vars/$1.yml" "${@:3}"
        # --extra-vars "@group_vars/all.yml" \
        # --extra-vars "hostname=$1"\
else
    ansible-playbook playbook.yml \
        --extra-vars "ansible_become_pass=$user_password" \
        --extra-vars "@group_vars/all_secret.yml" \
        --extra-vars "@host_vars/$1.yml" "${@:3}"
        # --extra-vars "@group_vars/all.yml" \
        # --extra-vars "hostname=$1"\
fi
