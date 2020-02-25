module pc
    ( input wire clock
    , input wire reset
    , input wire load
    , input wire[4:0] pc_i

    , output wire rmem
    , output wire[4:0] pc
    );

reg[7:0] q = 0;

assign rmem = !reset;
assign pc = q;

always @(reset) begin
    if (reset == 1) begin
        q <= 0;
    end
end

always @(posedge clock) begin
    if (reset == 1) begin
        q <= 0;
    end else if (load == 1) begin
        q <= pc_i;
    end else begin
        q <= q + 1;
    end
end

endmodule