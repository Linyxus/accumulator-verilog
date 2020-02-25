`timescale 1ns / 1ps
module pc_tb;

reg clock = 0;
always #10 clock = !clock;
reg reset = 0;
reg load = 0;
reg[4:0] pc_i = 0;

wire[4:0] pc;
wire rmem;

wire[4:0] pc_o;
wire rmem_o;

pc pc0(clock, reset, load, pc_i, rmem, pc);
pc_reg pc_reg0(clock, reset, pc, rmem, pc_o, rmem_o);

initial begin
    $dumpfile("pc_tb.vcd");
    $dumpvars(0, pc_tb);
    clock = 0;
    reset = 0;
    load = 0;
    pc_i = 0;
    #995
    reset = 1;
    #150
    reset = 0;
    #995
    load = 1;
    pc_i = 15;
    #20
    load = 0;
    pc_i = 0;
    #100
    $finish();
end

endmodule