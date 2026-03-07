# Makefile to build UPduino v3.0 one_hz.v  with icestorm toolchain
# Original Makefile is taken from: 
# https://github.com/tomverbeure/upduino/tree/master/blink
# On Linux, copy the included upduinov3.rules to /etc/udev/rules.d/ so that we don't have
# to use sudo to flash the bit file.
# Thanks to thanhtranhd for making changes to thsi makefile.

one_hz.bin: one_hz.asc
	icepack one_hz.asc one_hz.bin

one_hz.asc: one_hz.json ../common/upduino.pcf
	nextpnr-ice40 --up5k --package sg48 --json one_hz.json --pcf ../common/upduino.pcf --asc one_hz.asc   # run place and route

one_hz.json: one_hz.v
	yosys -q -p "synth_ice40 -json one_hz.json" one_hz.v

.PHONY: flash
flash:
	iceprog -d i:0x0403:0x6014 one_hz.bin

.PHONY: clean
clean:
	$(RM) -f one_hz.json one_hz.asc one_hz.bin
