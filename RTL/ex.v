`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/01 15:50:47
// Design Name: 
// Module Name: ex
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  执行阶段
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"
`include "ctrl_encode_def.v"
`include "instruction_def.v"

module ex(
    input wire         rst,
    
    //传递到执行阶段的信息
    input wire [4:0]   aluop_i,
    input wire [31:0]  rs1_i,
    input wire [31:0]  rs2_i,
    input wire         wreg_i,
    input wire [4:0]   rd_addr_i,
    input wire [31:0]  imm32_i,
    input wire [31:0]  pc_i,

    /*************解决数据相关************/
    //处于执行阶段的指令要写入的目的寄存器信息
    output reg         wreg_o,    //执行阶段指令是否要写目的寄存器
    output reg [4:0]   rd_addr_o, //执行阶段写的目的寄存器地址
    output reg [31:0]  rd_data_o, //执行阶段要写入目的寄存器的数据
    
    //处于执行阶段的指令的一些信息，用于解决load相关   aluop_o传递到访存阶段，用于加载、存储指令
    output     [4:0]   aluop_o,
    output reg [31:0]  mem_addr_o,
    output     [31:0]  rs2_o,     //store将rs2存入Data RAM
        
    //分支指令传递到控制块信息
    output wire        branch_flag_o,
    output reg [31:0]  new_pc_o,
    output wire        stallreq_ex
    );
    
    wire  jump;
    wire  branch_instr;
    reg   cmp_result;
    
    
    assign aluop_o = aluop_i;
    assign rs2_o   = rs2_i;
    assign stallreq_ex = `NoStop;
    
    integer  i;
    always @ (*) begin
        wreg_o    <= wreg_i;
        rd_addr_o <= rd_addr_i;
        if(rst == `RstEnable) begin
            rd_data_o  <= `ZeroWord;
            mem_addr_o <= `ZeroWord; 
            new_pc_o   <= `ZeroWord; 
        end
        else begin
            case (aluop_i)
                `ALUOP_NOP : rd_data_o <= `ZeroWord;
                `ALUOP_ADD : rd_data_o <= rs1_i + rs2_i;                   //ADD  ADDI
                `ALUOP_SLT : rd_data_o <= (rs1_i < rs2_i) ? 32'd1 : 32'd0; //SLT  SLTI
                `ALUOP_SLTU: rd_data_o <= ({1'b0,rs1_i}<{1'b0,rs2_i}) ? 32'd1 : 32'd0; //无符号比较 SLTU SLTIU
                `ALUOP_AND : rd_data_o <= rs1_i & rs2_i;                   //AND  ANDI
                `ALUOP_OR  : rd_data_o <= rs1_i | rs2_i;                   //OR  ORI
                `ALUOP_XOR : rd_data_o <= rs1_i ^ rs2_i;                   //XOR XORI
                `ALUOP_SLL : rd_data_o <= (rs1_i << rs2_i[4:0]);           //SLL SLLI
                `ALUOP_SRL : rd_data_o <= (rs1_i >> rs2_i[4:0]);           //SRL SRLI
                `ALUOP_SUB : rd_data_o <= rs1_i - rs2_i;                   //SUB
                `ALUOP_SRA : begin                                 //SRA SRAI
                    for(i = 1; i <= rs2_i[4:0]; i = i+1)
                        rd_data_o[32 - i] = rs1_i[31]; //符号位
                    for(i = 31-rs2_i[4:0]; i >= 0; i = i-1)
                        rd_data_o[i] = rs1_i[i + rs2_i[4:0]];
                 end
                `ALUOP_LUI : rd_data_o <= imm32_i; //lui
                `ALUOP_AUIPC:rd_data_o <= pc_i + imm32_i; //auipc
                
                `ALUOP_JAL : begin rd_data_o <= pc_i + 4; new_pc_o <= pc_i + imm32_i; end//jal
                `ALUOP_JALR: begin rd_data_o <= pc_i + 4; new_pc_o <= rs1_i + imm32_i; end//jalr
                `ALUOP_BEQ : begin cmp_result<= (rs1_i == rs2_i) ? 1'b1 : 1'b0; new_pc_o <= pc_i + imm32_i; end//BEQ
                `ALUOP_BNE : begin cmp_result<= (rs1_i != rs2_i) ? 1'b1 : 1'b0; new_pc_o <= pc_i + imm32_i; end//BNE
                `ALUOP_BLT : begin cmp_result<= (rs1_i < rs2_i)  ? 1'b1 : 1'b0; new_pc_o <= pc_i + imm32_i; end//BLT
                `ALUOP_BLTU: begin cmp_result<= ({1'b0,rs1_i}<{1'b0,rs2_i}) ? 1'b1 : 1'b0; new_pc_o <= pc_i + imm32_i; end
                `ALUOP_BGE : begin cmp_result<= (rs1_i > rs2_i)  ? 1'b1 : 1'b0; new_pc_o <= pc_i + imm32_i; end//BGE
                `ALUOP_BGEU: begin cmp_result<= ({1'b0,rs1_i}>{1'b0,rs2_i}) ? 1'b1 : 1'b0; new_pc_o <= pc_i + imm32_i; end
                
                default    : begin rd_data_o <= `ZeroWord;  new_pc_o <= `ZeroWord;  end
            endcase
        end
    end
    
    always @ (*) begin
        case (aluop_i)
            `ALUOP_LB  : mem_addr_o <= rs1_i + imm32_i; 
            `ALUOP_LH  : mem_addr_o <= rs1_i + imm32_i;
            `ALUOP_LW  : mem_addr_o <= rs1_i + imm32_i;
            `ALUOP_LBU : mem_addr_o <= rs1_i + imm32_i;
            `ALUOP_LHU : mem_addr_o <= rs1_i + imm32_i;
            `ALUOP_SB  : mem_addr_o <= rs1_i + imm32_i;
            `ALUOP_SH  : mem_addr_o <= rs1_i + imm32_i;
            `ALUOP_SW  : mem_addr_o <= rs1_i + imm32_i;
            default    : mem_addr_o <= `ZeroWord; 
        endcase
    end
    
    assign branch_instr = ((aluop_i == `ALUOP_BEQ) || (aluop_i == `ALUOP_BNE) || (aluop_i == `ALUOP_BLT)
                          || (aluop_i == `ALUOP_BLTU) || (aluop_i == `ALUOP_BGE) || (aluop_i == `ALUOP_BGEU)) ? 1'b1 : 1'b0;
    assign jump = (((branch_instr == 1'b1) && (cmp_result == 1'b1))
                    | aluop_i == `ALUOP_JAL
                    | aluop_i == `ALUOP_JALR
                    ) ? 1'b1 : 1'b0;
    assign branch_flag_o = ((jump == 1'b1) && (new_pc_o != pc_i + 4)) ? `Branch : `NotBranch;
endmodule
