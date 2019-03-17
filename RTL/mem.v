`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/02 14:32:05
// Design Name: 
// Module Name: mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  访存阶段
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module mem(
    input wire           rst,
    
    //来自执行阶段的信息	
    input wire           wreg_i,
    input wire [4:0]     rd_addr_i,
    input wire [31:0]    rd_data_i,
    //为实现加载、访存指令而添加
    input wire [4:0]     aluop_i,
    input wire [`DataMemNumLog2+1:0]    mem_addr_i,
    input wire [31:0]    rs2_i,     //store将rs2存入mem
    
    //来自Data RAM的信息    load从dataRAM取的数据需写回
    input wire [31:0]    mem_data_i,
    
    //送到回写阶段的信息
    output reg           wreg_o,
    output reg [4:0]     rd_addr_o,
    output reg [31:0]    rd_data_o, //load从dataRAM取的数据需写回  ALU运算结果要写回
    
    //送到Data RAM的信息
    output reg           mem_we_o,  //Data RAM读写信号  1 write
    output reg [3:0]     mem_sel_o, //字节选择信号
    output reg [`DataMemNumLog2+1:0]    mem_addr_o,//访问的地址
    output reg [31:0]    mem_data_o //要写入的数据   store将rs2存入mem
    );
    
    wire load_instr;
    wire store_instr;
    assign load_instr = ((aluop_i == `ALUOP_LB) || (aluop_i == `ALUOP_LH) || (aluop_i == `ALUOP_LW)
                          || (aluop_i == `ALUOP_LBU) || (aluop_i == `ALUOP_LHU)) ? 1'b1 : 1'b0;
    assign store_instr = ((aluop_i == `ALUOP_SB) || (aluop_i == `ALUOP_SH) || (aluop_i == `ALUOP_SW)) ? 1'b1 : 1'b0;
    
    always @ (*) begin
        if(rst == `RstEnable) begin
            wreg_o    <= `WriteDisable;
            rd_addr_o <= `Reg0addr;
            rd_data_o <= `ZeroWord;
            mem_we_o  <= `WriteDisable;
            mem_sel_o <= 4'b0000;
            mem_addr_o<= `DataMemNumLog2+1'b0;
            mem_data_o<= `ZeroWord;
        end
        else begin
            if(load_instr == 1'b1) begin
                wreg_o    <= wreg_i;
                rd_addr_o <= rd_addr_i;
                rd_data_o <= rd_data_i;
                mem_we_o   <= `WriteDisable;
                mem_data_o <= `ZeroWord;
                mem_sel_o  <= 4'b0000;
                mem_addr_o <= mem_addr_i;
                case(aluop_i)
                    `ALUOP_LB  : rd_data_o <= {{ 24{mem_data_i[7]} },mem_data_i[7:0]};
                    `ALUOP_LH  : rd_data_o <= {{ 16{mem_data_i[15]} },mem_data_i[15:0]};
                    `ALUOP_LW  : rd_data_o <= mem_data_i;
                    `ALUOP_LBU : rd_data_o <= {24'b0,mem_data_i[7:0]};
                    `ALUOP_LHU : rd_data_o <= {16'b0,mem_data_i[15:0]}; 
                endcase
            end
            else if(store_instr == 1'b1)begin
                wreg_o    <= `WriteDisable;
                rd_addr_o <= `Reg0addr;
                rd_data_o <= `ZeroWord;
                mem_we_o   <= `WriteEnable;
                mem_data_o <= rs2_i;
                mem_addr_o <= mem_addr_i;
                case(aluop_i)
                    `ALUOP_SB : mem_sel_o <= 4'b0001;  //store low 8bit
                    `ALUOP_SH : mem_sel_o <= 4'b0011;  //store low 16bit
                    `ALUOP_SW : mem_sel_o <= 4'b1111;  //store low 32bit
                endcase
            end
            else begin
                wreg_o    <= wreg_i;
                rd_addr_o <= rd_addr_i;
                rd_data_o <= rd_data_i;
                mem_we_o  <= `WriteDisable;
                mem_sel_o <= 4'b0000;
                mem_addr_o<= `DataMemNumLog2+1'b0;
                mem_data_o<= `ZeroWord;
            end
        end
    end
    
    
endmodule
