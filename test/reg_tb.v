`timescale 1ns / 1ps
module reg_tb;

reg clock = 0;
always #10 clock = !clock;
reg reset = 0;
reg load = 0;
reg[7:0] data = 0;
wire[7:0] y;

reg8 reg0 (
    .clock(clock),
    .reset(reset),
    .load(load),
    .data(data),
    .y(y)
);

initial begin
    $dumpfile("reg_tb.vcd");
    $dumpvars(0, reg_tb);
    clock = 0;
    reset = 0;
    load = 1;
    data = 1;
    #100
    reset = 1;
    #35
    reset = 0;
    #100
    $finish();
end

endmodule