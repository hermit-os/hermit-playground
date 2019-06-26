# Download base image ubuntu 18.04
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

# Update Software repository
RUN apt-get clean 
RUN apt-get -qq update

# Install required packets from ubuntu repository
RUN apt-get install -y apt-transport-https curl wget vim git binutils autoconf automake make cmake qemu-kvm qemu-system-x86 nasm gcc g++ build-essential libtool bsdmainutils libssl-dev python pkg-config lld

# add path to hermitcore packets
RUN echo "deb [trusted=yes] https://dl.bintray.com/hermitcore/ubuntu bionic main" | tee -a /etc/apt/sources.list

# Update Software repository
RUN apt-get -qq update

# Install required packets from ubuntu repository
RUN apt-get install -y --allow-unauthenticated binutils-hermit newlib-hermit-rs pte-hermit-rs gcc-hermit-rs libhermit-rs libomp-hermit-rs

# Install Rust toolchain
RUN git clone --depth 1 -b hermit https://github.com/hermitcore/rust.git
RUN wget https://git.rwth-aachen.de/acs/public/hermitcore/hermit-playground/raw/devel/target/config.toml
RUN mv config.toml rust
RUN cd rust && ./x.py install
RUN PATH="/opt/hermit/bin:/root/.cargo/bin:${PATH}" /root/.cargo/bin/cargo install cargo-xbuild
RUN PATH="/opt/hermit/bin:/root/.cargo/bin:${PATH}" /root/.cargo/bin/cargo install --git https://github.com/hermitcore/objmv.git
RUN PATH="/opt/hermit/bin:/root/.cargo/bin:${PATH}" /root/.cargo/bin/cargo install --git https://github.com/hermitcore/pci_ids_parser.git

ENV PATH="/opt/hermit/bin:/root/.cargo/bin:${PATH}"
ENV XARGO_RUST_SRC="/rust/src"
ENV EDITOR=vim
