## 仿真
### 汇编编程
支持 tinyrv-isa.txt 里的所有指令，汇编文件放在 tb 目录

#### 检查结果正确性
示例程序 loop.s：
```asm
# PROGRAM ------------------------------------
# accumulate 1..10
# --------------------------------------------

addi x1,x0,55
csrw 0x7c0 ,x1          # expected value 55

_start:
    addi t0, x0, 0x1
    addi t1, x0, 0x0
    addi t3, x0, 0xa
loop:
    add t1, t1, t0
    addi t0, t0, 0x1
    addi t3, t3, -1
    bne t3, x0, loop
    csrw 0x7c0 t1       # give out result for mngr to check......
NOPS:
    jal x0, NOPS
    nop
    nop
    nop
    nop
    nop

```
此程序计算从1累加到10的结果。如果希望其检查结果的正确性，需要进行两个
步骤：
1. 在程序开始时，把预期值写入 0x7c0 csr
2. 在程序得出结果后，再把运算结果写入 0x7c0 csr。
测试平台会比较两次写入值，不一样就报错。

### 运行仿真
以下操作需要有的环境：
+ Icarus Verilog
+ make
+ Python3 (和用到的库）

DUT有两种，核和带cache的核。如果想仿真一个汇编程序，比如 loop.s:
```bash
$ make proc.loop    # 使用proc DUT运行loop.s汇编文件
$ make procwc.loop  # 使用proc_with_cache DUT运行loop.s汇编文件
$ make all.loop     # 两个都用......
```
#### 查看波形
波形文件在 build 目录，VCD格式，可以使用 GTKWave 打开。

### 其他
#### 汇编汇编和查看结果
以汇编 loop.s 文件为例
```bash
$ make asm.loop
```
结果在 build/code.bin

#### 使用其他仿真软件
+ vcs：应该改一下makefile就行了
+ 其他： 没用过

## 相关内容
### 参考了的
+ [ECE 4750 Computer Architecture
Fall 2021](https://www.csl.cornell.edu/courses/ece4750/index.html)
+ https://github.com/bhwu/ece4750
+ https://github.com/violag12/ECE4750-Processor-Project
### 使用了的
+ [riscv-assembler](https://github.com/kcelebi/riscv-assembler)（做了一些修改）
+ [RISCV-RV32I-Assembler](https://github.com/metastableB/RISCV-RV32I-Assembler)（不再使用了）

