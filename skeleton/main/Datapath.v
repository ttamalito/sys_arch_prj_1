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

	// Fetch: Pass PC to instruction memory and update PC
	ProgramCounter pcenv(clk, reset, dobranch, signimm, jump, instr[25:0], pc);

	// Execute:
	// (a) Select operand
	SignExtension se(instr[15:0], signimm);
	assign srcbimm = alusrcbimm ? signimm : srcb;
	// (b) Perform computation in the ALU
	ArithmeticLogicUnit alu(srca, srcbimm, alucontrol, aluout, zero);
	// (c) Select the correct result
	assign result = memtoreg ? readdata : aluout;

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
	output [31:0] progcounter
);
	reg  [31:0] pc;
	wire [31:0] incpc, branchpc, nextpc;

	// Increment program counter by 4 (word aligned)
	Adder pcinc(.a(pc), .b(32'b100), .cin(1'b0), .y(incpc));
	// Calculate possible (PC-relative) branch target
	Adder pcbranch(.a(incpc), .b({branchoffset[29:0], 2'b00}), .cin(1'b0), .y(branchpc));
	// Select the next value of the program counter
	assign nextpc = dojump   ? {incpc[31:28], jumptarget, 2'b00} :
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
wire[31:0] sum; //sums up a+b 
wire first_xor; // wire for first xor gate (see ALU schema) 
wire second_xor;// wire for second xor gate (see ALU schema)
wire [31:0]extend;

assign b_multi = (alucontrol[2] == 1'd0) ?  b : ~b; //logic for a&b
assign a_and_b = a & b_multi;
assign a_or_b = a | b_multi;
assign sum =(alucontrol[2] == 1'd0)? a + b_multi: a + b_multi + 1'b1 ; // sum or substraction depending on the multiplexer 
assign first_xor = a[31] ^ b_multi[31]; //xor with the most significant digits of a and b/~b 
assign second_xor = first_xor ^ sum[31];
assign extend = {{31{1'b0}},second_xor};//ask in office hour for carry in from sum, for now negate extend. also ask for overflow

//logic for the  main multiplexer

assign result = (alucontrol[1:0]== 2'd0) ? a_and_b : (alucontrol[1:0] == 2'd1) ? a_or_b : (alucontrol[1:0]== 2'd2) ? sum :(alucontrol[2:0]== 3'd7) ? extend: 32'bx ; //main multiplexer logic
assign zero = (result[31:0] == 'b0) ? 1'b1 : 1'b0;    

endmodule
