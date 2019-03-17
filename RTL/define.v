`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/28 09:52:58
// Design Name: 
// Module Name: define
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

//全局定义
`define RstEnable        1'b1    //复位信号有效
`define RstDisable       1'b0    //复位信号无效
`define WriteEnable      1'b1    //使能写
`define WriteDisable     1'b0    //禁止写
`define ReadEnable       1'b1    //使能读
`define ReadDisable      1'b0    //禁止读
`define InstrValid       1'b0    //指令有效
`define InstrInvalid     1'b1    //指令无效
`define True_v           1'b1    //逻辑真
`define False_v          1'b0    //逻辑假
`define Stop             1'b1    //暂停
`define NoStop           1'b0    //不暂停
`define Branch           1'b1    //转移
`define NotBranch        1'b0    //没有转移
`define ChipEnable       1'b1    //芯片使能 
`define ChipDisable      1'b0    //芯片禁止
`define ZeroWord         32'h00000000  //32位的数值0

//指令存储器instr_rom
`define InstrAddrBus     31:0    //ROM地址总线宽度
`define InstrBus         31:0    //ROM数据总线宽度
`define InstrMemNum      4096    //ROM实际大小为4KB
`define InstrMemNumLog2  12      //ROM实际使用地址线宽度

//数据存储器 data ram
`define DataMemNum       4096   //RAM实际大小为4KB
`define DataMemNumLog2   12     //RAM实际使用地址线宽度

//通用寄存器regfile
`define RegNum           32
`define RegNumlog2       5
`define Reg0addr         5'b00000






