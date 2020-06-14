FROM zoneminderhq/zoneminder:latest-ubuntu18.04
ARG CUDA_VERSION="none"
ARG BUILD_DEPS="wget git build-essential cmake python-dev python3-dev python3-pip libopenblas-dev liblapack-dev libblas-dev libsm-dev zlib1g-dev libjpeg8-dev libtiff5-dev libpng-dev"
ARG CUDA_DEPS="nvidia-cuda-toolkit nvidia-cuda-dev libcudnn7 libcudnn7-dev"
ARG BUILD_DIR="/tmp/build"
ARG TEST_DIR="/tmp/test"

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F60F4B3D7FA2AF80 \
    && echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

# Install dependencies.
RUN mkdir -p "$BUILD_DIR" \
    && apt-get update \
    && apt-get --assume-yes install \
        curl \
        jq \
        sudo \
        libcrypt-mysql-perl \
        libcrypt-eksblowfish-perl \
        libmodule-build-perl \
        libyaml-perl \
        libjson-perl \
        libfile-spec-native-perl \
        libgetopt-long-descriptive-perl \
        libconfig-inifiles-perl \
        liblwp-protocol-https-perl \
        python-numpy \
        python3 \
        python3-pip \
        python3-numpy \
        python-idna \
        python3-idna \
        libsm6 \
        libxrender1 \
        libfontconfig1 \
        supervisor \
        g++-6 \
        gcc-6 \
        $([ "$CUDA_VERSION" = 'none' ] && echo -n "" || echo -n "$CUDA_DEPS") \
        $BUILD_DEPS \
    && curl "https://bootstrap.pypa.io/get-pip.py" -o "$BUILD_DIR/get-pip.py" \
    && python "$BUILD_DIR/get-pip.py" \
    && python3 -m pip install --upgrade pip \
    && pip install future \
    && pip3 install future \
    && perl -MCPAN -e "install Net::WebSocket::Server" \
    && perl -MCPAN -e "install Net::MQTT::Simple"

# Build opencv
RUN cd "$BUILD_DIR" \
    && curl --fail --location --output opencv.zip "https://github.com/opencv/opencv/archive/4.2.0.zip" \
    && unzip opencv.zip \
    && mv opencv-4.2.0 opencv \
    && curl --fail --location --output opencv_contrib.zip "https://github.com/opencv/opencv_contrib/archive/4.2.0.zip" \
    && unzip opencv_contrib.zip \
    && mv opencv_contrib-4.2.0 opencv_contrib \
    && mkdir -p "$BUILD_DIR/opencv/build" \
    && cd "$BUILD_DIR/opencv/build" \
    && CC=gcc-6 CXX=g++-6 cmake \
        -D CMAKE_BUILD_TYPE=RELEASE \
       	-D CMAKE_INSTALL_PREFIX=/usr/local \
        -D INSTALL_PYTHON_EXAMPLES=ON \
        -D INSTALL_C_EXAMPLES=OFF \
        -D OPENCV_ENABLE_NONFREE=ON \
       	-D WITH_CUDA=$([ "$CUDA_VERSION" = "none" ] && echo "OFF" || echo "ON") \
       	-D WITH_CUDNN=$([ "$CUDA_VERSION" = "none" ] && echo "OFF" || echo "ON") \
       	-D OPENCV_DNN_CUDA=$([ "$CUDA_VERSION" = "none" ] && echo "OFF" || echo "ON") \
       	-D ENABLE_FAST_MATH=1 \
        -D CUDA_FAST_MATH=$([ "$CUDA_VERSION" = "none" ] && echo "0" || echo "1") \
       	-D CUDA_ARCH_BIN=$CUDA_VERSION \
       	-D CUDA_ARCH=$CUDA_VERSION \
       	-D WITH_CUBLAS=$([ "$CUDA_VERSION" = "none" ] && echo "OFF" || echo "ON") \
       	-D OPENCV_EXTRA_MODULES_PATH="$BUILD_DIR/opencv_contrib/modules" \
       	-D BUILD_opencv_python2=ON \
       	-D BUILD_opencv_python3=ON \
       	.. \
    && echo "Starting make with $(grep -cE '^processor\s+:\s+[0-9]+' /proc/cpuinfo) theads." \
    && make -j$(grep -cE '^processor\s+:\s+[0-9]+' /proc/cpuinfo) \
    && make install \
    && ldconfig

# Install mlapi
RUN git clone "https://github.com/pliablepixels/mlapi.git" \
    && cd mlapi \
    && pip3 install -r requirements.txt

# Install zmeventnotification.
RUN git clone "https://github.com/pliablepixels/zmeventnotification.git" \
    && cd zmeventnotification \
    && git fetch --tags \
    && git checkout $(git describe --tags $(git rev-list --tags --max-count=1)) \
    && ./install.sh --no-interactive --install-es --install-hook --install-config --no-pysudo \
    && mkdir -p /var/lib/zmeventnotification/push/ \
    && chown www-data /var/lib/zmeventnotification/push/ -R

# Cleanup
RUN apt-get --assume-yes remove $BUILD_DEPS \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf "$BUILD_DIR"

COPY docker/ /
COPY test/ "$TEST_DIR"

# Test services
RUN "$TEST_DIR/test.sh" \
    && rm -rf "$TEST_DIR"

ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisor/supervisor.conf"]
