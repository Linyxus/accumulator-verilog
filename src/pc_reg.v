module pc_reg
    ( input wire clock
    , input wire reset
    , input wire[4:0] pc_i
    , input wire rmem_i
    
    , output wire[4:0] pc_o
    , output wire rmem_o
    );

reg[4:0] pc_q = 0;
reg rmem_q = 0;

assign pc_o = reset == 1 ? 0 : pc_q;
assign rmem_o = reset == 1 ? 0 : rmem_q;

always @(posedge clock) begin
    if (reset == 1) begin
        pc_q <= 0;
        rmem_q <= 0;
    end else begin
        pc_q <= pc_i;
        rmem_q <= rmem_i;
    end
end

endmodule