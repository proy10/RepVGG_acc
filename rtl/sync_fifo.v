module sync_fifo #(
	parameter AWI = 6,
	parameter AWO = 12,
	parameter DWI = 1792,
	parameter DWO = 32
)(
	input					clk,
	input					rst_n,
	input					wen,
	input [DWI-1:0]			wdata,

	input					ren,
	output [DWO-1:0]		rdata
);
	

	
	//write
	genvar i_wr;
	generate 
		//extend
		if(DWI <= DWO) begin: extend
			reg [AWI-1:0] wr_ptr;
			reg [AWO-1:0] rd_ptr;
			reg [DWI-1:0] mems [0:1<<AWI-1];

			for(i_wr=0; i_wr<56; i_wr=i_wr+1) begin
				always@(posedge clk) begin
					if(wen)
						mems[wr_ptr+i_wr] <= wdata[i_wr*DWI+:DWI];
				end
			end
		end

		//shrink
		else begin: shrink
			reg [AWI-1:0] wr_ptr;
			reg [AWO-1:0] rd_ptr;
			reg [DWO-1:0] mems [0:1<<AWO-1];

			for(i_wr=0; i_wr<56; i_wr=i_wr+1) begin
				always@(posedge clk) begin
					if(wen)
						mems[wr_ptr+i_wr] <= wdata[i_wr*DWO+:DWO];
				end
			end
		end
	endgenerate

endmodule
