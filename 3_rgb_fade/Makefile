# Makefile to build UPduino v3.0 rgb_fade.v  with icestorm toolchain
# Original Makefile is taken from: 
# https://github.com/tomverbeure/upduino/tree/master/blink
# On Linux, copy the included upduinov3.rules to /etc/udev/rules.d/ so that we don't have
# to use sudo to flash the bit file.
# Thanks to thanhtranhd for making changes to thsi makefile.

rgb_fade.bin: rgb_fade.asc
	icepack rgb_fade.asc rgb_fade.bin

rgb_fade.asc: rgb_fade.json ../common/upduino.pcf
	nextpnr-ice40 --up5k --package sg48 --json rgb_fade.json --pcf ../common/upduino.pcf --asc rgb_fade.asc   # run place and route

rgb_fade.json: rgb_fade.v
	yosys -q -p "synth_ice40 -json rgb_fade.json" rgb_fade.v

.PHONY: flash
flash:
	iceprog -d i:0x0403:0x6014 rgb_fade.bin

.PHONY: clean
clean:
	$(RM) -f rgb_fade.json rgb_fade.asc rgb_fade.bin
