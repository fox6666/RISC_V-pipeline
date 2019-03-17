`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/28 11:09:30
// Design Name: 
// Module Name: if_id
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: IF/ID阶段的寄存器
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

//IF/ID阶段的寄存器
module if_id(
    input wire                 clk,
    input wire                 rst,
    input wire [5:0]           stall,      //控制流水线暂停，每位为1表示该阶段需要暂停
    input wire                 flush,
    input wire [`InstrAddrBus] if_pc_i,    //取指阶段PC地址
    input wire [`InstrBus]     if_instr_i, //取指阶段32位指令信息
    output reg [`InstrAddrBus] id_pc_o,    //译码阶段pc
    output reg [`InstrBus]     id_instr_o,  //译码阶段32位指令信息
    output reg                 id_instr_o_valid //控制id/ex阶段输入的有效性  
    );
    
    //1、当stall[1]为stop，stall[2]为notstop，表示取指段暂停，
    //   译码段继续，使用空指令作为下一周期进入译码段指令
    //2、当stall[1]为notstop，取指段继续，取得指令进入译码阶段
    //3、其余情况，保持一码段寄存器pc，instr不变
    
    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            id_pc_o    <= `ZeroWord;
            id_instr_o <= `ZeroWord;
        end
        else if(flush == 1'b1)begin
            id_pc_o    <= `ZeroWord;
            id_instr_o <= `ZeroWord;
        end
        else if(stall[1] == `Stop && stall[2] == `NoStop) begin
            id_pc_o    <= `ZeroWord;
            id_instr_o <= `ZeroWord;
        end
        else if(stall[1] == `NoStop) begin
            id_pc_o    <= if_pc_i;
            id_instr_o <= if_instr_i;
        end
    end
    
    always @ (posedge clk) begin
        id_instr_o_valid <= flush;
    end
    
endmodule
