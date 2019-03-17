`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/28 10:02:47
// Design Name: 
// Module Name: pc_reg
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
`include "define.v"
//PC寄存器
module pc_reg(
    input wire        clk,
    input wire        rst,
    
    input wire [5:0]  stall, //控制流水线暂停，每位为1表示该阶段需要暂停
    
    input wire        flush, //是否发生转移信号
    input wire [31:0] new_pc_i,//转移到的目标地址
    
    output reg [31:0] pc,
    output reg        ce
    
    );

    always @ (posedge clk) begin
        if(rst == `RstEnable)
            ce <= `ChipDisable;  //复位时指令存储器禁用
        else
            ce <= `ChipEnable;   //复位结束，指令存储器使能
    end
    
    always @ (posedge clk) begin
        if(rst == `RstEnable)
            pc <= 32'h00000000;
        else if(flush == 1'b1)
            pc <= new_pc_i;
        else if(stall[0] == `NoStop) begin  //无流水线暂停  
            pc <= pc + 4'h4;
        end
    end

endmodule
