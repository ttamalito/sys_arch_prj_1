//extra file 
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
assign extend = second_xor;//{{31{1'b0}},second_xor};

//logic for the  main multiplexer

assign result = (alucontrol[1:0]== 2'd0) ? a_and_b : (alucontrol[1:0] == 2'd1) ? a_or_b : (alucontrol[1:0]== 2'd2) ? sum :(alucontrol[2:0]== 3'd7) ? extend: 32'bx ; //main multiplexer logic
assign zero = (result[31:0] == 'b0) ? 1'b1 : 1'b0;    

endmodule