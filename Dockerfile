FROM rwthos/hermitcore-rs

ENV DEBIAN_FRONTEND=noninteractive

# Update Software repository
RUN apt-get clean 
RUN apt-get -qq update

RUN PATH="/opt/hermit/bin:/opt/rust/bin:${PATH}" /opt/rust/bin/cargo install cargo-xbuild
RUN PATH="/opt/hermit/bin:/opt/rust/bin:${PATH}" /opt/rust/bin/cargo install --git https://github.com/hermitcore/objmv.git
RUN PATH="/opt/hermit/bin:/opt/rust/bin:${PATH}" /opt/rust/bin/cargo install --git https://github.com/hermitcore/pci_ids_parser.git

ENV XARGO_RUST_SRC="/opt/rust/src"
ENV EDITOR=vim
