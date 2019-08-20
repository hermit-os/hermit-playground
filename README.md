<img width="100" align="right" src="img/hermitcore_logo.png" />


# HermitCore-rs - A Rust-based, lightweight unikernel for a scalable and predictable runtime behavior

[![Build Status](https://git.rwth-aachen.de/acs/public/hermitcore/hermit-playground/badges/master/pipeline.svg)](https://git.rwth-aachen.de/acs/public/hermitcore/hermit-playground/pipelines)
[![Slack Status](https://radiant-ridge-95061.herokuapp.com/badge.svg)](https://radiant-ridge-95061.herokuapp.com)

[HermitCore]( http://www.hermitcore.org ) is a new
[unikernel](http://unikernel.org) targeting a scalable and predictable runtime
for high-performance and cloud computing.
We decided to develop a version of the kernel in [Rust](https://www.rust-lang.org) .
We promise that this will make it easier to maintain and extend our kernel.
All code beside the kernel can still be developed in your preferred language (C/C++/Go/Fortran).

This repository contains the Rust-based playground for HermitCore.
Currently, it isn't stable and does not support all features of the [C-based version](https://github.com/hermitcore/libhermit).
However, it is a starting point and runs within a hypervisor.
The multi-kernel approach has not yet been tested in it.

## Requirements

The build process works currently only on **x86-based Linux** systems. To build
the HermitCore-rs kernel and applications you need:

 * CMake
 * Netwide Assember (NASM)
 * Recent host compiler such as GCC
 * HermitCore cross-toolchain, i.e. Binutils, GCC, newlib, pthreads
 * [Rust compiler (nightly release)](https://www.rust-lang.org/en-US/install.html)
 * [cargo-xbuild](https://github.com/rust-osdev/cargo-xbuild), which can be installed with `cargo install cargo-xbuild`
 * Rust source code for cross-compiling, which can be installed with `rustup component add rust-src`.

### HermitCore-rs cross-toolchain

We provide prebuilt packages (currently Ubuntu 18.04 only) of the HermitCore-rs
toolchain. The packages can be installed as follows:

```bash
$ echo "deb [trusted=yes] https://dl.bintray.com/hermitcore/ubuntu bionic main" | sudo tee -a /etc/apt/sources.list
$ sudo apt-get -qq update
$ sudo apt-get install binutils-hermit newlib-hermit-rs pte-hermit-rs gcc-hermit-rs libomp-hermit-rs
```

If you want to build the toolchain yourself, have a look at the `path2rs` branch of the repository
[hermit-toolchain](https://github.com/hermitcore/hermit-toolchain).
It contains scripts to build the whole toolchain for HermitCore-rs.

## Building

### Preliminary work

As a first step, the repository and its submodules have to be cloned:

```bash
$ git clone git@github.com:hermitcore/hermit-playground.git
$ cd hermit-playground
$ git submodule init
$ git submodule update
```

### Building the library operating systems and its examples

To build the Rust-based kernel and its examples, go to the directory with the source code
and issue the following commands:

```bash
$ mkdir build
$ cd build
$ cmake ..
$ make
$ sudo make install
```

If your toolchain is not located in `/opt/hermit/bin` then you have to supply
its location to the `cmake` command above like so:

```bash
$ cmake -DTOOLCHAIN_BIN_DIR=/home/user/hermit/bin ..
```

Assuming that binaries like `x86_64-hermit-gcc` and friends are located in that
directory.
To install your new version in the same directory, you have to set the installation path and install HermitCore-rs as follows:

```bash
$ cmake -DTOOLCHAIN_BIN_DIR=/home/user/hermit/bin -DCMAKE_INSTALL_PREFIX=/home/user/hermit ..
$ make
$ make install
```

**Note:** If you use the cross compiler outside of this repository, it uses the library operating system located
by the toolchain (e.g. `/opt/hermit/x86_64-hermit/lib/libhermit.a`).

## Proxy

Part of HermitCore is a small helper tool, which is called *proxy*.
This tool helps to start HermitCore applications within a virtual machine or bare-metal on a NUMA node.
In principle it is a bridge to the Linux system.
If the proxy is registered as loader to the Linux system, HermitCore applications can be started like common Linux applications.
The proxy can be registered with the following command:

```bash
$ sudo -c sh 'echo ":hermit:M:7:\\x42::/opt/hermit/bin/proxy:" > /proc/sys/fs/binfmt_misc/register'
```

Applications can then be directly called like:
```bash
$ /opt/hermit/x86_64-hermit/extra/tests/hello
```

Otherwise, the proxy must be started directly and needs the path to the HermitCore application as an argument:
```bash
$ /opt/hermit/bin/proxy /opt/hermit/x86_64-hermit/extra/tests/hello
```

Afterwards, the proxy starts the HermitCore application within a VM (and later bare-metal on a NUMA node)

## Testing

HermitCore applications can be directly started as a standalone kernel within a
virtual machine:

```bash
$ cd build
$ make install DESTDIR=~/hermit-build
$ cd ~/hermit-build/opt/hermit
$ bin/proxy x86_64-hermit/extra/tests/hello
```

The application will be started within our thin
hypervisor _uhyve_ powered by Linux's KVM API and therefore requires *KVM* support.
In principle, it is an extension of [ukvm](https://www.usenix.org/sites/default/files/conference/protected-files/hotcloud16_slides_williams.pdf) and part of our proxy.

The environment variable `HERMIT_CPUS` specifies the number of
CPUs (and no longer a range of core ids). Furthermore, the variable `HERMIT_MEM`
defines the memory size of the virtual machine. The suffixes *M* and *G* can be
used to specify a value in megabytes or gigabytes respectively. By default, the
loader initializes a system with one core and 2 GiB RAM.
For instance, the following command starts the stream benchmark in a virtual machine, which
has 4 cores and 6GB memory:

```bash
$ HERMIT_CPUS=4 HERMIT_MEM=6G bin/proxy x86_64-hermit/extra/benchmarks/stream
```

To enable an Ethernet device for `uhyve`, we have to setup a tap device on the
host system. For instance, the following command establishes the tap device
`tap100` on Linux:

```bash
$ sudo ip tuntap add tap100 mode tap
$ sudo ip addr add 10.0.5.1/24 broadcast 10.0.5.255 dev tap100
$ sudo ip link set dev tap100 up
$ sudo bash -c 'echo 1 > /proc/sys/net/ipv4/conf/tap100/proxy_arp'
```

By default, `uhyve`'s network interface uses `10.0.5.2`as IP address, `10.0.5.1`
for the gateway and `255.255.255.0` as network mask.
The default configuration can be overwritten by the environment variables
`HERMIT_IP`, `HERMIT_GATEWAY` and `HERMIT_MASk`.
To enable the device, `HERMIT_NETIF` must be set to the name of the tap device.
For instance, the following command starts an HermitCore application within `uhyve`
and enables the network support:

```bash
$ HERMIT_ISLE=uhyve HERMIT_IP="10.0.5.3" HERMIT_GATEWAY="10.0.5.1" HERMIT_MASK="255.255.255.0" HERMIT_NETIF=tap100 bin/proxy x86_64-hermit/extra/tests/hello
```

## Building your own HermitCore applications

You can take `usr/tests` as a starting point to build your own applications. All
that is required is that you include
`[...]/HermitCore/cmake/HermitCore-Application.cmake` in your application's
`CMakeLists.txt`. It doesn't have to reside inside the HermitCore repository.
Other than that, it should behave like normal CMake.

## Tips

### Dumping the kernel log

By setting the environment variable `HERMIT_VERBOSE` to `1`, the proxy prints
the kernel log messages to the screen at termination.

## Credits

HermitCore's Emoji is provided for free by [EmojiOne](https://www.gfxmag.com/crab-emoji-vector-icon/).

## License

Licensed under either of

 * Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
 * MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.

HermitCore-rs is being developed on [GitHub](https://github.com/hermitcore/hermit-playground	).
Create your own fork, send us a pull request, and chat with us on [Slack](https://radiant-ridge-95061.herokuapp.com)
