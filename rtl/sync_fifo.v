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
	
	parameter EXTENT = DWO / DWI;
	parameter SHRINK = DWI / DWO;
	
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
						//mems[wr_ptr+i_wr] <= wdata[i_wr*DWI+:DWI];
				end
			end
		end

		//shrink
		else begin: shrink
			reg [AWI-1:0] wr_ptr;
			reg [AWO-1:0] rd_ptr;
			reg wover_flag, rover_flag;
			reg [DWO-1:0] mems [0:1<<AWO-1];
			reg full, empty;

			always@(posedge clk or negedge rst_n) begin
				if(!rst_n)
					full = 0;
				else if((wr_ptr*SHRINK == rd_ptr) && (wover_flag != rover_flag))
					full = 1;
				else
					full = 0;
			end

			always@(posedge clk or negedge rst_n) begin
				if(!rst_n)
					wr_ptr <= 0;
				else if(wen && !full) begin
					if(wr_ptr == 56) begin
						wr_ptr <= 0;
						wover_flag = ~wover_flag;
					end
					else
						wr_ptr <= wr_ptr + 1;
				end
			end	

			always@(posedge clk or negedge rst_n) begin
				if(!rst_n)
					rd_ptr <= 0;
				else if(ren && !empty) begin
					if(rd_ptr == 56*SHRINK) begin
						rd_ptr <= 0;
						rover_flag = ~rover_flag;
					end
					else
						rd_ptr <= rd_ptr + 1;
				end
			end			

			//write
			for(i_wr=0; i_wr<SHRINK; i_wr=i_wr+1) begin
				always@(posedge clk) begin
					if(wen)
						mems[wr_ptr*SHRINK+i_wr] <= wdata[i_wr*DWO+:DWO];
				end
			end

			//read
			always@(posedge clk) begin
				if(ren)
					rdata <= mems[rd_ptr];
			end
		end
	endgenerate

endmodule
