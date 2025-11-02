#!/bin/bash

if [ -n "$USERPASSWORD" ]; then
  echo ''
  echo "USERPASSWORD: $USERPASSWORD" # print password to docker log console
else
  # random password 
  USERPASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 10 ; echo '')
  echo "Generated Password: $USERPASSWORD"  
  # echo "$USERPASSWORD" > passwordoutput.txt         #save
fi

if [ -n "$USERNAME" ]; then
  echo "USERNAME: $USERNAME" #debug
  echo "$USERNAME" > usernameoutput.txt  #save
else
  USERNAME="user"
fi

# Set up user from command line input positions
addgroup "$USERNAME"
useradd -m -s /bin/bash -g "$USERNAME" "$USERNAME"
echo "$USERNAME:$USERPASSWORD" | chpasswd 
usermod -aG sudo "$USERNAME"
echo "debug1"

mkdir -p /home/$USERNAME/Desktop/

# start gnuradio script create
cat <<'EOF' > /home/$USERNAME/Desktop/runme.sh
#!/bin/bash
# initialize Conda
source /opt/conda/etc/profile.d/conda.sh

# activate your environment
conda activate gr310

# start GNU Radio Companion
gnuradio-companion meshtastic_sdr/gnuradio\ scripts/RX/Meshtastic_US_250KHz_RTLSDR.grc

# wait for background jobs
wait
EOF

# tell gnuradio where the xterm exec is at
# this doesnt work gets over-ridden
mkdir -p /home/$USERNAME/.config/gnuradio/
touch /home/$USERNAME/.config/gnuradio/grc.conf
sudo chown -R $USERNAME:user /home/$USERNAME/.config/gnuradio/grc.conf
echo "xterm_executable = /usr/bin/x-terminal-emulator" >> /home/$USERNAME/.config/gnuradio/grc.conf

# start-longfast-decode script create
cat <<'EOF' > /home/$USERNAME/Desktop/decode_longfast.sh
#!/bin/bash
xfce4-terminal --hold -e "bash -c 'source /opt/venv/bin/activate; cd /data/meshtastic_sdr/python\ scripts; python3 meshtastic_gnuradio_RX.py -n 127.0.0.1 -p 20004; read -p \"Press Enter to close\"'"
EOF

# Realtek RTL2832U devices
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="2832", GROUP="users", MODE="0666"' > /etc/udev/rules.d/rtl-sdr.rules
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="2838", GROUP="users", MODE="0666"' >> /etc/udev/rules.d/rtl-sdr.rules
sudo usermod -aG plugdev userid$


chmod +x /home/$USERNAME/Desktop/runme.sh
chmod +x /home/$USERNAME/Desktop/decode_longfast.sh
#sudo chown -R $USERNAME:user /opt/venv
sudo chown -R $USERNAME:user /app
sudo chown -R $USERNAME:user /home/user

# Start and stop scripts
echo -e "starting xrdp services...\n"
trap "pkill -f xrdp" SIGKILL SIGTERM SIGHUP SIGINT EXIT

# start xrdp desktop
rm -rf /var/run/xrdp*.pid
rm -rf /var/run/xrdp/xrdp*.pid
xrdp-sesman && exec xrdp -n