`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/02 15:58:56
// Design Name: 
// Module Name: data_ram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  数据存储器
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module data_ram(
    input wire         rst,
    input wire         clk,
    input wire         we_i,  //Data RAM读写信号  1 write
    input wire [3:0]   sel_i, //字节选择信号
    input wire [`DataMemNumLog2+1:0]  addr_i,//访问的地址
    input wire [31:0]  data_i,//要写入的数据
    output     [31:0]  data_o

    );
    integer i;
    reg [31:0] data_mem [`DataMemNum-1:0] ;
    //
    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            for(i = 0; i < `DataMemNum; i = i+1)
                    data_mem[i] <= 0;
        end
        if(we_i == `WriteEnable) begin
            if(sel_i[0]) data_mem[addr_i[`DataMemNumLog2+1:2]][7:0]   <= data_i[7:0];
            if(sel_i[1]) data_mem[addr_i[`DataMemNumLog2+1:2]][15:8]  <= data_i[15:8];
            if(sel_i[2]) data_mem[addr_i[`DataMemNumLog2+1:2]][23:16] <= data_i[23:16];
            if(sel_i[3]) data_mem[addr_i[`DataMemNumLog2+1:2]][31:24] <= data_i[31:24];
        end
        /*
        else if(we_i == `WriteDisable)
            data_o <= data_mem[addr_i[`DataMemNumLog2+1:2]];
        else
            data_o <= `ZeroWord;
        */
    end
    assign data_o = data_mem[addr_i[`DataMemNumLog2+1:2]];
    
endmodule
