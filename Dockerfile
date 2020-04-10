FROM zoneminderhq/zoneminder:latest-ubuntu18.04

# Install zm event notification server
RUN apt-get update \
    && apt-get --assume-yes install git curl sudo wget build-essential cmake libcrypt-mysql-perl libcrypt-eksblowfish-perl libmodule-build-perl libyaml-perl libjson-perl libfile-spec-native-perl libgetopt-long-descriptive-perl libconfig-inifiles-perl liblwp-protocol-https-perl python3 python3-pip python3-dev libopenblas-dev liblapack-dev libblas-dev libsm6 libsm-dev libxrender1 libfontconfig1 \
    && perl -MCPAN -e "install Net::WebSocket::Server" \
    && perl -MCPAN -e "install Net::MQTT::Simple" \
    && pip3 install opencv-python opencv-contrib-python face_recognition future

RUN git clone https://github.com/pliablepixels/zmeventnotification.git \
    && cd zmeventnotification \
    && git fetch --tags \
    && git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) \
    && ./install.sh --no-interactive --install-es --install-hook --install-config --no-pysudo

RUN mkdir -p /var/lib/zmeventnotification/push/ \
    && chown www-data /var/lib/zmeventnotification/push/ -R
