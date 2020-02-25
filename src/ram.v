module ram
    ( input wire clock
    , input wire re1
    , input wire[4:0] raddr1
    , input wire re2
    , input wire[4:0] raddr2
    , input wire we
    , input wire[4:0] waddr
    , input wire[7:0] wdata

    , output wire[7:0] rdata1
    , output wire[7:0] rdata2
    );

reg[7:0] data[0:31];
initial $readmemb("../data/ram.txt", data);

assign rdata1 = re1 == 0 ? 0 : data[raddr1];
assign rdata2 = re2 == 0 ? 0 : data[raddr2];

always @(posedge clock) begin
    if (we == 1) begin
        data[waddr] = wdata;
    end
end

endmodule