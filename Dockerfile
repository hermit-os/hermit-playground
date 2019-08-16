FROM rwthos/hermit-cargo:latest

ENV DEBIAN_FRONTEND=noninteractive

# Update Software repository
RUN apt-get clean 
RUN apt-get -qq update

# Install required packets from ubuntu repository
RUN apt-get install -y --allow-unauthenticated binutils-hermit gcc-hermit-rs newlib-hermit-rs pte-hermit-rs gcc-hermit-rs libhermit-rs libomp-hermit-rs

RUN PATH="/opt/hermit/bin:/root/.cargo/bin:${PATH}" /root/.cargo/bin/cargo install cargo-xbuild
