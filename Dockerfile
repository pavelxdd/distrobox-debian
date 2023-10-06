# syntax=docker/dockerfile:1
FROM docker.io/amd64/debian:sid as debian
WORKDIR /tmp

ARG LANG=C.UTF-8
ARG LANGUAGE=${LANG}
ARG LC_ALL=${LANG}

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ENV NPM_CONFIG_AUDIT=false
ENV NPM_CONFIG_FUND=false

ARG GCC_VERSION=13
ARG LLVM_VERSION=17
ARG NODE_VERSION=20

RUN --mount=type=bind,target=/app \
    --mount=type=tmpfs,target=/tmp \
    \
    rm -f \
        /etc/apt/sources.list.d/* \
        /etc/apt/preferences \
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
    && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
        | gpg --no-tty --dearmor -o /etc/apt/trusted.gpg.d/llvm.gpg \
    && printf "deb [arch=amd64] %s %s\n" \
              "https://apt.llvm.org/unstable/" \
              "llvm-toolchain-${LLVM_VERSION} main" > /etc/apt/sources.list.d/llvm.list \
    && printf "Package: *\nPin: origin %s\nPin-Priority: %s\n" \
              "apt.llvm.org" "900" > /etc/apt/preferences.d/llvm \
    \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --no-tty --dearmor -o /etc/apt/trusted.gpg.d/nodesource.gpg \
    && printf "deb [arch=amd64] %s %s\n" \
              "https://deb.nodesource.com/node_${NODE_VERSION}.x" \
              "nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && printf "Package: *\nPin: origin %s\nPin-Priority: %s\n" \
              "deb.nodesource.com" "900" > /etc/apt/preferences.d/nodesource \
    \
    && curl -fsSL https://cdn.pvs-studio.com/etc/pubkey.txt \
        | gpg --no-tty --dearmor -o /etc/apt/trusted.gpg.d/viva64.gpg \
    && printf "deb [arch=amd64] %s %s\n" \
              "https://cdn.pvs-studio.com/deb" \
              "viva64-release pvs-studio" > /etc/apt/sources.list.d/viva64.list \
    \
    && sed -i "s/http:/https:/g" /etc/apt/sources.list \
    \
    && apt-get update \
    && apt-get full-upgrade -yqq --auto-remove --purge \
    && apt-get install -yqq --no-install-recommends \
        apt-utils \
        archlinux-keyring \
        astyle \
        autoconf \
        autoconf-archive \
        automake \
        autopoint \
        bash \
        bash-completion \
        bc \
        bind9-dnsutils \
        bison \
        build-essential \
        clang-${LLVM_VERSION} \
        cmake \
        deborphan \
        dialog \
        diffutils \
        file \
        findutils \
        flex \
        htop \
        gawk \
        gcc-${GCC_VERSION} \
        g++-${GCC_VERSION} \
        gcc-${GCC_VERSION}-arm-linux-gnueabihf \
        g++-${GCC_VERSION}-arm-linux-gnueabihf \
        gcc-${GCC_VERSION}-aarch64-linux-gnu \
        g++-${GCC_VERSION}-aarch64-linux-gnu \
        gdb-multiarch \
        gdbserver \
        gettext \
        git \
        gnupg2 \
        iproute2 \
        ipset \
        iptables \
        iputils-ping \
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
        makepkg \
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
        ninja-build \
        nodejs \
        openssh-client \
        pacman-package-manager \
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
        traceroute \
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
    && install -m755 /app/update-alternatives-gcc.sh \
        /usr/local/bin/update-alternatives-gcc \
    && update-alternatives-gcc "${GCC_VERSION}" 60 2> /dev/null \
    \
    && install -m755 /app/update-alternatives-clang.sh \
        /usr/local/bin/update-alternatives-clang \
    && update-alternatives-clang "${LLVM_VERSION}" 60 2> /dev/null \
    \
    && update-alternatives --force --set editor /bin/nano \
    \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/flatpak \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/flatpak-bisect \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/flatpak-coredumpctl \
    \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/podman \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/podman-remote \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/podman-compose \
    && ln -s /usr/local/bin/host-spawn /usr/local/bin/buildah \
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

RUN --mount=type=bind,target=/app \
    --mount=type=tmpfs,target=/tmp \
    \
    pacman --version \
    \
    && install -m644 /app/pacman.conf /etc/pacman.conf \
    && install -Dm644 /app/mirrorlist /etc/pacman.d/mirrorlist \
    \
    && pacman-key --init \
    && pacman-key --populate archlinux \
    && pacman -Syyuudd --noconfirm \
        luacheck \
        lua-lanes \
        lua-argparse \
        lua-filesystem \
        starship \
    \
    && pacman -Scc --noconfirm

# how-to-use-pvs-studio-free
RUN --mount=type=tmpfs,target=/tmp \
    git clone --depth 1 --single-branch https://github.com/viva64/how-to-use-pvs-studio-free.git \
    && sed -i '1s;^;#include <cstdint>\n;' how-to-use-pvs-studio-free/comments.h \
    && cmake -Wno-dev \
        -G Ninja \
        -S how-to-use-pvs-studio-free \
        -B how-to-use-pvs-studio-free/build \
        -D CMAKE_CXX_COMPILER=clang++ \
        -D CMAKE_BUILD_TYPE=Release \
        -D PVS_STUDIO_SHARED=OFF \
    && cmake --build how-to-use-pvs-studio-free/build \
    && cmake --install how-to-use-pvs-studio-free/build --prefix /usr/local \
    && strip -s /usr/local/bin/how-to-use-pvs-studio-free

# hadolint
ADD --chmod=755 --chown=root:root \
    https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 \
    /usr/local/bin/hadolint

# host-spawn
ADD --chmod=755 --chown=root:root \
    https://github.com/1player/host-spawn/releases/latest/download/host-spawn-x86_64 \
    /usr/local/bin/host-spawn

# locales
ENV LANG en_US.UTF-8
RUN sed -i "s/# ${LANG} UTF-8/${LANG} UTF-8/" /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="${LANG}"
