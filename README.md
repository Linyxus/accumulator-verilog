# AddMachine

`AddMachine` 是一个使用Verilog实现的累加器，并包含一个Haskell实现的简单汇编器。这个累加器非常简单，仅仅适用于教学与练习，算上`nop` 只有7条指令而已，其中包含了读写RAM，执行加法，无条件转移。

该累加器有8位数据，也即1字节。指令长度类似MIPS，是固定的，与数据同宽，也为1字节。为了简单地在无条件跳转中编码绝对地址，地址空间为5位，也即RAM的总容量仅为32字节。

ALU部件仅有一个，且只支持一种功能：加法。有一个8位寄存器用于保存结果，同时也可作为ALU的输入。这是累加器的常用设计。

该累加器包含的所有部件为：PC，PC寄存器，RAM，译码器，ALU，结果寄存器。

## 设计思路

该寄存器的设计参考了MIPS的设计思想，但由于结构与功能的简单，只需要两个流水线阶段：

- 取指 / 译码 / 读RAM / 读结果寄存器 / ALU
- 写RAM / 写结果寄存器 / 写PC与PC寄存器（无条件跳转）

由于流水线仅有两个阶段，可以考虑连续的两条指令：A与B。在某一个时钟上升沿到来时，A指令要写入RAM的数据，写入结果寄存器的数据（ALU的结果）将被打入对应存储电路；而同时，B指令对应的PC被打入PC寄存器，而取指、译码、读RAM、读结果寄存器、进行ALU的过程能够通过组合电路直接完成。B指令产生的效果将在下一个时钟上升沿被打入存储电路。

由于RAM的读取可以被设计为组合电路，在A指令第二阶段被写入RAM的数据在B指令的第一阶段即可访问到。因而指令之间无互锁。

而对于跳转指令的实现，由于流水线非常简单，事实上可以消除MIPS中流水线的分支延迟槽 (branching delay slot)，但延迟槽是MIPS流水线的一大特色，因而在该累加器的设计中被保留了。也即，在执行跳转指令时，在下一个时钟上升沿将目标地址打入PC，此时跳转指令下一条指令所对应的地址已被打入PC寄存器。因而无条件跳转指令的下一条指令必定会被执行。

## 指令与汇编语言

### 指令

该累加器支持的指令共有7条，分为两种格式：第一种，立即数型，前4位编码指令类型，后4位给出立即数，立即数会被零扩展到8位后进入ALU。第二种，地址型，前3位编码指令类型，后5位给出跳转目标的绝对地址。使用指令的第一位来区分两种指令，第一种的第一位为0，第二种为1。

- `nop` 无操作。编码：`00000000`
- `add {addr:5}` 地址为`addr`的RAM数据与结果寄存器中数据做加法。编码：`100{addr:5}`。
- `addi {imm:4}` `imm`编码立即数与结果寄存器中数据做加法。编码：`0010{imm:4}`。
- `load {addr:5}` 将RAM中`addr`处数据加载到结果寄存器中。编码：`101{addr:5}`。
- `loadi {imm:4}` 将`imm`编码的立即数写入结果寄存器。编码：`0001{imm:4}`。
- `store {addr:5}` 将结果寄存器中数据写入RAM的`addr`处。编码：`110{addr:5}`。
- `jumpi {addr:5}` 跳转到`addr`处。编码：`111{addr:5}`。

### 汇编语言

例（计算斐波那契数列）：

```
.begin load .a
add .b
store .t
load .b
store .a
load .t
store .b
jumpi .begin
nop
.a value $1
.b value $1
.t value $0
```

该语言中，一行将确切地对应编译出的二进制串中的一个字节。每一行都是一个指令：首先是指令标示符，后面是参数。

类似于x86的汇编语言，为该寄存器设计的汇编语言中，在数字前添加`$`表示为立即数，否则表示地址。

可以用`.`开头的字符串（如例子中的`.a, .b, .t`）来标示一个标签。标签作为指令的参数时，汇编器将会把他们替换为对应的地址。

所有指令都已在上文说明，唯一值得注意的是`value`指令，这是一个伪指令，汇编器会把立即数参数转化为一个字节的二进制串，填充在机器代码的对应位置。

注意，立即数都为无符号十进制数，溢出的部分将会被截断。

```
lowerAlphaChar ::= 'a' .. 'z' 
alphaNumChar ::= 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9'

nop ::= 'nop'
immOp ::= 'addi' | 'loadi'
addrOp ::= 'add' | 'load' ｜ 'store' | 'jumpi' | 'value'

tag ::= '.' lowerAlphaChar alphaNumChar*

integer ::= ('0' .. '9')*
imm ::= '$' integer
addr ::= integer | tag

nopInst = nop
immInst = immOp ' ' imm
addrInst = addrOp ' ' addr

inst ::= [tag] (nopInst | immInst | addrInst)

code ::= inst ('\n' inst)*
```

## 安装与使用

### 依赖

- make
- icarus verilog
- haskell (the assembler is a haskell script)
- (optional) gtkwave (to inspect wave graphs)

### 运行

编译：
```
make all
```

运行testbench：
```
make test
```

汇编：
```
make as
```