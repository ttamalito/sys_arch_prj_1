module MealyPattern(
	input        clock,
	input        i,
	output [1:0] o
);
// Define the logic
// define the registers to store 010 and 101
// 2bit register to store 010 (name of the machine is 010)
reg [1:0] zero_one_zero;
// 2-bit register to store 101 (name of the machine is 010)
reg [1:0] one_zero_one;

// set the values to zero of the registers
initial begin
	zero_one_zero[0] = 'b0;
	zero_one_zero[1] = 'b0;
	one_zero_one[0] = 'b0;
	one_zero_one[1] = 'b0;
	end 
// logic to store in Q1 for 010
// note Q1 == reg[0] i.e., the least significant bit
wire w1;
assign w1 = i & (~zero_one_zero[0]); // not Q1 AND input
wire w2;
assign w2 = w1 & zero_one_zero[1]; // w1 AND Q2

//logic to compute Q2 for zero_one_zero
wire w3;
assign w3 = ~i & (~zero_one_zero[0]); // NOT input AND NOT Q1
wire w4;
assign w4 =  ~i & (~zero_one_zero[1]); // NOT input AND NOT Q2
wire w5;
assign w5 = w3 | w4; // w3 OR w4

// logic for the output 
wire w6;
assign w6 =  ~i & (zero_one_zero[0]); // NOT input AND Q1



// now the logic for 101... pretty similar
wire w7, w8, w9, w10, w11, w12;
assign w7 = ~i & (~one_zero_one[0]); // NOT input AND NOT Q1
assign w8 = w7 & one_zero_one[1]; // w7 AND Q2
assign w9 = i & (~one_zero_one[0]); // input AND NOT Q1
assign w10 = i & (~one_zero_one[1]); // input AND NOT Q2
assign w11 = w9 | w10; // w9 OR w10
assign w12 = i & (one_zero_one[0]); // input AND Q1


// now define the sequential circuit

always @ (posedge clock) begin
	// modify the states of the registers accordingly 
	// w2 has the new value for Q1 for zero_one_zero
	zero_one_zero[0] <= w2;
	// w5 has the new value for Q2 for zero_one_zero
	zero_one_zero[1] <= w5;
	// w8 has the new value for Q1 for one_zero_one
	one_zero_one[0] <= w8;
	// w11 has the new value for Q2 for one_zero_one
	one_zero_one[1] <= w11;
	end
	// the output
assign o[1] = w6 & (~zero_one_zero[1]); // w6 AND NOT Q2
	// the final output 
assign o[0] = w12 & (~one_zero_one[1]); // w12 AND NOT Q2
endmodule

module MealyPatternTestbench();

	// define the inputs
	reg clock, i;
	wire [1:0] o;

	MealyPattern machine(.clock(clock), .i(i), .o(o));

	//initial stae
	initial 
	begin
		clock = 0;
		i =0;
		//#2;
		//i = 0;
		#2;
		i = 1;
		#2;
		i = 1;
		#2;
		i = 0;
		#2;
		i = 1;
		#2;
		i = 0;
		#2;
		i = 1;	
		#2;
		i = 0;
		#2;
		i = 1;
		#2;
		i = 1;
		$finish;
	end
	
	always begin
		#1;
		clock = !clock;
	end
	
	initial 
	begin 
		$dumpfile ("mealy.vcd");
		$dumpvars;
	end
	
initial 
	begin 
		$display("\t\ttime ,\tclock ,\ti, \to ");
		$monitor("%d ,\t%b ,\t%b ,\t%b " ,$time, clock, i, o);
	end 
		
endmodule

