BUILD := build
RVIASM := python ./software/RISCV-RV32I-Assembler/src/rvi.py
AR     := python software/riscv-assembler/riscv_assembler/rvar_cli.py

# default target
proc.add:
cache: tb.cache
proc.%: 
	make asm.$* tb.proc
asm.%: tb/%.s
	$(AR) $< -o $(BUILD)/code.bin

tb.%:
	iverilog -g2012 -f flist.f -o build/$*_tb.vvp tb/$*_tb.sv
	cd $(BUILD) && vvp $*_tb.vvp

.PHNOY: asm.% tb.%