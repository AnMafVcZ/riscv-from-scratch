RTL = ../rtl/core
TB  = ../tb/core

verilate:
	verilator --cc --exe --build -Wall \
		-Wno-EOFNEWLINE -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN \
		$(RTL)/rv32i_top.sv \
		$(RTL)/regfile.sv \
		$(RTL)/alu.sv \
		$(RTL)/decode.sv \
		$(RTL)/lsu.sv \
		$(TB)/tb_core.cpp \
		--top-module rv32i_top \
		-o sim_rv32i

run: verilate
	./obj_dir/sim_rv32i

clean:
	rm -rf obj_dir
