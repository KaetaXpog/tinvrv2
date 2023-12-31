BUILD := build
RVIASM := python ./software/RISCV-RV32I-Assembler/src/rvi.py
AR     := python software/riscv-assembler/riscv_assembler/rvar_cli.py
GEN	   := python ./tb/gen_ram_data.py

# default target and short alias
sys.add: 
proc.add:
cache: tb.cache
proc: tb.proc

all.%:
	make asm.$* tb.proc tb.procwc
sys.%:
	make asm.$* tb.procwc
proc.%: 
	make asm.$* tb.proc
asm.%: tb/%.s
	$(AR) $< -o $(BUILD)/code.bin
	$(GEN) -r --ifname $(BUILD)/code.bin -o $(BUILD)/code.128b
unasm.%: tb/riscv_asm_unstd/%.s
	$(RVIASM) $< -o $(BUILD)/$*.un.bin
cmp.%: tb/%.s tb/riscv_asm_unstd/%.s
	make asm.$* unasm.$*
	diff $(BUILD)/code.bin $(BUILD)/$*.un.bin
tb.%:
	iverilog -g2012 -f flist.f -o build/$*_tb.vvp tb/$*_tb.sv
	cd $(BUILD) && vvp $*_tb.vvp

.PHNOY: asm.% tb.% sys.% proc.%