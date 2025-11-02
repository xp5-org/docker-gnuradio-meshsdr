## ubuntu 25 docker container with xrdp and gnuradio for decoding mesh packets

someone else did all the hard work of making 
gnuradio decode lora 
- https://github.com/tapparelj/gr-lora_sdr
meshtastic gnuradio decode:
- https://gitlab.com/crankylinuxuser/meshtastic_sdr 


<br>


## how to use this container

<br>

### check lsusb of docker host, with SDR plugged in
```
/meshsdr$ lsusb | grep -i rtl
Bus 003 Device 003: ID 0bda:2838 Realtek Semiconductor Corp. RTL2838 DVB-T
```
<br>

### set USB device permissions on the host

```
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
<br>

### get the dockerfile

```
git clone https://github.com/xp5-org/docker-gnuradio-meshsdr.git
```
<br>

### build container

```
docker build ./ -t meshsdr
```
<br>

### run the docker container 

```
/meshsdr$ docker run --rm -p 3389:3389 \
    -e USERNAME=user \
    -e USERPASSWORD=a \
    --device /dev/bus/usb/003/003 \
    meshsdr:latest

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

### connect to remote desktop and start the run script 

using a v1 RTL-SDR:
<img width="1021" height="797" alt="image" src="https://github.com/user-attachments/assets/8cdbbbdb-fdb3-40a8-9f0a-14b9a135a638" />


<br>
<br>

## example connecting to gnuradio ZMQ output to receive the packet from LongFast

```
python3 - <<'EOF'
import zmq
ctx = zmq.Context()
sock = ctx.socket(zmq.SUB)
sock.connect("tcp://127.0.0.1:20004")
sock.setsockopt_string(zmq.SUBSCRIBE, "")
while True:
    msg = sock.recv()
    print(msg)
EOF
```

<img width="1277" height="719" alt="image" src="https://github.com/user-attachments/assets/04b6e35f-1d8b-41de-bfbf-3fc4d0cac606" />

<br>

## using meshtastic_gnuradio_RX.py to decrypt & decode protobufs
this is a python script from https://gitlab.com/crankylinuxuser/meshtastic_sdr
<br>

<img width="1348" height="644" alt="image" src="https://github.com/user-attachments/assets/2acbe5a0-178c-4fd0-bb95-f8d1eaff9667" />


