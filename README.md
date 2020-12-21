### Automatic testing environment using Docker and Renode emulator

This repository contains a Dockerfile which builds from an empty Ubuntu 20.04 docker image (~80MB) an automatic testing environment for D applications to be run on a microcontroller using [TockOS](https://www.tockos.org). The environment is based on [Renode](https://renode.io), an emulator that successfully runs ARM Cortex-M applications. The development board that is emulated is a STM32F4Discovery board.

## TockOS

TockOS is an open-source operating system that targets ARM Cortex-M and RISC-V-based microcontrollers. [TockOS](https://github.com/tock/tock) exposes a kernelspace written in Rust, and 2 official userlands:
1. [libtock-c](https://github.com/tock/libtock-c) - Userspace applications can be developed in C and C++.
2. [libtock-rs](https://github.com/tock/libtock-rs) - Userspace applications can be developed in Rust.
There is also an adaption of the libtock-c for the [D Language](https://dlang.org) developed by us: [libtock-d](https://github.com/DLang-IoT/libtock-d).
The D Language environment uses [Phobos](https://github.com/dlang/phobos) and [DRuntime](https://github.com/dlang/druntime), libraries that do not fit the small resources of a microcontroller. Currently, D code can be run on a microcontroller using the ```-betterC``` compilation flag. This way, the compiler doesn't rely on DRuntime anymore, but on C's standard library ([newlib](https://sourceware.org/newlib/)) and all key-features like classes and Garbage Collector are lost. 
Our current work is focused on developing a small-sized DRuntime that targets contraint devices.

## Prerequisites

Starting from the docker image, the following tools must be installed:

1. Basic CLI tools: `git`, `iputils-ping`, `vim`, `curl`, `build-essential`, `mono-complete`.
2. [GNU Arm Embedded Toolchain Downloads] (https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) - GNU tools for ARM-based target architectures, including:
    * ```arm-none-eabi-gcc``` - C compiler and linker.
    * ```arm-none-eabi-ld``` - Linker.
    * ```arm-none-eabi-objcopy``` - Copy and translate object files.
    * ```arm-none-eabi-objdump``` - Display information about object files.
3. [Rust](https://www.rust-lang.org/tools/install) programming language and environment.
4. ```ldc``` - LLVM-based D compiler.
3. ```openocd``` + ```gdb``` -Flash the final application on the board
4. Alternatively, you can use [tockloader](https://github.com/tock/tockloader) to flash an application, if there is support for the target board.
5. ```Renode``` emulator - installed from github source (explained later, at step 4).

## Compilating, linking and emulating an application:
We focus on developing D applications for TockOS:
1. Clone the kernel repository (`git clone https://github.com/UPBIoT/tock.git`)and recursively the D userspace repository(it depends on libtock-c - `git clone --recursive https://github.com/DLang-IoT/libtock-d.git`) in the same folder: `~/tock_d`.
2. `cd libtock-d/` & `git checkout renode_work` (the project is still in development and some features are not merged into the master repository yet). The most important folders are:
* `examples` is a folder with applications that can be compiled, linked and run/emulated on a microcontroller. The most relevant applications are:
    - `basic_example` - a simple application that is not linked with DRuntime (so DRuntime-dependent features are not available) and prints to the console a "Hello" message.
    - `betterC_example` - a simple application that is compiled with the `-betterC` flag, so the C standard library (newlib) will be used instead of D's DRuntime and Phobos libraries.
    - `linked_druntime_example` - an application that is in progress; this is an application that is linked with the DRuntime and the current goal is for this app to run correctly.
* The `libtock-c` folder is the official C userspace for TockOS and contains standard libraries and the userspace drivers through which an application can control and communicate with connected peripherals. 
    - `libtock-c/build/cortex-m` contains C and C++ ported standard libraries, and also a static `libm` library.
    - `libtock-c/build/cortex-m<0/3/4>` contains the userspace library for each supported target architecture.
* `libtock` contains D headers for each `libtock-c` library. 
3. We will be compiling the `basic_example` application. 
`cd examples/basic_example/ && make`. There will be generated a `build` folder (`examples/basic_example/build`) with a folder for each supported architecture: 
* `examples/basic_example/build/cortex-m0`
* `examples/basic_example/build/cortex-m3`
* `examples/basic_example/build/cortex-m4`.
In each folder, we find:
* `main.o` - depends on the architecture
* `cortex-m<0/3/4>`.elf/Map/tbf - the final userspace applications (already linked with the userspace library and the standard C/C++ libraries).
4. Now, we need to install and setup the emulation environment, `Renode`. Download the master repository running `git clone https://github.com/renode/renode.git` and then `cd renode`. Here, run `./build.sh --no-gui`. Some important components we find here are:
* `scripts` folder - contains device-specific scripts to be run on the emulator 
* `platforms` folder - contains files that describe the CPUs and the boards that can be emulated.

To be able to use the emulator, we need to modify some lines in some folders:
in the file `~/tock_d/renode/scripts/single-node/stm32f4_discovery.resc`, modify 
- "showAnalyzer sysbus.uart4" to "showAnalyzer sysbus.uart2" &
- "$bin?=@https://dl.antmicro.com/projects/renode/stm32f4discovery.elf-s_445441-827a0dedd3790f4559d7518320006613768b5e72" to "$bin?=@/root/tock_d/tock/target/thumbv7em-none-eabi/debug/stm32f412gdiscovery-apps.elf". (stm32f412gdiscovery-apps.elf is the name of the final application that will be generated after the linking process).

In order to easily modify this file (if we ever want to emulate some other application) without searching it always, we will copy it in the same folder as the resulting application. Run `cp scripts/single-node/stm32f4_discovery.resc /root/tock_d/tock/boards/stm32f412gdiscovery/`. 

5. We move on to the kernelspace, to compile the kernel and link the kernel app with the user app: `cd ~/tock_d/tock` && `git checkout renode_tester`. Depending on the board we are using, we will change directory to `boards\<board_name>`.
On our case, we will be emulating the `stm32f412gdiscovery` board, so just run `cd board/stm32f412gdiscovery` && `APP=~/tock_d/libtock-d/basic_example/build/cortex-m4/cortex-m4.tbf make program`. The kernel will be compiled and linked with the userspace application (that was given as argument). 
The `Renode` emulator will start and the application will run.

This project consists of 2 repositories and we want an automatic compilation, so I added a Makefile in the `tock` repository, that needs to be moved in the same folder as the 2 repositories: `mv Makefile_auto ../Makefile`.
To use it, run `APP_NAME=basic_example make userspace kernel`. 
## Steps for emulating an application:

1. Clone this repository: `git clone https://github.com/DLang-IoT/renode_tester.git`
2. ``` cd renode_tester && make build ``` - this will build the environment to emulate an application.
3. After the docker image is running, run:
`cd tock_d && LANG=d APP_NAME=<your_application_name> make userspace kernel` in order to compile and run the application. As the emulation process can be terminated only by killing the actual Linux process, type `CTRL+C` to end it.
4. Ignore the `nvic` errors. Work is still in progress. 

## Modifying the current DRuntime

If you want to modify the DRuntime that is linked with the application, the source code can be found at `/root/DRuntime/ldc-build-runtime.tmp/ldc-src/runtime/druntime/src` and the files that are compiled and linked together can be modified in the `/root/DRuntime/ldc-build-runtime.tmp/ldc-src/runtime/CMakeLists.txt/` (this is our current version and it is work in progress). 

After modifying the file, just run `cd DRuntime && make delete run`. The new library will be copied at the correct path in the `libtock-d` hierarchy also. 

## Emulate applications using GDB

If you want to emulate an application using `gdb-multicarch`, follow the next steps:
1. Run 3 docker images (using `make run` for the first one and `make bash` for the next 2).
2. In the 1st connection, run:
    * `cd ~/renode && ./renode` - a telnet monitor is created that is waiting for connections on port 1234.
3. In the 2nd connection, run:
    * `telnet 127.0.0.1 1234` - connect to the telnet monitor
    * `mach create`
    * `machine LoadPlatformDescription @platforms/cpus/stm32f4.repl` - load the emulated board's hardware description
    * `sysbus LoadELF @/root/tock_d/tock/target/thumbv7em-none-eabi/debug/stm32f4discovery-app.elf` - load the application
4. In the 3rd connection, run:
    * `arm-none-eabi-gdb stm32f4discovery-app.elf`
    * `target remote :3333` - connect to the emulator
    * add any breakpoints if you need
5. Switch back to the 2nd connection and run:
    * `start` - start the application
6. Switch again to the 3rd connection and run:
    * `monitor start` - start the serial connection (to see the emulated microcontroller's output)
    * `continue` - continue running the application.

In the 1st connection will be showed the output of the application. As this is still work in progress, there are some warnings that do not concert us at the moment (`nvic` errors and so on).