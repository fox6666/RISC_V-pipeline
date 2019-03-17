`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/02 18:31:07
// Design Name: 
// Module Name: mem_wb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  MEM/WB阶段的寄存器
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module mem_wb(
    input wire         clk,
    input wire         rst,
    
    //来自控制模块的信息
    input wire [5:0]   stall,
    
    //来自访存阶段的信息
    input wire         mem_wreg_i,
    input wire [4:0]   mem_rd_addr_i,
    input wire [31:0]  mem_rd_data_i,
    
    //送到回写阶段的信息
    output reg         wb_wreg_o,
    output reg [4:0]   wb_rd_addr_o,
    output reg [31:0]  wb_rd_data_o //load从dataRAM取的数据需写回  ALU运算结果要写回

    );
    
    //1、当stall[4]为stop，stall[5]为notstop，表示访存段暂停
    //     而写回段继续，所以使用空指令作为下一周期进入写回阶段指令  空指令是为了避免往下流
    //2、当stall[4]为notstop，访存段继续，执行后指令进入写回阶段
    //3、其余情况，保持写回段寄存器不变
    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            wb_wreg_o    <= `WriteDisable;
            wb_rd_addr_o <= `Reg0addr;
            wb_rd_data_o <= `ZeroWord;
        end
        else if(stall[4] == `Stop && stall[5] == `NoStop) begin
            wb_wreg_o    <= `WriteDisable;
            wb_rd_addr_o <= `Reg0addr;
            wb_rd_data_o <= `ZeroWord;
        end
        else if(stall[4] == `NoStop) begin
            wb_wreg_o    <= mem_wreg_i;
            wb_rd_addr_o <= mem_rd_addr_i;
            wb_rd_data_o <= mem_rd_data_i;
        end
    end
endmodule










