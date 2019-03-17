`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/02/28 15:11:02
// Design Name: 
// Module Name: id
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision: 译码阶段
//    wire RType;   // Type of R-Type Instruction   寄存器-寄存器指令（10） add/sub sll slt sltu xor srl sra or and  10条
//    wire IType;   // Tyoe of Imm    Instruction   寄存器-立即数指令（11  addi slti sltiu xori ori andi slli srli/srai
//    wire BrType;  // Type of Branch Instruction   条件分支（6） BEQ/BNE/BLT/BLTU/BGE/BGEU
//    wire JType;   // Type of Jump   Instruction   无条件跳转（2）
//    wire LdType;  // Type of Load   Instruction   Load指令(5)   lb lh lw lbu lhu
//    wire StType;  // Type of Store  Instruction   store 指令(3) sb sh sw
//    wire MemType; // Type pf Memory Instruction(Load/Store)
//    wire LUI_AUIPC;//lui  auipc
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
`include "define.v"
`include "ctrl_encode_def.v"
`include "instruction_def.v"

module id(
    input wire                 rst,    //复位信号
    input wire [`InstrAddrBus] pc_i,   //译码阶段指令对应地址
    input wire [`InstrBus]     instr_i,//译码阶段指令
    input wire [31:0]          rs1_data_i,//从Regfile输入第一个读寄存器端口输入
    input wire [31:0]          rs2_data_i,//从Regfile输入第二个读寄存器端口输入
    
    //处于执行阶段的指令的一些信息，用于解决load相关
    input wire[4:0]            ex_aluop_i,
    
    /*************解决数据相关************/
    //处于执行阶段的指令要写入的目的寄存器信息
    input wire                 ex_wreg_i,    //执行阶段指令是否要写目的寄存器
    input wire [4:0]           ex_rd_addr_i, //执行阶段写的目的寄存器地址
    input wire [31:0]          ex_rd_data_i, //执行阶段要写入目的寄存器的数据
    //处于访存阶段的指令要写入的目的寄存器信息 
    input wire                 mem_wreg_i,   //访存阶段指令是否要写入目的寄存器
    input wire [4:0]           mem_rd_addr_i,//访存阶段要写的目的寄存器地址
    input wire [31:0]          mem_rd_data_i,//访存阶段要写入目的寄存器的数据
    
    
    //送到regfile的信息
    output reg                 rs1_red_o, //Regfile第一个读寄存器端口读使能信号
    output reg                 rs2_red_o, //Regfile第二个读寄存器端口读使能信号
    output reg [4:0]           rs1_addr_o,//Regfile第一个读寄存器端口读地址信号  32位指令的源操作数1索引   instr[19:15]
    output reg [4:0]           rs2_addr_o,//Regfile第二个读寄存器端口读地址信号  32位指令的源操作数2索引   instr[24:20]

    //送到执行阶段的信息
    output reg [4:0]           aluop_o,
    output reg [31:0]          rs1_data_o,//进行运算的源操作数1
    output reg [31:0]          rs2_data_o,//进行运算的源操作数2
    output reg                 wreg_o,
    output reg [4:0]           rd_addr_o, //32位指令的结果操作数索引  instr[11:7]

    output reg  [31:0]         imm32_o,
    output reg  [31:0]         pc_o,
    /**************load-use相关************/
    //请求stall流水线 load目的寄存器和当前操作数寄存器一样时
    output wire                stallreq_o
    );
    
    localparam  R_TYPE      = 3'b001,
                I_TYPE      = 3'b010,
                S_TYPE      = 3'b011,
                B_TYPE      = 3'b100,
                U_TYPE      = 3'b101,
                J_TYPE      = 3'b110,
                UKNOWN_TYPE = 3'b111;
    reg  [3:0]  instr_type;

    wire        load_instr;
    reg         rs1_loadrelate;
    reg         rs2_loadrelate;

    wire [6:0]   opcode; //  instr[6:0]
    wire [4:0]   rd;     //32位指令的结果操作数索引  instr[11:7]
    wire [4:0]   rs1;    //32位指令的源操作数1索引   instr[19:15]
    wire [4:0]   rs2;    //32位指令的源操作数2索引   instr[24:20]
    wire [2:0]   func3;  //32位指令的func3段        instr[14:12]
    wire [6:0]   func7;  //32位指令的func7段        instr[31:25]
    assign {func7, rs2, rs1, func3, rd, opcode} = instr_i;
//    assign opcode_o  = instr_i[6:0];   //取出opcode 低7位
//    assign rd_addr_o = instr_i[11:7];  //32位指令的结果操作数索引
//    assign func3_o   = instr_i[14:12]; //32位指令的func3段
//    assign rs1_addr_o= instr_i[19:15]; //32位指令的源操作数1索引
//    assign rs2_addr_o= instr_i[24:20]; //32位指令的源操作数2索引
//    assign func7_o   = instr_i[31:25]; //32位指令的func7段     

    assign  stallreq_o = rs1_loadrelate | rs2_loadrelate;
    assign  load_instr = ((ex_aluop_i == `ALUOP_LB) || (ex_aluop_i == `ALUOP_LH) || (ex_aluop_i == `ALUOP_LW)
                          || (ex_aluop_i == `ALUOP_LBU) || (ex_aluop_i == `ALUOP_LHU)) ? 1'b1 : 1'b0;
              
    //得到指令类型          
    always @ (*) begin
        case(opcode)
            `INSTR_Rtype        : instr_type <= R_TYPE;
            `INSTR_Jtype_jal    : instr_type <= J_TYPE;
            `INSTR_Utype_lui    : instr_type <= U_TYPE;
            `INSTR_Itype_imm    : instr_type <= I_TYPE;
            `INSTR_Itype_load   : instr_type <= I_TYPE;
            `INSTR_Itype_jalr   : instr_type <= I_TYPE;
            `INSTR_Stype_store  : instr_type <= S_TYPE;
            `INSTR_Btype_branch : instr_type <= B_TYPE;
            `INSTR_Utype_auipc  : instr_type <= U_TYPE;
            default             : instr_type <= UKNOWN_TYPE;
        endcase
    end    
          
    //译码出指令的立即数，不同指令类型由不同立即数编码形式           
    always @ (*) begin
        case (instr_type)
            R_TYPE : imm32_o <= 0;
            I_TYPE : imm32_o <= {  {20{instr_i[31]}} , instr_i[31:20] };
            S_TYPE : imm32_o <= {  {20{instr_i[31]}} , instr_i[31:25] , instr_i[11:7] };
            B_TYPE : imm32_o <= {  {20{instr_i[31]}} , instr_i[7]     , instr_i[30:25] ,instr_i[11:8] ,1'b0 };
            U_TYPE : imm32_o <= {  instr_i[31:12]    , 12'b0  };
            J_TYPE : imm32_o <= {  {12{instr_i[31]}} , instr_i[19:12] , instr_i[20]  ,  instr_i[30:21],1'b0 };
            default: imm32_o <= 0;
        endcase
    end           
    
    ////根据指令类型确定源操作数来源  1表示来自寄存器
    always @ (*) begin
        case(instr_type)
            R_TYPE  : {rs1_red_o, rs2_red_o} <= 2'b11;
            I_TYPE  : {rs1_red_o, rs2_red_o} <= 2'b10;
            S_TYPE  : {rs1_red_o, rs2_red_o} <= 2'b11;
            B_TYPE  : {rs1_red_o, rs2_red_o} <= 2'b11;
            U_TYPE  : {rs1_red_o, rs2_red_o} <= 2'b00;
            J_TYPE  : {rs1_red_o, rs2_red_o} <= 2'b00;
            default : {rs1_red_o, rs2_red_o} <= 2'b00;
        endcase
    end
    
    ////得到运算第1个操作数
    always @ (*) begin
        rs1_loadrelate <= `NoStop;
        if(rst == `RstEnable)
            rs1_data_o <= `ZeroWord;
        else if((rs1_red_o == 1'b1) && (rs1_addr_o == `Reg0addr)) //0号寄存器规定为0
            rs1_data_o <= `ZeroWord;
        //当前是load指令 load目的寄存器和当前源操作数寄存器一样时   load-use相关
        else if((load_instr == 1'b1) && (rs1_red_o == 1'b1) && (ex_rd_addr_i == rs1_addr_o))
            rs1_loadrelate <= `Stop;
        //要写回数据就是要使用的数据，Foward技术提前获得，解决数据相关
        else if((rs1_red_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_rd_addr_i == rs1_addr_o))
            rs1_data_o <= ex_rd_data_i;
        else if((rs1_red_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_rd_addr_i == rs1_addr_o))
            rs1_data_o <= mem_rd_data_i;
        //else if(opcode == `INSTR_Utype_auipc)
        //    rs1_data_o <= pc_i + 4;   //auipc need pc+high 20 bits imm32
        else if(rs1_red_o == 1'b1)
            rs1_data_o <= rs1_data_i;
        else if(rs1_red_o == 1'b0)
            rs1_data_o <= imm32_o;
    end
    
    ////得到运算第2个操作数
    always @ (*) begin
        rs2_loadrelate <= `NoStop;
        if(rst == `RstEnable)
            rs2_data_o <= `ZeroWord;
        else if((rs2_red_o == 1'b1) && (rs2_addr_o == `Reg0addr)) //0号寄存器规定为0
            rs2_data_o <= `ZeroWord;
        //当前是load指令 load目的寄存器和当前源操作数寄存器一样时   load-use相关
        else if((load_instr == 1'b1) && (rs2_red_o == 1'b1) && (ex_rd_addr_i == rs2_addr_o))
            rs2_loadrelate <= `Stop;
        //要写回数据就是要使用的数据，Foward技术提前获得，解决数据相关
        else if((rs2_red_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_rd_addr_i == rs2_addr_o))
            rs2_data_o <= ex_rd_data_i;
        else if((rs2_red_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_rd_addr_i == rs2_addr_o))
            rs2_data_o <= mem_rd_data_i;
        else if(rs2_red_o == 1'b1)
            rs2_data_o <= rs2_data_i;
        else if(rs2_red_o == 1'b0)
            rs2_data_o <= imm32_o;
    end
    
    always @ (*) begin
        if(rst == `RstEnable) begin
            rs1_red_o  <= 1'b0;
            rs2_red_o  <= 1'b0;
            rs1_addr_o <= `Reg0addr;
            rs2_addr_o <= `Reg0addr;
            rd_addr_o  <= `Reg0addr;
            aluop_o    <= `ALUOP_NOP;
            wreg_o     <= `WriteDisable;
            //rs1_data_o <= `ZeroWord;
            //rs2_data_o <= `ZeroWord;
            imm32_o    <= `ZeroWord;
            pc_o       <= `ZeroWord;
            end
        else begin
            rs1_addr_o <= rs1;
            rs2_addr_o <= rs2;
            rd_addr_o  <= rd;
            pc_o       <= pc_i;
            case (opcode)
                `INSTR_Rtype : begin   //寄存器-寄存器指令（10） add/sub sll slt sltu xor srl sra or and  10条
                    wreg_o <= `WriteEnable;  //R型需要结果写回寄存器
                    case(func3)
                        `FUNCT_ADDSUB : begin
                            if(func7 == 7'b0000000) aluop_o <= `ALUOP_ADD;
                            else                    aluop_o <= `ALUOP_SUB;
                            end
                        `FUNCT_SLL  : aluop_o <= `ALUOP_SLL;
                        `FUNCT_SLT  : aluop_o <= `ALUOP_SLT;
                        `FUNCT_SLTU : aluop_o <= `ALUOP_SLTU;
                        `FUNCT_XOR  : aluop_o <= `ALUOP_XOR;
                        `FUNCT_SRLSRA : begin
                            if(func7 == 7'b0000000) aluop_o <= `ALUOP_SRL;
                            else                    aluop_o <= `ALUOP_SRA;
                            end   
                        `FUNCT_OR   : aluop_o <= `ALUOP_OR;
                        `FUNCT_AND  : aluop_o <= `ALUOP_AND;
                    endcase
                    end
                `INSTR_Itype_imm : begin     //寄存器-立即数指令（11  addi slti sltiu xori ori andi slli srli/srai
                    wreg_o <= `WriteEnable;  //I型需要结果写回寄存器
                    case(func3)
                        `FUNCT_ADDI : aluop_o <= `ALUOP_ADD;
                        `FUNCT_SLTI : aluop_o <= `ALUOP_SLT;
                        `FUNCT_SLTIU: aluop_o <= `ALUOP_SLTU;
                        `FUNCT_XORI : aluop_o <= `ALUOP_XOR;
                        `FUNCT_ORI  : aluop_o <= `ALUOP_OR;
                        `FUNCT_ANDI : aluop_o <= `ALUOP_AND;
                        `FUNCT_SLLI : aluop_o <= `ALUOP_SLL;  
                        `FUNCT_SRLISRAI : begin
                            if(func7 == 0000000) aluop_o <= `ALUOP_SRL;
                            else                 aluop_o <= `ALUOP_SRA;
                         end   
                        
                    endcase
                    end
                `INSTR_Utype_lui : begin
                    wreg_o  <= `WriteEnable;  //lui需要结果写回寄存器
                    aluop_o <= `ALUOP_LUI;
                    end
                `INSTR_Utype_auipc : begin
                    wreg_o  <= `WriteEnable;  //auipc需要结果写回寄存器
                    aluop_o <= `ALUOP_AUIPC;
                    end
                `INSTR_Itype_load : begin
                    wreg_o <= `WriteEnable;  //load需要结果写回寄存器
                    case(func3)
                        `FUNCT_LB : aluop_o <= `ALUOP_LB;
                        `FUNCT_LH : aluop_o <= `ALUOP_LH;
                        `FUNCT_LW : aluop_o <= `ALUOP_LW;
                        `FUNCT_LBU: aluop_o <= `ALUOP_LBU;
                        `FUNCT_LHU: aluop_o <= `ALUOP_LHU;
                    endcase
                    end
                `INSTR_Stype_store : begin
                    wreg_o <= `WriteDisable;
                    case (func3)
                        `FUNCT_SB : aluop_o <= `ALUOP_SB;
                        `FUNCT_SH : aluop_o <= `ALUOP_SH;
                        `FUNCT_SW : aluop_o <= `ALUOP_SW;
                    endcase
                    end
                `INSTR_Btype_branch : begin
                    wreg_o <= `WriteDisable;
                    case (func3)
                        `FUNCT_BEQ : aluop_o <= `ALUOP_BEQ;
                        `FUNCT_BNE : aluop_o <= `ALUOP_BNE;
                        `FUNCT_BLT : aluop_o <= `ALUOP_BLT;
                        `FUNCT_BGE : aluop_o <= `ALUOP_BGE;
                        `FUNCT_BLTU: aluop_o <= `ALUOP_BLTU;
                        `FUNCT_BGEU: aluop_o <= `ALUOP_BGEU;
                    endcase
                    end
                `INSTR_Jtype_jal : begin
                    wreg_o <= `WriteEnable;
                    aluop_o <= `ALUOP_JAL;
                    end
                `INSTR_Itype_jalr : begin
                    wreg_o <= `WriteEnable;
                    aluop_o <= `ALUOP_JALR;
                    end 
            endcase 
            end
    end
    
endmodule
