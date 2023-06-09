module pe1x1 #(
	parameter INPUT_NUM = 7,
	parameter OUTPUT_NUM = 7,
	parameter IW = 24,
	parameter FW = 8
)(
	input 									clk,
	input 									rst_n,
	input [INPUT_NUM*(IW+FW)-1:0]			fmap_i,
	input [IW+FW-1:0] 						wht_i,

	output [OUTPUT_NUM*(IW+FW)-1:0] 		res_o
);

	wire [IW+FW-1:0] fmap_regs [0:INPUT_NUM-1];
	wire [IW+FW-1:0] MulRes_regs [0:INPUT_NUM-1];
	reg [IW+FW-1:0] res_regs [0:OUTPUT_NUM-1];

	genvar m;
	generate
		for(m=0; m<INPUT_NUM; m=m+1) begin: read_fmap
			assign fmap_regs[m] = fmap_i[m*(IW+FW)+IW+FW-1:m*(IW+FW)];
		end
	endgenerate

	genvar i;
	generate
		for(i=0; i<INPUT_NUM; i=i+1) begin: mul_inst
			mul #(
				.IW(IW),
				.FW(FW)
			) u_mul( 
				.fmap(fmap_regs[i]),
				.wht(wht_i),
				.res(MulRes_regs[i])
			);
		end
	endgenerate
	
	genvar j;
	generate
		for(j=0; j<OUTPUT_NUM; j=j+1) begin: read_res
			always@(posedge clk or negedge rst_n) begin
				if(!rst_n)
					res_regs[j] <= 0;
				else
					res_regs[j] <= MulRes_regs[j];
			end
		end
	endgenerate

	genvar k;
	generate
		for(k=0; k<OUTPUT_NUM; k=k+1) begin: write_res
			assign res_o[k*(IW+FW)+IW+FW-1:k*(IW+FW)] = res_regs[k];
		end
	endgenerate
	
endmodule
