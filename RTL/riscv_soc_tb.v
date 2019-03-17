`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/06 17:48:28
// Design Name: 
// Module Name: riscv_soc_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module riscv_soc_tb(

    );

    reg clk,rst;
    risc_v_soc i_risc_v_soc(
        .clk(clk),  .rst(rst) 
    );
    
    initial begin
        clk = 1;
        rst = 1;
        #5
        rst = 0;
    end
    
    always
        #(1) clk = ~ clk;
endmodule