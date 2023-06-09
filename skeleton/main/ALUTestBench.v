//extra file
module AluTestBench();
reg[31:0] a,b;
reg[2:0] alucontrol;
wire[31:0] result;
wire zero;

ArithmeticLogicUnit alutest(
    .a(a),
    .b(b),
    .alucontrol(alucontrol),
    .result(result),
    .zero(zero)
);
initial 
    begin
        a = 32'd170;
        b = 32'd85;
        alucontrol = 3'd7;
    end

initial
	begin
		$dumpfile("alutest.vcd");
		$dumpvars;
		#5;
		if (zero == 1'b1 && result == 32'd0)
			$display("Simulation succeeded");
		else
			$display("Simulation failed");
	end
	
	initial 
	begin 
		$display("\t\ttime ,\tresult ,\ta, \tb, \talucontrol ");
		$monitor("%d ,\t%b ,\t%d ,\t%d " ,$time, result, a, b, alucontrol);
	end 


endmodule