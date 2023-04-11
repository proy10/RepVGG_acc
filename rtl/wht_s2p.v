module #(
	parameter DW = 32,
	parameter DEPTH = 10
)(
	input							clk,
	input							rst_n,
	input [DW-1:0]					data_i,

	output [DW*DEPTH-1:0]			data_o
);

	reg [DW*DEPTH-1:0] mem;
	reg [3:0] wr_ptr;
	reg full;

	always@(posedge clk or rst_n) begin
		if(!rst_n) 
			wr_ptr <= 0;
		else if(wr_ptr == (DEPTH-1))
			wr_ptr <= 0;
		else
			wr_ptr <= wr_ptr + 1;
	end

	//write
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			mem <= 0;
		end
		else begin
			mem[(wr_ptr*DW)+:DW] <= data_i;
		end
	end

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			full = 1'b0;
		else if(wr_ptr == (DEPTH-1))
			full = 1'b1;
		else
			full = 1'b0;
	end

	//read
	assign data_o = (full) ? mem : 0;

endmodule
