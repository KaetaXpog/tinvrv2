BUILD := build
RVIASM := python E:/code/hdl/Projects/riscv_refs/RISCV-RV32I-Assembler/src/rvi.py

proc.%: 
	make asm.$* tb.proc
asm.%: tb/%.s
	$(RVIASM) $< -o $(BUILD)/code.bin

tb.%:
	iverilog -g2012 -f flist.f -o build/$*_tb.vvp tb/$*_tb.sv
	cd $(BUILD) && vvp $*_tb.vvp

.PHNOY: asm.% tb.%