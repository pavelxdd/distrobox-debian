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
ARG NPM_CONFIG_AUDIT=false
ARG NPM_CONFIG_FUND=false

ARG GCC_VERSION=12
ARG LLVM_VERSION=15
ARG NODE_VERSION=18

RUN --mount=type=bind,target=/app \
    --mount=type=tmpfs,target=/tmp \
    --mount=type=tmpfs,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/cache/apt \
    \
    rm -f \
        /etc/apt/sources.list.d/* \
        /etc/apt/preferences \
    \
    && cat /app/dpkg.cfg > /etc/dpkg/dpkg.cfg.d/local \
    && cat /app/apt.conf > /etc/apt/apt.conf.d/local \
    && cat /app/sources.list > /etc/apt/sources.list \
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
    && install -m755 /app/update-alternatives-gcc.sh /usr/local/bin/update-alternatives-gcc \
    && install -m755 /app/update-alternatives-clang.sh /usr/local/bin/update-alternatives-clang \
    \
    && sed -i 's/http:/https:/g' /etc/apt/sources.list

RUN --mount=type=tmpfs,target=/tmp \
    --mount=type=tmpfs,target=/var/lib/apt \
    --mount=type=tmpfs,target=/var/cache/apt \
    \
    apt-get update && apt-get full-upgrade -yqq --auto-remove --purge \
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
        libegl1-mesa \
        libgl1-mesa-glx \
        liblua5.4-dev \
        libluajit-5.1-dev \
        libnss-myhostname \
        libpython3-dev \
        libssl-dev:amd64 \
        libssl-dev:arm64 \
        libssl-dev:armhf \
        libtool \
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
        mkcert \
        nala \
        nano \
        nasm \
        ncurses-base \
        neofetch \
        netcat-openbsd \
        ninja-build \
        nodejs \
        openssh-client \
        p7zip \
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
        squashfs-tools \
        strace \
        sudo \
        swig \
        time \
        tree \
        tzdata \
        util-linux \
        uuid-runtime \
        valgrind \
        wget \
        zsh \
        zstd \
    \
    && update-alternatives-gcc ${GCC_VERSION} 60 2> /dev/null \
    && update-alternatives-clang ${LLVM_VERSION} 60 2> /dev/null \
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
    && apt-get autoremove --purge -yqq

ARG MAKEFLAGS="-j4"
ARG CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -g -DNDEBUG -pthread -fPIC -DPIC \
-fno-plt -fexceptions -fstack-clash-protection -fcf-protection \
-falign-functions=32 -ftree-vectorize -ftree-slp-vectorize \
-Wp,-D_FORTIFY_SOURCE=3 -Wformat -Werror=format-security -Wno-stringop-overflow \
-D_GNU_SOURCE -D_LARGE_FILES -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -D_TIME_BITS=64"
ARG CXXFLAGS="${CFLAGS} -Wp,-D_GLIBCXX_ASSERTIONS"
ARG LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now,-z,pack-relative-relocs"

# how-to-use-pvs-studio-free
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch https://github.com/viva64/how-to-use-pvs-studio-free.git \
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
        | tar xz && install -m755 starship /usr/local/bin/starship

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

# zsh-syntax-highlighting
RUN --mount=type=tmpfs,target=/tmp share_dir=/usr/share/zsh/plugins/zsh-syntax-highlighting \
    && git clone --depth 1 --single-branch https://github.com/zsh-users/zsh-syntax-highlighting.git \
    && make -C zsh-syntax-highlighting install \
        PREFIX=/usr \
        DOC_DIR="$(mktemp -d)" \
        SHARE_DIR="${share_dir}" \
    && ln -s zsh-syntax-highlighting.zsh "${share_dir}/zsh-syntax-highlighting.plugin.zsh"

# zsh-autosuggestions
RUN --mount=type=tmpfs,target=/tmp share_dir=/usr/share/zsh/plugins/zsh-autosuggestions \
    && git clone --depth 1 --single-branch https://github.com/zsh-users/zsh-autosuggestions.git \
    && make -C zsh-autosuggestions \
    && install -Dm644 zsh-autosuggestions/zsh-autosuggestions.zsh "${share_dir}/zsh-autosuggestions.zsh" \
    && ln -s zsh-autosuggestions.zsh "${share_dir}/zsh-autosuggestions.plugin.zsh"

# ble.sh
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch --recurse-submodules https://github.com/akinomyoga/ble.sh.git \
    && make -C ble.sh install PREFIX=/usr INSDIR_DOC="$(mktemp -d)"

# git-delta
RUN --mount=type=tmpfs,target=/tmp version=0.15.1 name=git-delta_${version}_amd64 \
    && curl -fsSLO https://github.com/dandavison/delta/releases/download/${version}/${name}.deb \
    && dpkg -i ${name}.deb

# locales
ENV LANG en_US.UTF-8
RUN sed -i "s/# ${LANG} UTF-8/${LANG} UTF-8/" /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="${LANG}"
