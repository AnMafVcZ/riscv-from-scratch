RTL = ../rtl/core
TB  = ../tb/core

TEST     ?= hello
EXPECTED ?= 8
ARGS     ?=

verilate:
	verilator --cc --exe --build -Wall \
		-Wno-EOFNEWLINE -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN --public \
		$(RTL)/rv32i_top.sv \
		$(RTL)/regfile.sv \
		$(RTL)/alu.sv \
		$(RTL)/decode.sv \
		$(RTL)/lsu.sv \
		$(RTL)/csr.sv \
		$(TB)/tb_core.cpp \
		--top-module rv32i_top \
		-o sim_rv32i

run: verilate
	./obj_dir/sim_rv32i +HEX=../tests/$(TEST)_word.hex +EXPECTED=$(EXPECTED) $(ARGS)

clean:
	rm -rf obj_dir
