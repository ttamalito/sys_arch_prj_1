module Division(
	input         clock,
	input         start,
	input  [31:0] a,
	input  [31:0] b,
	output [31:0] q,
	output [31:0] r
);

	// store B
	reg [31:0] divisor, dividend, partial_result;
	// store A and Q
	//reg [31:0] intermediate;
	// store R for the loop
	reg [31:0] remainder;
	
	wire [31:0] r_prime; // I belive the greatest value to be stored here is 3, but for the moment make it 32 bit
	wire predicate; // stores the value r_prime < B, so its either true or false
	// define a counter
	reg [4:0] counter; // define a counter for the 32 iterations
	reg [4:0] q_counter; // i think we dont need this one, will check later
	
	// the combinatorial circuit
	assign r_prime = (remainder << 1) + dividend[counter]; // r_prime = 2 * remainder + A[i] i-th iteration
	assign predicate = r_prime < divisor[31:0];
	//$display("Value of predicate outside the always is    ", predicate);
	wire r_prime_minus_b;
	assign r_prime_minus_b = r_prime - divisor;
	
	// decrease the counters
	wire [4:0] decreased_q_counter, decreased_counter, q_counter_value, counter_dividend_value;
	assign decreased_q_counter = (q_counter == 5'b0) ? 5'b0 : q_counter[4:0] - 1'b1;
	assign decreased_counter = (counter == 5'b0) ? 5'b0 : counter[4:0] - 1'b1;
	assign q_counter_value = q_counter[4:0];
	assign counter_dividend_value = counter[4:0];
	/*
	If at a rising edge of clock the start signal is set (start = 1), we store the inputs A and B in the corresponding
registers and start the computation
*/
always @ (posedge clock) begin 
	if (start) begin
		// start the computation
		remainder[31:0] <= 31'b0;
		divisor <= b;
		dividend <= a;
		counter <= 5'd31;
		q_counter <= 5'd31;
		partial_result <= 31'b0;
		end
	if (predicate) begin
		//$display("Value of predicate is  ", predicate);
		//$display("Value of q_counter predicate true   " , q_counter);
		partial_result[q_counter_value] <= 1'b0; // Q[i] = 0
		//$display("Value of R' is  ",  r_prime);
		remainder <= r_prime; // R = R'
		//$display("Value of R in true ", remainder);
		//$display("Value of dividend is in true ", dividend[counter]);
		// decrease the counter
		q_counter <= decreased_q_counter;
		counter <= decreased_counter;
		//$display("Value of the counter", counter);
		//$display("Value of the q_counter", q_counter);
		end
	if (!predicate) begin
		//$display("Value of q_counter predicate false    " , q_counter);
		partial_result[q_counter_value] <= 1'b1; // Q[i] = 1
		remainder <= r_prime_minus_b; // R = R' - B
		// decrease the counter
		q_counter <= decreased_q_counter; // decrease the counter
		counter <= decreased_counter;
		//$display("Value of the counter", counter);
		//$display("Value of the q_counter", q_counter);
		end
		
	end
	
	// final output
	// if the counter == 0, that means that the 32 cycles already went by
	// so no output
	assign q = partial_result; // do we need to output until the final result or are we allowed to output something in between the 32 iterations
	assign r = remainder;
		
endmodule
