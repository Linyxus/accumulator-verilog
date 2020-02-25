module addmachine
    ( input wire clock
    , input wire reset

    , output wire[7:0] res
    );

wire[4:0] pc_o;
wire pc_rmem_o;
wire[4:0] pc_reg_o;
wire pc_reg_rmem_o;

wire[7:0] id_val1_o;
wire[7:0] id_val2_o;
wire id_wmem_o;
wire[4:0] id_wmemaddr_o;
wire id_wresreg_o;
wire id_wpc_o;
wire[4:0] id_pc_o;
wire id_rmem_o;
wire[4:0] id_rmemaddr_o;

wire[7:0] ram_rdata1_o;
wire[7:0] ram_rdata2_o;

wire[7:0] resreg_o;

wire[7:0] alu_o;

pc pc0 (
    .clock(clock),
    .reset(reset),
    .load(id_wpc_o),
    .pc_i(id_pc_o),
    .rmem(pc_rmem_o),
    .pc(pc_o)
);

pc_reg pc_reg0 (
    .clock(clock),
    .reset(reset),
    .pc_i(pc_o),
    .rmem_i(pc_rmem_o),
    .pc_o(pc_reg_o),
    .rmem_o(pc_reg_rmem_o)
);

ram ram0 (
    .clock(clock),
    .re1(pc_reg_rmem_o),
    .raddr1(pc_reg_o),
    .re2(id_rmem_o),
    .raddr2(id_rmemaddr_o),
    .we(id_wmem_o),
    .waddr(id_wmemaddr_o),
    .wdata(resreg_o),

    .rdata1(ram_rdata1_o),
    .rdata2(ram_rdata2_o)
);

id id0 (
    .reset(reset),
    .pc(pc_reg_o),
    .inst(ram_rdata1_o),
    .resreg(resreg_o),
    .val_i(ram_rdata2_o),
    
    .val1(id_val1_o),
    .val2(id_val2_o),
    .wmem(id_wmem_o),
    .wmemaddr(id_wmemaddr_o),
    .wresreg(id_wresreg_o),
    .wpc(id_wpc_o),
    .pc_o(id_pc_o),
    .rmem(id_rmem_o),
    .rmemaddr(id_rmemaddr_o)
);

reg8 resreg (
    .clock(clock),
    .reset(reset),
    .load(id_wresreg_o),
    .data(alu_o),

    .y(resreg_o)
);

alu alu0 (
    .a(id_val1_o),
    .b(id_val2_o),

    .y(alu_o)
);

assign res = resreg_o;

endmodule