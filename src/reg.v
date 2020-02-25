module reg8 
    ( input wire clock
    , input wire reset
    , input wire load
    , input wire[7:0] data

    , output wire[7:0] y
    );

reg[7:0] value = 0;

assign y = reset == 1 ? 0 : value;

always @(posedge clock) begin
    if (reset == 1) begin
        value <= 0;
    end else if (load == 1) begin
        value <= data;
    end
end

endmodule
