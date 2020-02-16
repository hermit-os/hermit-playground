FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packets from ubuntu repository
RUN apt-get clean && apt-get -qq update && apt-get install -y apt-transport-https curl wget vim git binutils autoconf automake make cmake qemu-kvm qemu-system-x86 nasm gcc g++ build-essential libtool bsdmainutils libssl-dev python pkg-config lld swig python-dev libncurses5-dev

# Install HermitCore toolchain
RUN apt-get clean && apt-get -qq update && apt-get install -y --allow-unauthenticated binutils-hermit gcc-hermit-rs newlib-hermit-rs pte-hermit-rs gcc-hermit-rs libhermit-rs libomp-hermit-rs

# Install Rust toolchain
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly
RUN /root/.cargo/bin/cargo install cargo-download
RUN /root/.cargo/bin/cargo install uhyve
RUN /root/.cargo/bin/cargo install cargo-xbuild
RUN /root/.cargo/bin/rustup component add rust-src
RUN /root/.cargo/bin/rustup component add llvm-tools-preview

ENV PATH="/root/.cargo/bin:/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-unknown-linux-gnu/bin/:${PATH}"
ENV EDITOR=vim

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
