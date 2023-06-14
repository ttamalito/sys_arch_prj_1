module Datapath(
	input         clk, reset,
	input         memtoreg,
	input         dobranch,
	input         alusrcbimm,
	input  [4:0]  destreg,
	input         regwrite,
	input         jump,
	input  [2:0]  alucontrol,
	output        zero,
	output [31:0] pc,
	input  [31:0] instr,
	output [31:0] aluout,
	output [31:0] writedata,
	input  [31:0] readdata
);
	wire [31:0] pc;
	wire [31:0] signimm;
	wire [31:0] srca, srcb, srcbimm;
	wire [31:0] result;
	wire [31:0] paddwire; // for the new padding extension module
	wire [31:0] zero_left_wire;
	wire [31:0] jal_wire;
	wire [31:0] mflo_wire;
	wire [31:0] mfhi_wire;
	wire [31:0] lo,hi;
	wire enable_mul;

	assign {hi,lo} =  32'd123* 32'd456;// {srca, srcb};
	assign enable_mul = (instr[5:0] == 6'b011001) ? 1 : 0;

	Multiplication mul(.clk(clk),.mul_enable(enable_mul), .wd3hi(hi),.wd3lo(lo), .mfhi(mfhi_wire),.mflo(mflo_wire));
	// Fetch: Pass PC to instruction memory and update PC
	ProgramCounter pcenv(clk, reset, dobranch, signimm, jump, instr[25:0], aluout, instr[31:26],srca,instr[5:0],alucontrol, pc,jal_wire); // I added the result of the ALU and the operation code, as inputs
	
	// Execute:
	// (a) Select operand
	SignExtension se(instr[15:0], signimm);
	BackExtend back(instr[15:0],paddwire);
	ZeroExtend padd(instr[15:0],zero_left_wire);
	assign srcbimm = (instr[31:26]== 6'b001101)? zero_left_wire : (instr[31:26] == 6'b001111) ? paddwire : alusrcbimm ? signimm : srcb; //if LUI then use paddwire to add zeros to the front 
	// (b) Perform computation in the ALU
	ArithmeticLogicUnit alu(srca, srcbimm, alucontrol, aluout, zero);
	// (c) Select the correct result
	assign result = (instr[5:0] == 6'b010010 && instr[31:16] == 16'd0 && instr[10:5] == 5'd0 && alucontrol[2:0] == 3'b011) ? mflo_wire : (instr[5:0] == 6'b010000 && instr[31:16] == 16'd0 && instr[10:5] == 5'd0 && alucontrol[2:0] == 3'b011 ) ? mfhi_wire : (instr[31:26] == 6'b000011 && jump == 1'b1) ? jal_wire : memtoreg ? readdata : aluout;

	// Memory: Data word that is transferred to the data memory for (possible) storage
	assign writedata = srcb;

	// Write-Back: Provide operands and write back the result
	RegisterFile gpr(clk, regwrite, instr[25:21], instr[20:16],
				   destreg, result, srca, srcb);
	

endmodule

module ProgramCounter(
	input         clk,
	input         reset,
	input         dobranch,
	input  [31:0] branchoffset,
	input         dojump,
	input  [25:0] jumptarget,
	input  [31:0] aluResult,
	input  [5:0] opCode,
	input [31:0] jr_pc,
	input [5:0] least_sig_bits,
	input [2:0] alucontrol,
	output [31:0] progcounter,
	output [31:0] pc_plus // additional output 
);
	reg  [31:0] pc;
	wire [31:0] incpc, branchpc, nextpc;

	// Increment program counter by 4 (word aligned)
	Adder pcinc(.a(pc), .b(32'b100), .cin(1'b0), .y(incpc));
	// Calculate possible (PC-relative) branch target
	Adder pcbranch(.a(incpc), .b({branchoffset[29:0], 2'b00}), .cin(1'b0), .y(branchpc));
	assign pc_plus = incpc;
	
	// Select the next value of the program counter
	/*
	The following logic was added: 
	IF the opCOde is the code of BLGTZ and the result of the ALU is 1 and doBranch is 1, then take the branch
	aluResult is going to be 1 when A < 0. So in that case we should take the branch
	*/
	assign nextpc = (least_sig_bits[5:0] == 6'b001000 && dojump == 1 && alucontrol[2:0] == 3'b100) ? jr_pc :(opCode == 6'b000001 && aluResult == 32'd1 && dobranch) ? branchpc: dojump   ? {incpc[31:28], jumptarget, 2'b00} :
					dobranch ? branchpc :
							   incpc;

	// The program counter memory element
	always @(posedge clk)
	begin
		if (reset) begin // Initialize with address 0x00400000
			pc <= 'h00400000;
		end else begin
			pc <= nextpc;
		end
	end

	// Output
	assign progcounter = pc;

endmodule

module RegisterFile(
	input         clk,
	input         we3,
	input  [4:0]  ra1, ra2, wa3,
	input  [31:0] wd3,
	output [31:0] rd1, rd2
);
	reg [31:0] registers[31:0];

	always @(posedge clk)
		if (we3) begin
			registers[wa3] <= wd3;
			$display("We are writing this", wd3);
		end

	assign rd1 = (ra1 != 0) ? registers[ra1] : 0;
	assign rd2 = (ra2 != 0) ? registers[ra2] : 0;
endmodule

module Adder(
	input  [31:0] a, b,
	input         cin,
	output [31:0] y,
	output        cout
);
	assign {cout, y} = a + b + cin;
endmodule

module SignExtension(
	input  [15:0] a,
	output [31:0] y
);
	assign y = {{16{a[15]}}, a};
endmodule

module ArithmeticLogicUnit(
	input  [31:0] a, b,
	input  [2:0]  alucontrol,
	output [31:0] result,
	output        zero
);
wire[31:0] b_multi; //wire for multiplexer takes b or ~b
wire[31:0] a_and_b;// wire for a&b
wire[31:0] a_or_b;
wire cout1; // creating our own adder kinda 
wire[31:0] sum; //sums up a+b 
wire first_xor; // wire for first xor gate (see ALU schema) 
wire second_xor;// wire for second xor gate (see ALU schema)
wire [31:0]extend;

assign b_multi = (alucontrol[2] == 1'd0) ?  b : ~b; //logic for a&b
assign a_and_b = a & b_multi;
assign a_or_b = a | b_multi;
assign {cout1,sum} =(alucontrol[2] == 1'd0)? a + b_multi: a + b_multi + 1'b1 ; // sum or substraction depending on the multiplexer 
assign first_xor = a[31] ^ b_multi[31]; //xor with the most significant digits of a and b/~b 
assign second_xor = first_xor ^ cout1 ;
assign extend = {{31{1'b0}},second_xor};//ask in office hour for carry in from sum, for now negate extend. also ask for overflow

//logic for the  main multiplexer

assign result = (alucontrol[1:0]== 2'd0) ? a_and_b : (alucontrol[1:0] == 2'd1) ? a_or_b : (alucontrol[1:0]== 2'd2) ? sum :(alucontrol[2:0]== 3'd7) ? extend: 32'bx ; //main multiplexer logic
assign zero = (result[31:0] == 'b0) ? 1'b1 : 1'b0;    

endmodule
//module for padding with zeros
module BackExtend(
	input[15:0] a,
	output[31:0] y
); 
assign y = {a,{16{1'b0}}};
endmodule

module ZeroExtend(
	input[15:0] a,
	output[31:0] y
); 
assign y = {{16{1'b0}},a};
endmodule

module Multiplication (
	input clk,
	input mul_enable,
	input [31:0] wd3hi, wd3lo,
	output [31:0] mfhi, mflo
);
assign mfhi = mul_registers[1];
assign mflo = mul_registers[0];
reg[31:0] mul_registers [1:0];
always @(posedge clk) 
begin
	if(mul_enable)
	begin
		$display("this is wd3hi", wd3hi);
		$display("this is wd3lo", wd3lo);
		mul_registers[1] <= wd3hi;
		mul_registers[0] <= wd3lo;
	end
end

	
endmodule