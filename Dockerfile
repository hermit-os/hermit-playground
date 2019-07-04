FROM rwthos/hermitcore-rs

ENV DEBIAN_FRONTEND=noninteractive

# Update Software repository
RUN apt-get -qq update

# Install Rust toolchain
#RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain nightly
RUN /opt/rust/bin/cargo install cargo-xbuild
RUN /opt/rust/bin/rustup component add rust-src
RUN /opt/rust/bin/cargo install --git https://github.com/hermitcore/objmv.git
RUN /opt/rust/bin/cargo install --git https://github.com/hermitcore/pci_ids_parser.git

#ENV PATH="/opt/hermit/bin:/root/.cargo/bin:${PATH}"
#ENV EDITOR=vim
