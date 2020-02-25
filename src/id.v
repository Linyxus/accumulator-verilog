module id
    ( input wire reset
    , input wire[4:0] pc
    , input wire[7:0] inst
    , input wire[7:0] resreg
    , input wire[7:0] val_i

    , output reg[7:0] val1
    , output reg[7:0] val2
    , output reg wmem
    , output reg[4:0] wmemaddr
    , output reg wresreg
    , output reg wpc
    , output reg[4:0] pc_o
    , output reg rmem
    , output reg[4:0] rmemaddr
    );

always @(*) begin
    if (reset == 1) begin
        val1 <= 0;
        val2 <= 0;
        wmem <= 0;
        wmemaddr <= 0;
        wresreg <= 0;
        wpc <= 0;
        pc_o <= 0;
        rmem <= 0;
        rmemaddr <= 0;
    end else if (inst[7] == 0) begin
        // non-addr inst
        case (inst[6:4])
            3'b001: begin // loadi: load immediate
                val1 <= 0;
                val2 <= {4'b0000, inst[3:0]};
                wmem <= 0;
                wmemaddr <= 0;
                wresreg <= 1;
                wpc <= 0;
                pc_o <= 0;
                rmem <= 0;
                rmemaddr <= 0;
            end
            3'b010: begin // addi: add immediate
                val1 <= resreg;
                val2 <= {4'b0000, inst[3:0]};
                wmem <= 0;
                wmemaddr <= 0;
                wresreg <= 1;
                wpc <= 0;
                pc_o <= 0;
                rmem <= 0;
                rmemaddr <= 0;   
            end
            default: begin // nop or anything else
                val1 <= 0;
                val2 <= 0;
                wmem <= 0;
                wmemaddr <= 0;
                wresreg <= 0;
                wpc <= 0;
                pc_o <= 0;
                rmem <= 0;
                rmemaddr <= 0;    
            end
        endcase
    end else begin
        case (inst[6:5])
            2'b00: begin // add
                val1 <= resreg;
                val2 <= val_i;
                wmem <= 0;
                wmemaddr <= 0;
                wresreg <= 1;
                wpc <= 0;
                pc_o <= 0;
                rmem <= 1;
                rmemaddr <= inst[4:0];
            end
            2'b01: begin
                val1 <= 0;
                val2 <= val_i;
                wmem <= 0;
                wmemaddr <= 0;
                wresreg <= 1;
                wpc <= 0;
                pc_o <= 0;
                rmem <= 1;
                rmemaddr <= inst[4:0]; 
            end
            2'b10: begin
                val1 <= 0;
                val2 <= resreg;
                wmem <= 1;
                wmemaddr <= inst[4:0];
                wresreg <= 0;
                wpc <= 0;
                pc_o <= 0;
                rmem <= 0;
                rmemaddr <= 0; 
            end
            2'b11: begin
                val1 <= 0;
                val2 <= 0;
                wmem <= 0;
                wmemaddr <= 0;
                wresreg <= 0;
                wpc <= 1;
                pc_o <= inst[4:0];
                rmem <= 0;
                rmemaddr <= 0; 
            end
            default: begin
                val1 <= 0;
                val2 <= 0;
                wmem <= 0;
                wmemaddr <= 0;
                wresreg <= 0;
                wpc <= 0;
                pc_o <= 0;
                rmem <= 0;
                rmemaddr <= 0;  
            end
        endcase
    end
end

endmodule