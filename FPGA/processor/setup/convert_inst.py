"""
Instruction set:
http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html
http://www.dsi.unive.it/~gasparetto/materials/MIPS_Instruction_Set.pdf

Instructions to Hex:
http://www.kurtm.net/mipsasm/index.cgi

Opcode list:
https://opencores.org/projects/plasma/opcodes
"""

import sys

# name of 2D Verilog array
mem_name = 'memdata'

"""Convert from hex instructions to binary"""

args = iter(sys.argv)
next(args)
f = next(args)
hex_insts = open(f, 'r')

bits = 32   # how many bits each instruction is
base = 16   # base to convert to
output = ''
BEGIN, END = ('begin', 'end')

converted_binary_insts = []
reading = False

for inst in hex_insts.readlines():

    output += inst

    if BEGIN in inst and inst.index(BEGIN) == 0:
        reading = True
        continue
    
    if END in inst and inst.index(END) == 0:
        reading = False
        break
    
    if reading:
        binary = bin(int(inst, base))[2:].zfill(bits)
        converted_binary_insts.append(binary)

output += '\n\n'

for line_no, inst in enumerate(converted_binary_insts):
    output += f"{mem_name}[{line_no}] = {bits}'b{inst};\n"

print(output)
hex_insts.close()

with open(f, 'w') as formatted_insts:
    formatted_insts.write(output)
