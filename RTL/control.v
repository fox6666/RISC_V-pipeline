`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/02 18:47:27
// Design Name: 
// Module Name: control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  控制模块，控制流水线的刷新、暂停等
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module control(
    input wire       rst,
    input wire       stallreq_id,
    input wire       stallreq_ex,
    input wire       branch_flag_i,
    input wire [31:0]new_pc_i,
    output reg [5:0] stall , //stall[0]表示PC是否不变、stall[1]流水线取指段是否暂停,stall[2]译码段 ...    
    output reg       flush,
    output reg [31:0]new_pc_o

    );
    always @ (*) begin
        if(rst == `RstEnable) begin   stall <= 6'b000000; flush <= 1'b0; new_pc_o <= `ZeroWord; end
        else if(stallreq_id == `Stop) stall <= 6'b000111;
        else if(stallreq_ex == `Stop) stall <= 6'b001111;
        else stall <= 6'b000000;
    end
    always @ (*) begin
        if(branch_flag_i == `Branch) begin
            flush = 1'b1;
            new_pc_o = new_pc_i;
        end
        else if(branch_flag_i == `NotBranch) begin
            flush = 1'b0;
            new_pc_o = `ZeroWord;
        end
    end
endmodule
