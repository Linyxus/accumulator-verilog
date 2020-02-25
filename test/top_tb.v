`timescale 1ns / 1ps
module top_tb;

reg clock = 0;
always #10 clock = !clock;
reg reset = 0;
wire[7:0] res;

addmachine add0 (
    .clock(clock),
    .reset(reset),
    .res(res)
);

initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
    clock = 0;
    reset = 1;
    #10
    reset = 0;
    #1000
    $finish();
end

endmodule