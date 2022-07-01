FROM rust:buster as builder

RUN cargo install --git https://github.com/hermitcore/uhyve.git --locked uhyve


FROM ghcr.io/hermitcore/hermit-toolchain:latest as playground

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        autoconf \
        automake \
        binutils \
        bsdmainutils \
        build-essential \
        cmake \
        curl \
        g++ \
        gcc \
        git \
        libncurses5-dev \
        libssl-dev \
        libtool \
        lld \
        make \
        nasm \
        pkg-config \
        python \
        python-dev \
        qemu-kvm \
        qemu-system-x86 \
        swig \
        vim \
        wget \
    ; \
    rm -rf /var/lib/apt/lists/*;

COPY --from=builder $CARGO_HOME/bin/uhyve $CARGO_HOME/bin/uhyve
