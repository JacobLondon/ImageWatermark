`timescale 1ns / 1ps

//module Processor;
module Processor(clk, regout_pix, image_pix, water_pix, waiting, done);
input clk;
input [11:0] image_pix;
input [11:0] water_pix;
input waiting;
output done;
output [11:0] regout_pix;

reg [31:0] in1;
reg [31:0] in2;
reg [4:0] addr3;
reg [31:0] data3;
reg chksignal;      // tell when to jump
reg [31:0] in;
reg [31:0] address;

wire [5:0] opcode;
wire [4:0] shamt;
wire [5:0] funct;
wire [31:0] pc;
wire [31:0] inst;
wire [4:0] rs;
wire [4:0] rt;
wire [4:0] rd;
wire [15:0] addr;
wire [31:0] result;
wire [31:0] Rs;
wire [31:0] Rt;
wire [31:0] out;
wire [31:0] extendaddr;
wire [31:0] newpc;

wire [31:0] difference;

// vga connection
wire [31:0] regout;
wire [11:0] imagein;
wire [11:0] waterin;
wire [11:0] counter;
// test pixel averaging
//reg [11:0] image_pix;
//reg [11:0] water_pix;
/*initial begin
    image_pix = 12'b111111111111;
    water_pix = 12'b111111111111;
end*/

assign imagein = image_pix;
assign waterin = water_pix;
assign regout_pix = regout[11:0];

// generate a clock waveform
//Clock CLK(clk);
// increment pc and control jumping
PC pc_(pc, in, clk);
PC_ALU pc_alu(newpc, pc, extendaddr, chksignal);
// memory for registers, instructions, and data
RegisterFile register_file(rw, rs, rt, Rs, Rt, addr3, data3, clk, regout, imagein, waterin, waiting, done);
InstructionMemory inst_mem(inst, pc, clk);
DataMemory data_mem(opcode, Rt, address, clk, out);
// split instructions based on R, I, J type
Splitter split(inst, opcode, rs, rt, rd, shamt, funct, addr);
// perform operations based on opcode
ALU alu_(opcode, shamt, funct, in1, in2, result, rw, clk, difference);
// extend sign of the address
SignExtend sign_extend(addr, extendaddr);


// program loop
always @(*) begin

    // ALU operation
    if(opcode == 6'b000000) begin
        // functions' opcodes
        if(funct == 6'b100000       // ADD
            || funct == 6'b100010   // SUB
            || funct == 6'b100100   // AND
            || funct == 6'b100101   // OR
            || funct == 6'b000010   // LSR
            || funct == 6'b000000)  // LSL
        begin
            // perform the R operation
            in1 = Rs;
            in2 = Rt;
            addr3 = rd;         // write address from RegisterFile
            data3 = result;     // load
            chksignal = 1'b0;   // don't jump
            in = newpc;         // go to next instruction

        end
    end

    // LW, load word
    else if(opcode == 6'b100011) begin
        in1 = Rs;
        in2 = extendaddr;
        address = result;
        addr3 = rt;
        data3 = out;
        chksignal = 1'b0;
        in = newpc;
    end

    // SW, store word
    else if(opcode == 6'b101011) begin
        in1 = Rs;
        in2 = extendaddr;
        address = result;
        chksignal = 1'b0;
        in = newpc;
    end

    // BEQ, branch on equals
    else if(opcode == 6'b000100) begin
        in1 = Rs;
        in2 = Rt;
        chksignal = 1'b0;

        // if EQ, then jump
        if(difference == 32'b00000000000000000000000000000000) begin
            chksignal = 1'b1;
            in = newpc;
        end
    end

    // BNE, branch not equals
    else if(opcode == 6'b000101) begin
        in1 = Rs;
        in2 = Rt;
        chksignal = 1'b0;

        // if NE, then jump
        // doesn't work with result, only with difference
        if(difference != 32'b00000000000000000000000000000000) begin
            chksignal = 1'b1;
            in = newpc;
        end
    end

end

/*
TEST VARS:
regout
*/
initial begin
    $monitor("pc = %5d | inst=%b | in1 = %5d | in2 = %5d | result = %12d | time=%5d | clk = %5d | regout = %12d | counter = %12d",
        pc, inst, in1, in2, result, $time, clk, regout, counter);
    #150
    $finish;
end

endmodule
