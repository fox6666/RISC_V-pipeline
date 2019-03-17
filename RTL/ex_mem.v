`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/02 13:58:01
// Design Name: 
// Module Name: ex_mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  EX/MEM阶段的寄存器
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module ex_mem(
    input wire        clk,
    input wire        rst,
    
    //来自控制模块的信息
    input wire [5:0]  stall,
    
    //来自执行阶段的信息	
    input wire        ex_wreg_i,
    input wire [4:0]  ex_rd_addr_i,
    input wire [31:0] ex_rd_data_i,
    
    //为实现加载、访存指令而添加
    input wire [4:0]  ex_aluop_i,
    input wire [`DataMemNumLog2+1:0] ex_mem_addr_i,
    input wire [31:0] ex_rs2_i,     //store将rs2存入mem
    
    //送到访存阶段的信息
    output reg        mem_wreg_o,
    output reg [4:0]  mem_rd_addr_o,
    output reg [31:0] mem_rd_data_o,
    
    //为实现加载、访存指令而添加
    output reg [4:0]  mem_aluop_o,
    output reg [`DataMemNumLog2+1:0] mem_mem_addr_o,
    output reg [31:0] mem_rs2_o
    
    );
    
    //1、当stall[3]为stop，stall[4]为notstop，表示执行段暂停
    //   而访存段继续，所以使用空指令作为下一周期进入访存阶段指令  空指令是为了避免往下流
    //2、当stall[3]为notstop，执行段继续，执行后指令进入访存阶段
    //3、其余情况，保持访存段寄存器不变
    always @(posedge clk) begin
        if(rst == `RstEnable) begin
            mem_wreg_o    <= `WriteDisable;
            mem_rd_addr_o <= `Reg0addr;
            mem_rd_data_o <= `ZeroWord;
            mem_aluop_o   <= 5'b00000;
            mem_mem_addr_o<= `DataMemNumLog2+1'b0;
            mem_rs2_o     <= `ZeroWord;
        end
        else if(stall[3] == `Stop && stall[4] == `NoStop) begin
            mem_wreg_o    <= `WriteDisable;
            mem_rd_addr_o <= `Reg0addr;
            mem_rd_data_o <= `ZeroWord;
            mem_aluop_o   <= 5'b00000;
            mem_mem_addr_o<= `DataMemNumLog2+1'b0;
            mem_rs2_o     <= `ZeroWord;
        end
        else if(stall[3] == `NoStop) begin
            mem_wreg_o    <= ex_wreg_i;
            mem_rd_addr_o <= ex_rd_addr_i;
            mem_rd_data_o <= ex_rd_data_i;
            mem_aluop_o   <= ex_aluop_i;
            mem_mem_addr_o<= ex_mem_addr_i;
            mem_rs2_o     <= ex_rs2_i;
        end
    end
    
    
    
endmodule
