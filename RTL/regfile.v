`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/28 16:23:51
// Design Name: 
// Module Name: regfile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  通用寄存器，共32个
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module regfile(
    input wire        clk,
    input wire        rst,
    
    //read 1 port
    input wire        re1_i,
    input wire [4:0]  raddr1_i,
    output reg [31:0] rdata1_o,
    
    //read 2 port
    input wire        re2_i,
    input wire [4:0]  raddr2_i,
    output reg [31:0] rdata2_o,
    
    //write port
    input wire        we_i,
    input wire [4:0]  waddr_i,
    input wire [31:0] wdata_i
    
    );
    
    reg [31:0] regs[`RegNum-1:0]; //32个32位通用寄存器
    integer i;
    initial begin
        for(i = 0; i < `RegNum; i = i+1)
            regs[i] = 0;
    end
    
    always @(posedge clk) begin
        if(rst == `RstDisable) begin
            //if(we_i == `WriteEnable) 
            if((we_i == `WriteEnable) && (waddr_i != `Reg0addr)) //RISC_V规定0号寄存器一直为0
                regs[waddr_i] <= wdata_i;
        end
    end
        
    always @ (*) begin
        if(rst == `RstEnable) 
            rdata1_o <= `ZeroWord;
        else if(raddr1_i == `Reg0addr)
            rdata1_o <= `ZeroWord;
        //相隔两条指令的数据相关此处解决，回写时如果译码需要寄存器值直接获取
        else if((raddr1_i == waddr_i) && (we_i == `WriteEnable) && (re1_i == `ReadEnable))
            rdata1_o <= wdata_i;
        else if(re1_i == `ReadEnable)
            rdata1_o <= regs[raddr1_i];
        else
            rdata1_o <= `ZeroWord;
    end
    
    always @ (*) begin
        if(rst == `RstEnable)
            rdata2_o <= `ZeroWord;
        else if(raddr2_i == `Reg0addr)
            rdata2_o <= `ZeroWord;
        else if((raddr2_i == waddr_i) && (re2_i == `ReadEnable) && (we_i == `WriteEnable))
            rdata2_o <= wdata_i;
        else if(re2_i == `ReadEnable)
            rdata2_o <= regs[raddr2_i];
        else 
            rdata2_o <= `ZeroWord;
    end
    
endmodule
