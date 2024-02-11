# ansible
An Ansible Playbook to setup my Linux machines. From the platform of Arch linux and wanting to automate my install was born this project. [btw, I use Arch](https://i.kym-cdn.com/photos/images/original/002/243/383/c00.png)

## Installing
Boot into the archiso, connect to the internet, and run this command to start the install. It will ask you if you want to wipe the disk.

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aryan-gupta/ansible/master/scripts/webstrap.sh)" "default"
```

### Options
- Replace `/master/` in the URL to `/develop/` switch to develop branch
- The first argument specifies the hostname. See `host_vars/*` for available options.
- The disk style can be changed using these extra arguments. `-e` is short for `--extra-vars`
  - `-e '{"nocrypt":false, "nolvm":false}'` : Redundantly specify default config
  - `-e '{"nocrypt":true}'`                 : Do not setup luks
  - `-e '{"nolvm":true}'`                   : Do not setup LVM
  - `-e '{"nocrypt":true, "nolvm":true}'`   : Do not setup luks or LVM
- The `--start-at-task` argument can be used to resume playbook after resolving an failure

```shell
WEBSTRAP_URL='https://raw.githubusercontent.com/aryan-gupta/ansible/develop/scripts/webstrap.sh'
sh -c "$(curl -fsSL $WEBSTRAP_URL)" "default" -e '{"nocrypt":true}'
sh -c "$(curl -fsSL $WEBSTRAP_URL)" "boson" --start-at-task="Check if in UEFI mode"
sh -c "$(curl -fsSL $WEBSTRAP_URL)" "graviton" --extra-vars '{"nocrypt":true}' --start-at-task="Check if in UEFI mode"
```

## Features
### Base
- Arch linux

  I have always loved the Arch linux philosphy.

  > The default installation is a minimal base system, configured by the user to only add what is purposely required.

  Only install the bare necessities. From a person who came from M$ Windows, bloatware and unnessary garbage was always a large pet peave of mine. I still run Windows debloating scripts on my gaming system.

- Ansible

  This project is written in Ansible. It seems the best tool for the job and if a better tool comes along, hopefully porting it to another language (other than ansible yaml) not too difficult to do and debug.

### Boot
- UEFI Secureboot

  Instal contains two partitions. A efi partition with two items (signed boot image and a random-seed from systemd). The second partion is encrypted with LUKS (below). The kernel is verified by both the motherboard (TPM) and sbctl on boot (via a script). Any change to the boot image will notify the user.

- Linux UKI Image

  Install creates a single signed image that contains the kernel, initramfs, microcode and commandline params. Please note there is NO fallback image. Only one default image is created. A fallback kernel is TBD if needed at all (and will most likley be non-signed or something if I do it).

- Plymouth

  For a relatively seamless boot experience. There are issued but I belive its [issues](https://blogs.gnome.org/halfline/2009/11/28/plymouth-%E2%9F%B6-x-transition/) of other systems and their compatibility with this style of eyecandy. Please be aware of a current security issue with my implementation (the plymouth non-daemon program is nopasswd in sudoers to fix an issue and will hopefully be removed if I can figure out why it is an issue)

### System
- LUKS

  The main data partition of the install is LUKS encrypted (see LUKS section for details). The install auto logs in the user using getty so either the LUKS password or keyfile is needed to decrypt the drive. The password is asked by the user at each boot. Sleep is replaced with hybernation on the laptop to ensure data security. LUKS, secureboot, and manual decrypting of the drive ensures chaining of security. Secrets are managed by a secrets script (NOT commited to git) (see Bitwarden section).

  ```
    cipher: aes-xts-plain64
    keysize: 512
    hash: sha512
  ```

  > AES256-xts has a 512 bit key. The key is split into the two 256 bit keys and AES256 is done twice. [See this link](https://security.stackexchange.com/questions/101995)

- LVM

  The luks partition is then broken into 3 LVM partitions. `/home/user` is a symlink (@TODO convert to bind mount) to `/data/user`.

  - root
  - var
  - data

  I made the code modular so I can move to a different schema if I think of something better later.

### User
- Autologin (getty) / single user
- [dotfiles](https://github.com/aryan-gupta/dotfiles)
- AUR packages (testing)

  These packages are done manually through makepkg and not all of them work properly. Will need rethinking.

- Shell: `zsh` / `oh-my-zsh` / [`spaceship` prompt](https://spaceship-prompt.sh/)
- WM: `BSPWM`
- Terminal: `alacritty`
- Menu: `rofi`
- Compositor: `picom`
- Browser: `firefox`

### Data and Apps
- Data Manegment (partial-TBD)

  I have a NAS and it syncs up data with the NAS as needed, including backups and syncing.

### Secrets
- Philosophy

  - Attempt to use real security, not [security by obfuscation](https://en.wikipedia.org/wiki/Security_through_obscurity)
  - All secrets are encrypted
  - Please note that I am an amatueur security researcher (hopefully in the future I can have a friend audit my stuff)

- Bitwarden (WIP)

  As the secrets manager. With this, my secrets can move around and can be updated dynamically. This is the newest addition so its a WIP. I also need a blob manager

- Firefox

  Policies script is located in file: `roles/etc/templates/policies.json`

### TBD
  - user provisioning with active directory services
  - advanced networking support (integration into my homelab, etc)
  - TAGS (NEXT ITEM)


## Development
### VM
If you are attempting to run this in a vm, first download the arch iso:

> [https://archlinux.org/download/](https://archlinux.org/download/)

Create a VM with a `20 GB` disk and boot into the arch iso. Please ensure network connectivity and `/dev/vda` is the disk you want to install to. Run above command in the console. You can `ssh` into the archiso to copy-paste the command. See [SSH section](#ssh) for advice.

```console
root@archiso ~ # sh -c "$(curl -fsSL https://raw.githubusercontent.com/aryan-gupta/ansible/develop/scripts/webstrap.sh)" "default"
```

If the provisioning requires custom hostname or disk name. This command can be run. Since `default` was the chosen hostname, the file `host_vars/default.yml` gets loaded. You can copy this file to change the settings for another specific host if more complicated config is required. More examples are in the `host_vars` directory.

```console
root@archiso ~ # sh -c "$(curl -fsSL https://raw.githubusercontent.com/aryan-gupta/ansible/develop/scripts/webstrap.sh)" "foobar" --extra-vars '{"nocrypt":true,"install_disk":"/dev/sda","hostname":"foobar"}'
```

>
> Currently this error will show up. I am debating how to do secrets managment and once I decide on a method, I will remove this code. See [SSH section](#ssh) for advice.
>
> ```
> ===============================================================
> [ERROR]: /tmp/ansible/group_vars/all_secret.yml doesnt exist.
> Waiting on secrets file.
> This will be removed when screts manegment
> isnt scp'ing it into the test VM
> ===============================================================
> .........
> ```
>

Select `y` two times to confirm data destruction. See script `scripts/reset.sh` for more info. Select `n` to not wipe. If the disk is new, it is recommemded to select `n`. It is also the default choice. This script will be merged as an ansible role at some point.

```
[...]
===============================================================
Install Disk: /dev/vda
===============================================================
[WARNING] Do you want to WIPE THIS COMPUTER [y/N]: y
One more time: DELETE ALL DATA on /dev/vda? [y/N]: y

```

### SSH
If `ssh` is available, after booting into the arch iso, run this command and type in any password. This needs to be as secure as you need it.

```console
root@archiso ~ # passwd
New password: <text hidden>
Retype new password: <text hidden>
passwd: password updated successfully
```

From another box connected to the same network, you can run this command. Substitute `192.168.122.128` with the ip of the guest.

```console
➜ ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@192.168.122.128
Warning: Permanently added '192.168.122.213' (ED25519) to the list of known hosts.
root@192.168.122.213's password:
To install Arch Linux follow the installation guide:
https://wiki.archlinux.org/title/Installation_guide

For Wi-Fi, authenticate to the wireless network using the iwctl utility.
For mobile broadband (WWAN) modems, connect with the mmcli utility.
Ethernet, WLAN and WWAN interfaces using DHCP should work automatically.

After connecting to the internet, the installation guide can be accessed
via the convenience script Installation_guide.


Last login: Thu Feb  8 21:50:01 2024
root@archiso ~ #

```

You can now copy and paste the command into your host console. Please note that this is the develop webstrap script. Replace develop with master for mainline. Enter the hostname to start the install.

```console
root@archiso ~ # sh -c "$(curl -fsSL https://raw.githubusercontent.com/aryan-gupta/ansible/develop/scripts/webstrap.sh)"
Host Name: default

```

At some point you will get this error:

```
===============================================================
[ERROR]: /tmp/ansible/group_vars/all_secret.yml doesnt exist.
Waiting on secrets file.
This will be removed when screts manegment
isnt scp'ing it into the test VM
===============================================================
......
```

If you are me, you can do this command to move the secrets file to the VM. At some point I do need to stop using this `.gitignore`'d file and finish the bitwarden script

```console
➜ scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no /godfile/ansible/group_vars/all_secret.yml root@192.168.122.128:/tmp/ansible/group_vars/all_secret.yml
root@192.168.122.128's password:
all_secret.yml                                                   100% ----   479.8KB/s   00:00
```

Finally, choose if the disk should be wiped:

```
[...]
===============================================================
Install Disk: /dev/vda
===============================================================
[WARNING] Do you want to WIPE THIS COMPUTER [y/N]: y
One more time: DELETE ALL DATA on /dev/vda? [y/N]: y
```

## Issues
This section will never be updated and will be removed once issues have been resolved
[ommited](https://en.wikipedia.org/wiki/Security_through_obscurity)
```
  nopasswd
  restart_windows_script
  xppentablet
  plymouth
```


## Hosts
- boson : Laptop
  - [Thinkpad X1C9](https://wiki.archlinux.org/title/Lenovo_ThinkPad_X1_Carbon_(Gen_9) )
  - retired ~~[Thinkpad X1C6](https://wiki.archlinux.org/index.php/Lenovo_ThinkPad_X1_Carbon_(Gen_6) )~~
- graviton : Main Desktop
  - Gigabyte B550
  - retired ~~Asus Z97 Custom Build~~
- default
  - reserved for VM test installs
