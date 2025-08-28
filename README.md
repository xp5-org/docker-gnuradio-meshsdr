this is a ubuntu 25 docker container with xrdp and gnuradio

someone else did all the hard work of making gnuradio decode lora & meshtastic: https://gitlab.com/crankylinuxuser/meshtastic_sdr 






need to set permissions on the usb device in the host so the 'user' in docker container can see it

```
/meshsdr$ lsusb | grep -i rtl
Bus 003 Device 003: ID 0bda:2838 Realtek Semiconductor Corp. RTL2838 DVB-T

/meshsdr$ getfacl /dev/bus/usb/003/003
getfacl: Removing leading '/' from absolute path names
# file: dev/bus/usb/003/003
# owner: root
# group: plugdev
user::rw-
user:user:rw-
group::rw-
mask::rw-
other::---

/meshsdr$ sudo chmod 666 /dev/bus/usb/003/003
/meshsdr$ getfacl /dev/bus/usb/003/003
getfacl: Removing leading '/' from absolute path names
# file: dev/bus/usb/003/003
# owner: root
# group: plugdev
user::rw-
user:user:rw-
group::rw-
mask::rw-
other::rw-
```

```
/meshsdr$ docker run --rm -p 3389:3389 \
    -e USERNAME=user \
    -e USERPASSWORD=a \
    --device /dev/bus/usb/003/003 \
    meshsim:latest

USERPASSWORD: a
USERNAME: user
info: Selecting GID from range 1000 to 59999 ...
info: Adding group `user' (GID 1001) ...
useradd: warning: the home directory /home/user already exists.
useradd: Not copying any file from skel directory into it.
debug1
usermod: user 'userid$' does not exist
debug2
debug2.1
debug2.2
debug2.3
chown: cannot access '/testrunnerapp': No such file or directory
debug2.4 this part takes awhile
debug3
starting xrdp services...

debug4
```

<br>

using a v1 RTL-SDR:

<img width="1021" height="797" alt="image" src="https://github.com/user-attachments/assets/8cdbbbdb-fdb3-40a8-9f0a-14b9a135a638" />

