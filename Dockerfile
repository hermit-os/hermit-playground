FROM rust:buster as builder

RUN cargo install --git https://github.com/hermitcore/uhyve.git --locked uhyve


FROM ghcr.io/hermitcore/hermit-toolchain:latest as playground

COPY --from=builder $CARGO_HOME/bin/uhyve $CARGO_HOME/bin/uhyve
