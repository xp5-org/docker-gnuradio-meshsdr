FROM ubuntu:25.04

ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        xfce4 \
        xfce4-clipman-plugin \
        xfce4-cpugraph-plugin \
        xfce4-netload-plugin \
        xserver-xorg-legacy \
        xdg-utils \
        dbus-x11 \
        xfce4-screenshooter \
        xfce4-taskmanager \
        xfce4-terminal \
        xfce4-xkb-plugin \
        xorgxrdp \
        xrdp \
        sudo \
        wget \
        curl \
        bzip2 \
        python3 \
        python3-pip \
        python3-venv \
        build-essential \
        xterm \
        git \
        vim \
        pkg-config \
        libusb-1.0-0-dev \
        libuv1-dev \
        libgpiod-dev \
        libbluetooth-dev \
        libi2c-dev \
        libyaml-cpp-dev \
        cmake \
        ninja-build \
        python3-dev \
        libudev-dev \
        libssl-dev \
        libffi-dev \
        libncurses5-dev \
        libncursesw5-dev \
        zlib1g-dev \
        libsqlite3-dev \
        libreadline-dev \
        libbz2-dev \
        liblzma-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        linux-headers-generic \
        ncurses-dev \
        xdotool \
        python3-tk \
        gnuradio* \
        python3-gi gir1.2-gtk-3.0 libgtk-3-dev rtl-sdr gr-osmosdr\
        unzip && \
    apt-get remove -y light-locker xscreensaver && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*



# Fix XRDP/X11 setup
RUN mkdir -p /var/run/dbus && \
    cp /etc/X11/xrdp/xorg.conf /etc/X11 || true && \
    sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config && \
    sed -i "s|xrdp/xorg|xorg|g" /etc/xrdp/sesman.ini && \
    echo "xfce4-session" >> /etc/skel/.Xsession





# -----------------------
# meshtastic environment
# -----------------------
WORKDIR /home/user
RUN git clone https://gitlab.com/crankylinuxuser/meshtastic_sdr
RUN mkdir -p /home/user/Meshtasticator/Meshtasticator-device && \
    git clone https://github.com/meshtastic/firmware.git /home/user/Meshtasticator/Meshtasticator-device




# ----------------
# setup lora sdr dependencies
# -------------------
RUN mkdir -p /data
RUN chgrp -R users /data && \
    chmod -R g+rwx /data && \
    chmod g+s /data
ENV CONDA_ACCEPT_CHANNELS=true
ENV CONDA_SUPPRESS_CHANNEL_PRIVACY_CONSENT=true

# install lora + mesh sdr
WORKDIR /data/
RUN git clone https://gitlab.com/crankylinuxuser/meshtastic_sdr 
RUN git clone https://github.com/tapparelj/gr-lora_sdr.git


# install conda
WORKDIR /data/gr-lora_sdr
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-latest-Linux-x86_64.sh

RUN /opt/conda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
RUN /opt/conda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# create conda env
RUN cp environment.yml /tmp/environment.yml
RUN /opt/conda/bin/conda env create -f /tmp/environment.yml -p /opt/conda/envs/gr310 -y
#    /opt/conda/bin/conda clean -afy

ENV PATH=/opt/conda/envs/gr310/bin:/opt/conda/bin:$PATH

# build lora sdr blocks
RUN mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make install -j$(( ($(nproc) / 2) > 0 ? $(nproc) / 2 : 1 )) && \

# make it so non root users can write and exec
RUN chgrp -R users /opt/conda/envs && \
    chmod -R g+rwx /opt/conda/envs && \
    chmod g+s /opt/conda/envs && \
    chmod -R 0775 /opt/conda/envs






# ----------------
# pip python venv
# -------------------
WORKDIR /data/Meshtasticator/Meshtasticator-device
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install platformio PyYAML matplotlib meshtastic scipy && \
    chgrp -R users /opt/venv && chmod -R g+rwX /opt/venv && \
    find /opt/venv -type d -exec chmod g+s {} \;

ENV VENV_PATH=/opt/venv
ENV PATH="$VENV_PATH/bin:$PATH"




# -----------------------
# setup runtime
# -----------------------
WORKDIR /root
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

EXPOSE 3389 8080
ENTRYPOINT ["/app/entrypoint.sh"]