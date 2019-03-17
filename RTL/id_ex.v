`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/01 10:50:47
// Design Name: 
// Module Name: id_ex
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  ID/EX阶段的寄存器
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module id_ex(
    input wire         clk,
    input wire         rst,
    
    //来自控制模块的信息
    input wire [5:0]   stall,   
    input wire         flush,
    input wire         id_instr_i_valid,
    
    //从译码阶段传递的信息
    input wire [4:0]   id_aluop_i,
    input wire [31:0]  id_rs1_i,
    input wire [31:0]  id_rs2_i,
    input wire         id_wreg_i,
    input wire [4:0]   id_rd_addr_i,
    input wire [31:0]  id_imm32_i,//load指令将rs2存到mem
    input wire [31:0]  id_pc_i,
    
    //传递到执行阶段的信息
    output reg [4:0]   ex_aluop_o,
    output reg [31:0]  ex_rs1_o,
    output reg [31:0]  ex_rs2_o,
    output reg         ex_wreg_o,
    output reg [4:0]   ex_rd_addr_o,
    output reg [31:0]  ex_imm32_o,//load指令将rs2存到mem
    output reg [31:0]  ex_pc_o
    );
    
    //1、当stall[2]为stop，stall[3]为notstop，表示译码段暂停
    //     而执行段继续，所以使用空指令作为下一周期进入执行阶段指令  空指令是为了避免往下流
    //2、当stall[2]为notstop，译码段继续，译码后指令进入执行阶段
    //3、其余情况，保持执行段寄存器不变
    always @ (posedge clk) begin
        if(rst == `RstEnable)begin
            ex_aluop_o  <= `ALUOP_NOP;
            ex_rs1_o    <= `ZeroWord;
            ex_rs2_o    <= `ZeroWord;
            ex_wreg_o   <= `WriteDisable;
            ex_rd_addr_o<= `Reg0addr;
            ex_imm32_o  <= `ZeroWord;
            ex_pc_o     <= `ZeroWord;
        end
        else if(flush == 1'b1 ) begin
            ex_aluop_o  <= `ALUOP_NOP;
            ex_rs1_o    <= `ZeroWord;
            ex_rs2_o    <= `ZeroWord;
            ex_wreg_o   <= `WriteDisable;
            ex_rd_addr_o<= `Reg0addr;
            ex_imm32_o  <= `ZeroWord;
            ex_pc_o     <= `ZeroWord;
        end
        else if(id_instr_i_valid == 1'b1 ) begin
            ex_aluop_o  <= `ALUOP_NOP;
            ex_rs1_o    <= `ZeroWord;
            ex_rs2_o    <= `ZeroWord;
            ex_wreg_o   <= `WriteDisable;
            ex_rd_addr_o<= `Reg0addr;
            ex_imm32_o  <= `ZeroWord;
            ex_pc_o     <= `ZeroWord;
        end
        else if(stall[2] == `Stop && stall[3] == `NoStop)begin
            ex_aluop_o  <= `ALUOP_NOP;
            ex_rs1_o    <= `ZeroWord;
            ex_rs2_o    <= `ZeroWord;
            ex_wreg_o   <= `WriteDisable;
            ex_rd_addr_o<= `Reg0addr;
            ex_imm32_o  <= `ZeroWord;
            ex_pc_o     <= `ZeroWord;
        end
        else if(stall[2] == `NoStop)begin
            ex_aluop_o  <= id_aluop_i;
            ex_rs1_o    <= id_rs1_i;
            ex_rs2_o    <= id_rs2_i;
            ex_wreg_o   <= id_wreg_i;
            ex_rd_addr_o<= id_rd_addr_i;
            ex_imm32_o  <= id_imm32_i;
            ex_pc_o     <= id_pc_i;
        end
    end
    
endmodule









