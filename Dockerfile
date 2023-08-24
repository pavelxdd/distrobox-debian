# syntax=docker/dockerfile:1
FROM docker.io/amd64/debian:sid as debian
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /tmp

ARG LANG=C.UTF-8
ARG LANGUAGE=${LANG}
ARG LC_ALL=${LANG}

ARG TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_FUND=false

ARG GCC_VERSION=13
ARG LLVM_VERSION=16
ARG NODE_VERSION=18

RUN --mount=type=bind,target=/app \
    --mount=type=tmpfs,target=/tmp \
    \
    rm -f /etc/apt/sources.list.d/* /etc/apt/preferences \
    \
    && install -m644 /app/sources.list /etc/apt/sources.list \
    && install -m644 /app/apt.conf /etc/apt/apt.conf.d/99local \
    && install -m644 /app/dpkg.cfg /etc/dpkg/dpkg.cfg.d/99local \
    \
    && apt-get update && apt-get install -yqq --no-install-recommends \
        ca-certificates gpg curl \
    \
    && dpkg --add-architecture armhf \
    && dpkg --add-architecture arm64 \
    \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key \
        | gpg --no-tty --dearmor -o /etc/apt/trusted.gpg.d/nodesource.gpg \
    && printf "deb [arch=amd64] %s %s\n" \
              "https://deb.nodesource.com/node_${NODE_VERSION}.x" \
              "sid main" > /etc/apt/sources.list.d/nodesource.list \
    && printf "Package: *\nPin: origin %s\nPin-Priority: %s\n" \
              "deb.nodesource.com" "900" > /etc/apt/preferences.d/nodesource \
    \
    && curl -fsSL https://files.pvs-studio.com/etc/pubkey.txt \
        | gpg --no-tty --dearmor -o /etc/apt/trusted.gpg.d/viva64.gpg \
    && printf "deb [arch=amd64] %s %s\n" \
              "https://files.pvs-studio.com/deb" \
              "viva64-release pvs-studio" > /etc/apt/sources.list.d/viva64.list \
    \
    && sed -i "s/http:/https:/g" /etc/apt/sources.list \
    \
    && apt-get update \
    && apt-get full-upgrade -yqq --auto-remove --purge \
    && apt-get install -yqq --no-install-recommends \
        apt-utils \
        astyle \
        autoconf \
        automake \
        autopoint \
        bash \
        bash-completion \
        bc \
        bind9-dnsutils \
        bison \
        build-essential \
        busybox \
        clang-${LLVM_VERSION} \
        cmake \
        debhelper \
        deborphan \
        devscripts \
        dialog \
        diffutils \
        file \
        findutils \
        flex \
        htop \
        gawk \
        {gcc,g++}-${GCC_VERSION} \
        {gcc,g++}-${GCC_VERSION}-arm-linux-gnueabihf \
        {gcc,g++}-${GCC_VERSION}-aarch64-linux-gnu \
        gdb-multiarch \
        gdbserver \
        gettext \
        git \
        git-delta \
        gnupg2 \
        inetutils-ping \
        inetutils-traceroute \
        iproute2 \
        iptables \
        ipset \
        jq \
        kmod \
        less \
        libcunit1-dev \
        libdistro-info-perl \
        libegl1-mesa \
        libgl1-mesa-glx \
        libev-dev \
        liblua5.4-dev \
        libluajit-5.1-dev \
        libnss-myhostname \
        libpython3-dev \
        libssl-dev:amd64 \
        libssl-dev:armhf \
        libssl-dev:arm64 \
        libtool-bin \
        libvte-2.9[0-9]-common \
        libvte-common \
        libvulkan1 \
        lld-${LLVM_VERSION} \
        lldb-${LLVM_VERSION} \
        llvm-${LLVM_VERSION}-dev \
        locales \
        lsb-release \
        lsof \
        lua5.4 \
        luajit \
        man-db \
        manpages \
        mc \
        mesa-vulkan-drivers \
        meson \
        mkcert \
        musl-dev \
        musl-tools \
        nala \
        nano \
        nasm \
        ncurses-base \
        neofetch \
        netcat-openbsd \
        nodejs \
        openssh-client \
        p7zip-rar \
        p7zip-full \
        pahole \
        passwd \
        pbzip2 \
        pinentry-curses \
        perl \
        pigz \
        pkg-config \
        pre-commit \
        procps \
        pvs-studio \
        python3 \
        python3-distutils \
        python3-pip \
        python3-setuptools \
        rsync \
        shellcheck \
        shfmt \
        squashfs-tools \
        sshpass \
        strace \
        sudo \
        swig \
        time \
        tmux \
        tree \
        tzdata \
        util-linux \
        uuid-runtime \
        valgrind \
        wget \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        zstd \
    \
    && install -m755 /app/update-alternatives-gcc.sh /usr/local/bin/update-alternatives-gcc \
    && update-alternatives-gcc ${GCC_VERSION} 60 2> /dev/null \
    \
    && install -m755 /app/update-alternatives-clang.sh /usr/local/bin/update-alternatives-clang \
    && update-alternatives-clang ${LLVM_VERSION} 60 2> /dev/null \
    \
    && update-alternatives --force --set editor /bin/nano \
    \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/flatpak \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/flatpak-bisect \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/flatpak-coredumpctl \
    \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/docker \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/docker-init \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/docker-proxy \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/docker-compose \
    \
    && setcap cap_sys_chroot+ep /usr/sbin/chroot \
    \
    && env NPM_CONFIG_CACHE=/tmp/npm npm i -g \
        npm@latest \
        yarn@latest \
        wscat \
    \
    && apt-get autoremove --purge -yqq \
    && apt-get clean -yqq \
    && rm -rf /var/lib/apt/lists/*

ARG MAKEFLAGS="-j4"
ARG MARCH="x86-64-v3"
ARG MTUNE="generic"
ARG CC=gcc
ARG CXX=g++
ARG CFLAGS="-march=${MARCH} -mtune=${MTUNE} \
-O2 -ftree-vectorize -pipe -g0 -DNDEBUG -pthread -fPIC -DPIC -fno-plt"
ARG CXXFLAGS="${CFLAGS}"
ARG LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now -s"

# samurai
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch https://github.com/michaelforney/samurai.git \
    && make -C samurai install PREFIX=/usr/local \
    && ln -s samu /usr/local/bin/ninja

# how-to-use-pvs-studio-free
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch https://github.com/viva64/how-to-use-pvs-studio-free.git \
    && sed -i '1s;^;#include <cstdint>\n;' how-to-use-pvs-studio-free/comments.h \
    && cmake -Wno-dev \
        -G Ninja \
        -S how-to-use-pvs-studio-free \
        -B how-to-use-pvs-studio-free/build \
        -D CMAKE_BUILD_TYPE=Release \
        -D PVS_STUDIO_SHARED=OFF \
    && cmake --build how-to-use-pvs-studio-free/build \
    && cmake --install how-to-use-pvs-studio-free/build --prefix /usr/local \
    && strip -s /usr/local/bin/how-to-use-pvs-studio-free

# starship
RUN --mount=type=tmpfs,target=/tmp name=starship-x86_64-unknown-linux-gnu \
    && curl -fsSL https://github.com/starship/starship/releases/latest/download/${name}.tar.gz \
        | tar xz && install -m755 -t /usr/local/bin starship

# hadolint
ADD --chmod=755 --chown=root:root \
    https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 \
    /usr/local/bin/hadolint

# host-spawn
ADD --chmod=755 --chown=root:root \
    https://github.com/1player/host-spawn/releases/latest/download/host-spawn-x86_64 \
    /usr/local/bin/host-spawn

# lua-argparse
ADD --chmod=644 --chown=root:root \
    https://raw.githubusercontent.com/luarocks/argparse/master/src/argparse.lua \
    /usr/local/share/lua/5.1/argparse.lua

# lua-filesystem
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch https://github.com/lunarmodules/luafilesystem.git \
    && make -C luafilesystem LUA_INC=-I/usr/include/luajit-2.1 WARN="${CFLAGS}" \
    && make -C luafilesystem PREFIX=/usr/local LUA_VERSION=5.1 install

# lua-lanes
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch https://github.com/LuaLanes/lanes.git \
    && sed -i "s/sudo = (geteuid() == 0)/sudo = 0/" lanes/src/lanes.c \
    && make -C lanes install \
        CFLAGS="${CFLAGS} -I/usr/include/luajit-2.1" \
        LIBFLAG="-shared" \
        LIBS="-lluajit-5.1 -lpthread" \
        LUAROCKS=1 \
        DESTDIR=/usr/local \
        LUA_LIBDIR=/usr/local/lib/lua/5.1 \
        LUA_SHAREDIR=/usr/local/share/lua/5.1

# luacheck
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch https://github.com/luarocks/luacheck.git \
    && cp -r luacheck/src/luacheck /usr/local/share/lua/5.1/ \
    && install -Dm755 luacheck/bin/luacheck.lua /usr/local/bin/luacheck \
    && sed -i "s/env lua/env luajit/" /usr/local/bin/luacheck

# ble.sh
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch --recurse-submodules https://github.com/akinomyoga/ble.sh.git \
    && make -C ble.sh install PREFIX=/usr INSDIR_DOC="$(mktemp -d)"

# freebsd <sys/queue.h>
ADD --chmod=644 --chown=root:root \
    https://raw.githubusercontent.com/freebsd/freebsd-src/main/sys/sys/queue.h \
    /usr/local/include/freebsd/sys/queue.h

# pthread_wrapper
ADD --chmod=644 --chown=root:root \
    https://raw.githubusercontent.com/pavelxdd/pthread_wrapper/master/src/pthread_wrapper.h \
    /usr/local/include/

# circleq
ADD --chmod=644 --chown=root:root \
    https://raw.githubusercontent.com/pavelxdd/circleq/master/src/circleq.h \
    /usr/local/include/

# tbtree
ADD --chmod=644 --chown=root:root \
    https://raw.githubusercontent.com/pavelxdd/tbtree/master/src/tbtree.h \
    /usr/local/include/

# raii
ADD --chmod=644 --chown=root:root \
    https://raw.githubusercontent.com/pavelxdd/raii/master/src/raii.h \
    /usr/local/include/

# ta
RUN cd /usr/local/src \
    && git clone --depth 1 --single-branch https://github.com/pavelxdd/ta.git \
    && cmake -Wno-dev \
        -G Ninja \
        -S ta \
        -B ta/build \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D CMAKE_INSTALL_LIBDIR=/usr/local/lib \
        -D BUILD_SHARED_LIBS=OFF \
    && cmake --build ta/build \
    && cmake --install ta/build

# evio
RUN cd /usr/local/src \
    && git clone --depth 1 --single-branch https://github.com/pavelxdd/evio.git \
    && cmake -Wno-dev \
        -G Ninja \
        -S evio \
        -B evio/build \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D CMAKE_INSTALL_LIBDIR=/usr/local/lib \
        -D BUILD_SHARED_LIBS=OFF \
    && cmake --build evio/build \
    && cmake --install evio/build

# yyjson
RUN cd /usr/local/src \
    && git clone --depth 1 --single-branch https://github.com/ibireme/yyjson.git \
    && cmake -Wno-dev \
        -G Ninja \
        -S yyjson \
        -B yyjson/build \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D CMAKE_INSTALL_LIBDIR=/usr/local/lib \
        -D BUILD_SHARED_LIBS=OFF \
    && cmake --build yyjson/build \
    && cmake --install yyjson/build

# mpack
RUN cd /usr/local/src \
    && git clone --depth 1 --single-branch https://github.com/ludocode/mpack.git \
    && cd mpack && tools/amalgamate.sh && cd .build/amalgamation/src/mpack \
    && gcc -c mpack.c -o mpack.o && ar rcs libmpack.a mpack.o \
    && install -m644 -t /usr/local/lib libmpack.a \
    && install -m644 -t /usr/local/include mpack.h

# locales
ENV LANG en_US.UTF-8
RUN sed -i "s/# ${LANG} UTF-8/${LANG} UTF-8/" /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="${LANG}"
