FROM ubuntu:20.04
ARG VERSION=unknown

LABEL maintainer="eduard.c.staniloiu@gmail.com" \
      name="Druntime for Microcontrollers" \
      version="${VERSION}"

WORKDIR /root

# Install missing packages and required dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y wget git

RUN apt-get install -y curl

RUN apt-get install -y build-essential

RUN apt-get install -y gcc-arm-none-eabi

RUN apt-get install -y iputils-ping

RUN apt-get install telnet

RUN DEBIAN_FRONTEND="noninteractive" TZ=Europe/Bucharest apt-get install -y mono-runtime

RUN ["/bin/bash", "-c", "echo \"nameserver 8.8.8.8\" > /etc/resolv.conf; cat /etc/resolv.conf; \
    wget https://dlang.org/install.sh && chmod +x install.sh && ./install.sh ldc"]

RUN apt-get install -y libxml2 vim

RUN apt-get install -y mono-complete

RUN apt-get install -y gdb gdb-multiarch

RUN apt-get install -y openocd

RUN ["/bin/bash", "-c", "git clone https://github.com/renode/renode.git && \
    cd renode && \
    ./build.sh --no-gui"]


RUN sed -i -e 's/showAnalyzer sysbus.uart4/showAnalyzer sysbus.uart2/g' /root/renode/scripts/single-node/stm32f4_discovery.resc && \
    sed -i -e 's/$bin?=@https:\/\/dl.antmicro.com\/projects\/renode\/stm32f4discovery.elf-s_445441-827a0dedd3790f4559d7518320006613768b5e72/$bin?=@\/root\/tock_d\/tock\/target\/thumbv7em-none-eabi\/debug\/stm32f4discovery_renode-app.elf/g' /root/renode/scripts/single-node/stm32f4_discovery.resc

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o sh.rustup.rs && chmod +x sh.rustup.rs && ./sh.rustup.rs -y

RUN ["/bin/bash", "-c", "source $HOME/.cargo/env && cargo install -f elf2tab"]

RUN rm -rf tock_d && mkdir tock_d && cd tock_d && \
    git clone https://github.com/UPBIoT/tock.git && \
    git clone --recursive https://github.com/DLang-IoT/libtock-d.git && \
    git clone --recursive https://github.com/teonaseverin/CMakeListsDRuntime.git DRuntime

RUN ["/bin/bash", "-c", "source ~/dlang/ldc-*/activate && \
    source $HOME/.cargo/env && \
    cd tock_d/libtock-d && \
    git checkout renode_work && \
    cd libtock && \
    make && \
    cd ~/tock_d/tock/ && \
    git checkout renode_tester && \
    mv Makefile_auto ../Makefile"]