`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/06 16:16:39
// Design Name: 
// Module Name: risc_v_soc
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

module risc_v_soc(
    input wire clk,
    input wire rst
    );

    wire  [`InstrAddrBus]          instr_addr;
    wire  [`InstrBus]              instr;
    wire                           rom_ce;
    wire  [31:0]                   ram_data_i;
    wire                           ram_we;
    wire  [3:0]                    ram_sel;
    wire  [`DataMemNumLog2+1:0]    ram_addr;
    wire  [31:0]                   ram_data_o ;   

    risc_v   i_risc_v(
        .clk(clk),
        .rst(rst),
        
        .rom_data_i(instr),
        .rom_addr_o(instr_addr),
        .rom_ce_o(rom_ce),
        
        .ram_data_i(ram_data_i),
        .ram_we_o(ram_we),
        .ram_sel_o(ram_sel),
        .ram_addr_o(ram_addr),
        .ram_data_o(ram_data_o)
    ); 
    
    insrt_rom  i_insrt_rom(
        .addr(instr_addr[`InstrMemNumLog2+1:0]),
        .ce(rom_ce),
        .instr_o(instr)
    );

    data_ram i_data_ram(
        .rst(rst),
        .clk(clk),
        .we_i(ram_we),
        .sel_i(ram_sel),
        .addr_i(ram_addr),
        .data_i(ram_data_o),
        .data_o(ram_data_i)
    );
    
    endmodule