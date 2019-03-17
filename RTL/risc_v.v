`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/28 09:52:39
// Design Name: 
// Module Name: risc_v
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  RISC_V处理器的顶层文件
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"

module risc_v(
    input  wire                 clk,
    input  wire                 rst,

    //连接指令存储器
    input  wire [31:0]          rom_data_i,
    output wire [`InstrAddrBus] rom_addr_o,
    output wire                 rom_ce_o,  
    
    //连接数据存储器data_ram
    input  wire [31:0]          ram_data_i,
    output wire                 ram_we_o,
    output wire [3:0]           ram_sel_o,
    output wire [`DataMemNumLog2+1:0] ram_addr_o,
    output wire [31:0]          ram_data_o 
    );
    
    //中间连线
    //连接指令存储器
    wire [`InstrAddrBus]  pc;
    
    //
    wire [`InstrAddrBus]  id_pc_i;
    wire [`InstrBus]      id_instr_i;
    
    //连接译码阶段ID模块与通用寄存器Regfile模块
    wire                  rs1_red;
    wire                  rs2_red;
    wire [4:0]            rs1_addr;
    wire [4:0]            rs2_addr;
    wire [31:0]           rs1_data;
    wire [31:0]           rs2_data;
    
    //连接译码阶段ID模块的输出与ID/EX模块的输入
    wire  [4:0]           id_aluop_o;
    wire  [31:0]          id_rs1_data_o; 
    wire  [31:0]          id_rs2_data_o; 
    wire                  id_wreg_o;
    wire  [4:0]           id_rd_addr_o;
    wire  [31:0]          id_imm32_o;
    wire  [31:0]          id_pc_o;
    wire                  id_instr_o_valid;
    
    //连接ID/EX模块的输出与执行阶段EX模块的输入
    wire  [4:0]           ex_aluop_i;
    wire  [31:0]          ex_rs1_i;
    wire  [31:0]          ex_rs2_i;
    wire                  ex_wreg_i;
    wire  [4:0]           ex_rd_addr_i;
    wire  [31:0]          ex_imm32_i;
    wire  [31:0]          ex_pc_i;
    
    //连接执行阶段EX模块的输出与EX/MEM模块的输入
    wire                  ex_wreg_o;
    wire  [4:0]           ex_rd_addr_o;
    wire  [31:0]          ex_rd_data_o;
    wire  [4:0]           ex_aluop_o;
    wire  [31:0]          ex_mem_addr_o;
    wire  [31:0]          ex_rs2_o;
    wire                  ex_branch_flag_o;
    wire  [31:0]          ex_new_pc_o;
    
    //连接EX/MEM模块的输出与访存阶段MEM模块的输入
    wire                  mem_wreg_i;
    wire  [4:0]           mem_rd_addr_i;
    wire  [31:0]          mem_rd_data_i;
    wire  [4:0]           mem_aluop_i;
    wire  [`DataMemNumLog2+1:0] mem_mem_addr_i;
    wire  [31:0]          mem_rs2_i;
    
    
    //连接访存阶段MEM模块的输出与MEM/WB模块的输入
    wire                  mem_wreg_o;
    wire  [4:0]           mem_rd_addr_o;
    wire  [31:0]          mem_rd_data_o;
    
    //连接MEM/WB模块的输出与回写阶段的输入	
    wire                  wb_wreg_i;
    wire  [4:0]           wb_rd_addr_i;
    wire  [31:0]          wb_rd_data_i; //load从dataRAM取的数据需写回  ALU运算结果要写回
    
    //控制信号
    wire  [5:0]           stall;
    wire                  flush;
    wire                  stallreq_id;
    wire                  stallreq_ex;
    wire  [31:0]          new_pc;
    
    //各模块例化
    control i_control(
        .rst(rst),
        .stallreq_id(stallreq_id),
        .stallreq_ex(stallreq_ex),
        .branch_flag_i(ex_branch_flag_o),
        .new_pc_i(ex_new_pc_o),
        .stall(stall),
        .flush(flush),
        .new_pc_o(new_pc)
    );
    
    pc_reg  i_pc_reg(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .new_pc_i(new_pc),
        .pc(pc),
        .ce(rom_ce_o)
    );
    assign rom_addr_o = pc;
    
    
    if_id  i_if_id(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .if_pc_i(pc),
        .if_instr_i(rom_data_i),
        .id_pc_o(id_pc_i),
        .id_instr_o(id_instr_i),
        .id_instr_o_valid(id_instr_o_valid)
    );
    
    id  i_id(
        .rst(rst),
        .pc_i(id_pc_i),
        .instr_i(id_instr_i),
        .rs1_data_i(rs1_data),
        .rs2_data_i(rs2_data),
        
        //处于执行阶段的指令的一些信息，用于解决load相关
        .ex_aluop_i(ex_aluop_o),
        
        /*************解决数据相关************/
        //处于执行阶段的指令要写入的目的寄存器信息
        .ex_wreg_i(ex_wreg_o),
        .ex_rd_addr_i(ex_rd_addr_o),
        .ex_rd_data_i(ex_rd_data_o),
        //处于访存阶段的指令要写入的目的寄存器信息 
        .mem_wreg_i(mem_wreg_o),
        .mem_rd_addr_i(mem_rd_addr_o),
        .mem_rd_data_i(mem_rd_data_o),
        
        //送到regfile的信息
        .rs1_red_o(rs1_red),
        .rs2_red_o(rs2_red),
        .rs1_addr_o(rs1_addr),
        .rs2_addr_o(rs2_addr),
        
        //送到执行阶段的信息
        .aluop_o(id_aluop_o),
        .rs1_data_o(id_rs1_data_o),
        .rs2_data_o(id_rs2_data_o),
        .wreg_o(id_wreg_o),
        .rd_addr_o(id_rd_addr_o),
        .imm32_o(id_imm32_o),
        .pc_o(id_pc_o),
        
        /**************load-use相关************/
        //请求stall流水线 load目的寄存器和当前操作数寄存器一样时
        .stallreq_o(stallreq_id)
    );
    
    regfile i_regfile(
        .clk(clk),
        .rst(rst),
        //read 1 port
        .re1_i(rs1_red),
        .raddr1_i(rs1_addr),
        .rdata1_o(rs1_data),
        //read 2 port
        .re2_i(rs2_red),
        .raddr2_i(rs2_addr),
        .rdata2_o(rs2_data),
        //write port
        .we_i(wb_wreg_i),
        .waddr_i(wb_rd_addr_i),
        .wdata_i(wb_rd_data_i)
    );
    
    id_ex  i_id_ex(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .id_instr_i_valid(id_instr_o_valid),
        
        //从译码阶段传递的信息
        .id_aluop_i(id_aluop_o),
        .id_rs1_i(id_rs1_data_o),
        .id_rs2_i(id_rs2_data_o),
        .id_wreg_i(id_wreg_o),
        .id_rd_addr_i(id_rd_addr_o),
        .id_imm32_i(id_imm32_o),
        .id_pc_i(id_pc_o),
        
        //传递到执行阶段的信息
        .ex_aluop_o(ex_aluop_i),
        .ex_rs1_o(ex_rs1_i),
        .ex_rs2_o(ex_rs2_i),
        .ex_wreg_o(ex_wreg_i),
        .ex_rd_addr_o(ex_rd_addr_i),
        .ex_imm32_o(ex_imm32_i),
        .ex_pc_o(ex_pc_i)
    );
    
    ex  i_ex(
        .rst(rst),
        .aluop_i(ex_aluop_i),
        .rs1_i(ex_rs1_i),
        .rs2_i(ex_rs2_i),
        .wreg_i(ex_wreg_i),
        .rd_addr_i(ex_rd_addr_i),
        .imm32_i(ex_imm32_i),
        .pc_i(ex_pc_i),
        
        /*************解决数据相关************/
        //处于执行阶段的指令要写入的目的寄存器信息
        .wreg_o(ex_wreg_o),
        .rd_addr_o(ex_rd_addr_o),
        .rd_data_o(ex_rd_data_o),
        
        //执行阶段指令一些信息，用于解决load相关  aluop_o传递到访存阶段，用于加载、存储指令
        .aluop_o(ex_aluop_o),
        .mem_addr_o(ex_mem_addr_o),
        .rs2_o(ex_rs2_o),
        
        .branch_flag_o(ex_branch_flag_o),
        .new_pc_o(ex_new_pc_o),
        .stallreq_ex(stallreq_ex)
    );
    
    ex_mem  i_ex_mem(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        
        //来自执行阶段的信息	
        .ex_wreg_i(ex_wreg_o),
        .ex_rd_addr_i(ex_rd_addr_o),
        .ex_rd_data_i(ex_rd_data_o),
        
        //为实现加载、访存指令而添加
        .ex_aluop_i(ex_aluop_o),
        .ex_mem_addr_i(ex_mem_addr_o[`DataMemNumLog2+1:0]),
        .ex_rs2_i(ex_rs2_o),   //store将rs2存入mem
        
        //送到访存阶段的信息
        .mem_wreg_o(mem_wreg_i),
        .mem_rd_addr_o(mem_rd_addr_i),
        .mem_rd_data_o(mem_rd_data_i),
        .mem_aluop_o(mem_aluop_i),
        .mem_mem_addr_o(mem_mem_addr_i),
        .mem_rs2_o(mem_rs2_i)
    );
    
    mem  i_mem(
        .rst(rst),
        
        //来自执行阶段的信息
        .wreg_i(mem_wreg_i),
        .rd_addr_i(mem_rd_addr_i),
        .rd_data_i(mem_rd_data_i),
        //为实现加载、访存指令而添加
        .aluop_i(mem_aluop_i),
        .mem_addr_i(mem_mem_addr_i),
        .rs2_i(mem_rs2_i),
        
        //来自Data RAM的信息    load从dataRAM取的数据需写回
        .mem_data_i(ram_data_i),
        
        //送到回写阶段的信息
        .wreg_o(mem_wreg_o),
        .rd_addr_o(mem_rd_addr_o),
        .rd_data_o(mem_rd_data_o),
        
        //送到Data RAM的信息
        .mem_we_o(ram_we_o),
        .mem_sel_o(ram_sel_o),
        .mem_addr_o(ram_addr_o),
        .mem_data_o(ram_data_o)
    );
       
    mem_wb i_mem_wb(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        //来自访存阶段的信息
        .mem_wreg_i(mem_wreg_o),
        .mem_rd_addr_i(mem_rd_addr_o),
        .mem_rd_data_i(mem_rd_data_o),
        //送到回写阶段的信息
        .wb_wreg_o(wb_wreg_i),
        .wb_rd_addr_o(wb_rd_addr_i),
        .wb_rd_data_o(wb_rd_data_i)
    );
    
endmodule
