module par2ser #(
	parameter DWI = 56*32,
	parameter DWO = 8*32
)(
	input					clk,
	input					rst_n,
	input [DWI-1:0]			din,
	input					valid,

	output reg				ready,
	output					wen,
	output [DWO-1:0]		dout
);

	reg [DWI-1:0] shift;
	reg [5:0] cnt;
	wire [DWO-1:0] dout;
	reg valid_stall;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			cnt <= 0;
		else if(valid && ready)			
			cnt <= 7;
		else if(cnt)
			cnt <= cnt - 1;			
	end

	always@(*) begin
		if(!cnt && valid)
			ready = 1'b1;
		else
			ready = 1'b0;
	end

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			valid_stall <= 1'b0;
		else if(valid && ready)
			valid_stall <= 1'b1;
		else if(!cnt)
			valid_stall <= 1'b0;
	end

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			shift <= 0;
		else if(valid && ready)
			shift <= din;
		else
			shift <= {{DWO{1'b0}}, shift[(DWI-1)-:DWO]};
	end

	assign dout = valid_stall ? shift[0+:DWO] : 0;
	assign wen = valid_stall;

endmodule
