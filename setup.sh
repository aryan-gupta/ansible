#!/bin/sh

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo "./setup.sh HOSTNAME"
    exit 1
fi


#
# =============== ANSIBLE ==================
#


# get the secrets we need
# https://stackoverflow.com/questions/369758
# do not set the user password until the end so this is not needed
# or set it to a temp password then set it to the actual password if ansible cant handle it
# move to ansible once we get the script working
user_password=$(grep "user_password" group_vars/all_secret.yml | awk -F ' ' '{print $2}' | head -1 | xargs echo -n)
#./scripts/secrets.sh $1


# WARNING: running this command will WIPE THE DISK
# ansible-playbook playbook.yml \
#     --tags "unmount, dd-lvm, dev-remove, dd-crypt, dms-remove, dd-disks" \
# 	--extra-vars "@group_vars/all_secret.yml" \
# 	--extra-vars "@host_vars/$1.yml"
	# --extra-vars "@group_vars/all.yml" \
./scripts/reset.sh $1

# run ansible playbook
mkdir -p logs/
export ANSIBLE_LOG_PATH="./logs/ansible-$(date +%Y-%m-%d-%H-%M-%s).log"
# echo "ansible-playbook playbook.yml $HOSTNAME_PARAM $BECOME_PARAM $EXVAR_PARAM $RESUME_PARAM"
#  ansible-playbook playbook.yml $RESUME_PARAM $BECOME_PARAM $EXVAR_PARAM $HOSTNAME_PARAM

if [ ! -z "$2" ]; then
    ansible-playbook playbook.yml \
        --start-at-task="$2" \
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
