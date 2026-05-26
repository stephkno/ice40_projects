top.bin: top.asc
	icepack top.asc top.bin

top.asc: top.json ../common/upduino.pcf
	nextpnr-ice40 --up5k --package sg48 --json top.json --pcf ../common/upduino.pcf --asc top.asc 

top.json: uart.v top.v
	yosys -q -p "synth_ice40 -top top -flatten; clean -purge; write_json top.json" top.v uart.v

flash:
	sudo iceprog top.bin

clean:
	$(RM) -f top.json top.asc top.bin