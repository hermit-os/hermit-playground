FROM rust:buster as builder

RUN cargo install --git https://github.com/hermit-os/uhyve.git --locked uhyve


FROM ghcr.io/hermit-os/hermit-toolchain:latest as playground

COPY --from=builder $CARGO_HOME/bin/uhyve $CARGO_HOME/bin/uhyve
