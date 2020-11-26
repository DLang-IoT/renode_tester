### Automatic testing environment using Docker and Renode emulator

Test D applications for TockOS, by emulating the STM32F4Discovery board using Renode. 

## Steps for emulating an application:

1. Clone this repository
2. ``` cd renode_tester && make run ```
3. After the container starts, run: ``` cd renode_1.11.0_portable && ./renode``` - this starts a telnet server on port 1234
4. In another terminal run ``` make bash``` in order to open a new bash session. After that, run ```telnet 127.0.0.1 1234```
5. When the connection is established, run in telnet ``` s @scripts/single-node/stm32f4_discovery.resc``` - this is the script through which the emulation begins. In order to change the .elf application, edit the renode_1.11.0_portable/scripts/single-node/stm32f4_discovery.resc file accordingly.
6. Ignore the `nvic` errors. Work is still in progress. 