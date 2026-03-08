# Makefile to build UPduino v3.0 uart.v  with icestorm toolchain
# Original Makefile is taken from: 
# https://github.com/tomverbeure/upduino/tree/master/blink
# On Linux, copy the included upduinov3.rules to /etc/udev/rules.d/ so that we don't have
# to use sudo to flash the bit file.
# Thanks to thanhtranhd for making changes to thsi makefile.

uart.bin: uart.asc
	icepack uart.asc uart.bin

uart.asc: uart.json ../common/upduino.pcf
	nextpnr-ice40 --up5k --package sg48 --json uart.json --pcf ../common/upduino.pcf --asc uart.asc   # run place and route

uart.json: uart.v
	yosys -q -p "synth_ice40 -json uart.json" uart.v

.PHONY: flash
flash:
	iceprog -d i:0x0403:0x6014 uart.bin

.PHONY: clean
clean:
	$(RM) -f uart.json uart.asc uart.bin
