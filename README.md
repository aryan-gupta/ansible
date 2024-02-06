# ansible
An Ansible Playbook to setup my Linux machines. From the platform of Arch linux and wanting to automate my install was born this project. [btws I use Arch](https://i.kym-cdn.com/photos/images/original/002/243/383/c00.png)


## Installing
Run this command to start the install. It will ask you if you want to destroy the disk.
```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/aryan-gupta/ansible/master/scripts/webstrap.sh)"
```

## Features
#### Base
  - Arch linux
    > I have always loved the Arch linux philosphy. From a person who came from M$ Windows, bloatware and unnessary garbage was always a large pet peave of mine. I still run Windows debloating scripts on my gaming hard drive.
  - Ansible
    > This project is written in Ansible. It seems the best tool for the job and if a better tool comes along, hopefully porting it to another language (other than ansible yaml) not too difficult to do and debug.

#### Boot
  - UEFI Secureboot (testing)
    > Instal contains two partitions. A efi partition with two items (signed boot image and a random-seed from systemd). The second partion is encrypted with LUKS (below). The kernel is verified by both the motherboard (TPM) and sbctl on boot (via a script). Any change to the boot image will notify the user.
  - Linux UKI Image
    > Install creates a single signed image that contains the kernel, initramfs, microcode and commandline params. Please note there is NO fallback image. Only one default image is created. A fallback kernel is TBD if needed at all (and will most likley be non-signed or something if I do it).
  - Plymouth
    > For a relatively seamless boot experience. There are issued but I belive its [issues](https://blogs.gnome.org/halfline/2009/11/28/plymouth-%E2%9F%B6-x-transition/) of other systems and their compatibility with this style of eyecandy. Please be aware of a current security issue with my implementation (the plymouth non-daemon program is nopasswd in sudoers to fix an issue and will hopefully be removed if I can figure out why it is an issue)

#### System
  - LUKS
    > The main data partition of the install is LUKS encrypted (see LUKS section for details). The install auto logs in the user using getty so either the LUKS password or keyfile is needed to decrypt the drive. The password is asked by the user at each boot. Sleep is replaced with hybernation on the laptop to ensure data security. LUKS, secureboot, and manual decrypting of the drive ensures chaining of security. Secrets are managed by a secrets script (NOT commited to git) (see Bitwarden section).
    ```
      cipher: aes-xts-plain64
      keysize: 512
      hash: sha512
      keyfile_len: 512
    ```
  - LVM
    > LVM stuff here

#### User
  - Autologin (getty) / single user
  - AUR packages (testing)
    > These packages are done manually through makepkg and not all of them work properly. Will need rethinking.
  - zsh / oh-my-zsh / spaceship prompt
    > Auto provisioning of user shell
  - [dotfiles]()

#### Data and Apps
  - Data Manegment (partial-TBD)
    > I have a NAS and it syncs up data with the NAS as needed, including backups and syncing.

#### Secrets
  - Philosophy
    > Attempt to use real security, not [security by obfuscation](https://en.wikipedia.org/wiki/Security_through_obscurity)
    > All secrets are encrypted
    > Please note that I am an amatueur security researcher (hopefully in the future I can have a friend audit my stuff)
  - Bitwarden (WIP)
    > As the secrets manager. With this, my secrets can move around and can be updated dynamically. This is the newest addition so its a WIP. I also need a blob manager
  - Firefox
    > Policies script is located in file: `roles/etc/templates/policies.json`

#### TBD
  - user provisioning with active directory services
  - advanced networking support (integration into my homelab, etc)
  - TAGS (NEXT ITEM)


## KVM
If you are attempting to run this in a vm, first download the arch iso:

> [https://archlinux.org/download/](https://archlinux.org/download/)

Create a VM with a `20 GB` disk and boot into the arch iso. please ensure network connectivity and `/dev/vda` is the disk you want to install to

Run above command and select `default` for the hostname:

> If `ssh` is allowed, a quicker way is documented after these steps.

```
root@archiso ~ # sh -c "$(curl -fsSL https://raw.githubusercontent.com/aryan-gupta/ansible/master/scripts/webstrap.sh)"
Host Name: default

```

Select `y` two times to confirm data destruction. See script `scripts/reset.sh` for more info. Select `n` to not wipe.

> If the disk is new, it is recommemded to select `n`. It is also the default choice.

```
[...]
Do you want to WIPE THIS COMPUTER [y/N]: y
One more time: DELETE ALL DATA? [y/N]: y

```

Since `default` was the chosen hostname, the file `host_vars/default.yml` gets loaded. You can copy this file to change the settings for another specific host. More examples are in the `host_vars` directory.

>
> Theoritcally, the `./setup.sh` script can be manually run with this parameters. However this has not been tested.
>
> ```shell
> ./setup.sh default "" --extra-vars="hostname=foobar install_disk=/dev/sda"
>
> ```
>

If `ssh` is available, after booting into the arch iso, run this command and type in any password:

> This needs to be as secure as you need it. Since the connection is local on a VM it can be simple.

```
root@archiso ~ # passwd
New password: <text hidden>
Retype new password: <text hidden>
passwd: password updated successfully
```

From another box connected to the same network (My host box since this is a VM example), you can run this command:

> example uses 192.168.122.128 as the ip. Substitute the ip of the guest as needed.

```
➜ ssh root@192.168.122.128
The authenticity of host '192.168.122.128 (192.168.122.128)' can't be established.
ED25519 key fingerprint is SHA256:jVLpn2MEqLm7MkCSHyxzIQSi1kubdjS27+XhCUFqLHM.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.122.128' (ED25519) to the list of known hosts.
root@192.168.122.128's password:

```

You can now copy and paste the command into your host shell:

```
root@archiso ~ # sh -c "$(curl -fsSL https://raw.githubusercontent.com/aryan-gupta/ansible/master/scripts/webstrap.sh)"

```

At some point you will get this error:

```
[ERROR]: /tmp/ansible/group_vars/all_secret.yml doesnt exist.
Waiting on secrets file.
This will be removed when screts manegment
isnt scp'ing it into the test VM
sleeping 5 more seconds
\n\n\n

```

If you are me, you can do this command to move the secrets file to the VM. At some point I do need to stop using this `.gitignore`'d file and finish the bitwarden script

```
scp /godfile/ansible/group_vars/all_secret.yml root@192.168.122.128:/tmp/ansible/group_vars/all_secret.yml
root@192.168.122.128's password:
all_secret.yml                                                   100% ----   479.8KB/s   00:00

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
