#!/bin/sh

# =========================================================================================
# ===================================== VARS ==============================================
# =========================================================================================

ram_area='/tmp' # or /dev/shm

server='gitea.gempi.re'
# server='github.com'
export GIT_SSL_NO_VERIFY=true

this_repo="https://$server/aryan-gupta/ansible"
repo_path="$ram_area/ansible"

secret_repo="https://$server/aryan-gupta/ansible-secrets" # pragma: allowlist secret
secret_repo_path="$ram_area/ansible/ansible-secrets"

gpg_enc_key="$secret_repo_path/E009B402.sub.key.asc"
secrets_file="$secret_repo_path/all_secret.yml"

ansible_log_path="$repo_path/logs/ansible-$(date +%Y-%m-%d-%H-%M-%s).log"

# =========================================================================================
# ===================================== ARGS ==============================================
# =========================================================================================

function help {
    echo "========================= Usage ==============================="
    echo "\$INVOCATION hostname [ --additional-arguments=\"ARGS\" ]"
    echo "LOCAL: "
    echo "./setup.sh hostname [ --additional-arguments=\"ARGS\" ]"
    echo "WEBSTRAP: "
    echo "sh -c \"\$(curl -fsSL \$URL)\" hostname [ --additional-arguments=\"ARGS\" ]"
    echo "========================= Usage ==============================="
}

if [[ "$0" == *".sh" ]]; then
    echo "[INFO] Welcome to the LOCAL ansible installer"
    [ -z "$1" ] && echo "[ERROR] No arguments" && help && exit 1
    [[ $1 == "-"* ]]  && echo "[ERROR] No hostname" && help && exit 1
    host=$1
    shift # removes the hostname so the rest of the args can be passed to ansible
else
    echo "[INFO] Welcome to the WEBSTRAP ansible installer"
    [ -z "$0" ] && echo "[ERROR] No arguments" && help && exit 1
    [[ $0 == "-"* ]]  && echo "[ERROR] No hostname" && help && exit 1
    host=$0
fi

echo "[INFO] Using hostname: $host"

# =========================================================================================
# ===================================== NET ===============================================
# =========================================================================================

if ping -c 1 "8.8.8.8" > /dev/null; then
    echo "[INFO] Connected to the Internet"
else
    # attempt to connect to the internet if possible
    iwctl station wlan0 scan
    sleep 5
    echo -n "[ASK] Network Name: "
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

# =========================================================================================
# ===================================== ARCHISO ===========================================
# =========================================================================================

# setup archiso boot
# remount cowspace so we can install ansible and git
# https://github.com/zxiiro/ansible-arch-install
echo "[INFO] Remounting COWspace"
mount -o remount,size=2G /run/archiso/cowspace

echo "[INFO] Updating Time..."
timedatectl set-timezone "America/New_York"
timedatectl set-ntp true
sleep 10
timedatectl # verify date is correct for keys below

# init pacman and pacman keys
echo "[INFO] Updating pacman keys"
pacman-key --init
pacman-key --populate archlinux

# install packages we need
echo "[INFO] Installing packages"
pacman -Sy ansible-core ansible git efibootmgr python python-passlib bitwarden-cli python-markupsafe --needed --noconfirm

# =========================================================================================
# ===================================== GIT ===============================================
# =========================================================================================

if [ ! -d "$repo_path" ]; then
    echo "[INFO] Git repo not found. Cloning."
    git clone $this_repo $repo_path
fi

echo "[INFO] Entering git repo"
cd $repo_path
echo "[INFO] Checking out testing branch"
git checkout testing

# =========================================================================================
# ===================================== SECRETS ===========================================
# =========================================================================================

if [ ! -d "$secret_repo_path" ]; then
    echo "[INFO] Git repo **ansible-secrets** not found. Cloning."
    git clone $secret_repo $secret_repo_path
fi

cd $secret_repo_path

echo "[ASK] Please login to bitwarden for secret extraction"
bw logout
export BW_SESSION=$(bw login --raw)

# these bitwarden id's are not secrets, are they?
# access to the UUID does not reveal the encrypted password data
# https://stackoverflow.com/questions/61742196/
# https://security.stackexchange.com/questions/4729/
# https://security.stackexchange.com/questions/36870/
echo "[INFO] Decrypting gpg key"
ansible_secrets_key=$(bw get password 9d9cf34b-936d-434c-ba58-b144014f323e)
gpg --batch --passphrase $ansible_secrets_key --decrypt --output $gpg_enc_key $( basename $gpg_enc_key ).sym.gpg

echo "[INFO] Importing gpg key"
gnupg_password=$(bw get password 6d69ae1b-9f81-42fb-be10-acd8016bdb33)
gpg --batch --passphrase $gnupg_password --import $gpg_enc_key

echo "[INFO] Decrypting files"
cd $secret_repo_path
./decrypt_all.sh $gnupg_password

echo "[INFO] Changing directory to main repo"
cd $repo_path

# =========================================================================================
# ===================================== LOGS ==============================================
# =========================================================================================

# run ansible playbook
mkdir -p logs/
export ANSIBLE_LOG_PATH=$ansible_log_path
echo "[INFO] Setup logging"

# =========================================================================================
# ===================================== WIPE ==============================================
# =========================================================================================

if [[ "$*" == *"wipe"* ]]; then
    echo "[INFO] Wipe command was passed into CLI args, will not ask for wipe"
else
    # https://stackoverflow.com/questions/29436275
    function yes_or_no {
        while true; do
            read -p "$* [y/N]: " yn
            case $yn in
                [Yy]*) return 0  ;;
                [Nn]*) echo "[INFO] Did not do anything. Continuing..." ; return 1 ;;
                *)     echo "[INFO] Did not do anything. Defaulting..." ; return 1 ;;
            esac
        done
    }

    install_disk="$(grep "install_disk" host_vars/$host.yml | awk -F ' ' '{print $2}' | head -1 | xargs echo -n)"
    echo "==============================================================="
    echo "[INFO] Install Disk: $install_disk"
    echo "==============================================================="
    # WARNING: running this command will WIPE THE DISK
    yes_or_no "[ASK] Do you want to WIPE THIS COMPUTER"      && \
    yes_or_no "[ASK] One more time: DELETE ALL DATA on $install_disk?" && \
    echo "[WARN] Wiping... Bye..." && \
    ansible-playbook archiso.yml \
        --extra-vars "@$secrets_file" \
        --extra-vars "@host_vars/$host.yml" \
        --extra-vars '{"wipe":true}' --tags="wipe" ${@:1}

    echo "[INFO] Wiped"
    lsblk
fi

# =========================================================================================
# ===================================== RUN ===============================================
# =========================================================================================

#
# "${@:2}" passes the 2rd argument onwards to ansible
# allows you to do
#
# > ./setup.sh default --start-at-task="START_AT_TASK"
# > ./setup.sh default --extra-vars="var_name=var_value"
#
# https://stackoverflow.com/questions/3811345/
#
## @TODO remove ansible_become_pass
# @TODO convert all_secrets.yml to simply secrets.yml
# @TODO test other disk provisioning schemas
#

ansible-playbook archiso.yml \
    --extra-vars "{\"gnupg_password\":\"$gnupg_password\"}" \
    --extra-vars "@$secrets_file" \
    --extra-vars "@host_vars/$host.yml" ${@:1}
