/*module ser2par #(
	parameter DW = 32,
	parameter DP = 56
)(
	input					clk,
	input					rst_n,
	input [DW-1:0]			data_i,
	//input					sel, //0 denotes active
	
	output [DW*DP-1:0]	data_o
);
	
	reg [DW*DP-1:0] mem;
	reg [5:0] wr_ptr;
	reg full;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) 
			wr_ptr <= 0;
		else if(wr_ptr == (DP-1))
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
		else if(wr_ptr == (DP-1))
			full = 1'b1;
		else
			full = 1'b0;
	end

	//read
	assign data_o = (full) ? mem : 0;

endmodule*/


module ser2par #(
	parameter DWI = 128, //4 data
	parameter DWO = 56*32
)(
	input				clk,
	input				rst_n,
	input				en,
	input [DWI-1:0]		data_i,

	output [DWO-1:0]	data_o
);

	reg [DWO-1:0]	reg_o;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			reg_o <= 0;
		else if(en)
			reg_o <= {reg_o[DWO-DWI-1:0], data_i};
	end

	assign data_o = (en) ? 0 : reg_o;

endmodule
