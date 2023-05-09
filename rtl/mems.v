module mems #(
	parameter DWI = 8*32,
	parameter DWO = 2*32,
	parameter AWI = 14,
	parameter AWO = 16
)(
	input				clk,
	input				wen,
	input [AWI-1:0]		wr_ptr,
	input [DWI-1:0]		din,

	input				ren,
	input [AWO-1:0]		rd_ptr,
	output [DWO-1:0]	dout
);
	
	reg [AWI-1:0] addr;
	reg [0:3] sel;

	always@(*) begin
		if(wen)
			addr = wr_ptr;
		else if(ren)
			addr = rd_ptr[13:0];
		else
			addr = 0;
	end

	always@(*) begin
		if(wen)
			sel = 4'hf;
		else if(ren)
			case(rd_ptr[15:14])
				2'b0: sel = 4'b1000;
				2'b1: sel = 4'b0100;
				2'b10: sel = 4'b0010;
				2'b11: sel = 4'b0001;
				default: sel = 4'bx;
			endcase
		else
			sel = 4'b0;
	end

	genvar i_ram;
	generate
		for(i_ram=0; i_ram<4; i_ram=i_ram+1) begin: sram
			/*sram_top #(
				.DW(64),
				.MW(8),
				.AW(14)
			) sram_4kx64_u(
				.clk(clk),
				.cs(ren^wen&sel[i_ram]),
				.we(wen),
				.wem(8'hFF),
				.addr(addr),
				.din(din[i_ram*64+:64]),

				.dout(dout)
			);*/
			sirv_sim_ram #(
				.DW(64),
				.MW(8),
				.AW(14)
			) sram_4kx64_u(
				.clk(clk),
				.cs(ren^wen&sel[i_ram]),
				.we(wen),
				.wem(8'hFF),
				.addr(addr),
				.din(din[i_ram*64+:64]),

				.dout(dout)
			);
		end
	endgenerate

endmodule
