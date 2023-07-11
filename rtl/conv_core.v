module conv_core (
	input 			clk,
	input 			rst_n,
	//input [32-1:0]		ctrl,
	input [32-1:0]		state,

	output [32-1:0]		ifm_addr,
	output			ifm_cs,
	output			ifm_we,
	output [32/8-1:0]	ifm_wem,
	input [32-1:0]		ifm_i,

	output [32-1:0]		wht_addr,
	output			wht_cs,
	output			wht_we,
	output [32/8-1:0]	wht_wem,
	input [32-1:0]		wht_i,

	output [32-1:0]		res_addr,
	output reg		res_cs,
	output reg		res_we,
	output [32/8-1:0]	res_wem,
	output [32-1:0]		res_o
);


//ifm serial to parallel
	wire ifm_en;	
	//wire [4*16-1:0] ifm_exp;
	wire [14*8-1:0] ifm;

	assign ifm_en = state[4];
	//assign ifm_exp = {{8{ifm_i[31]}}, ifm_i[31-:8], {8{ifm_i[23]}}, ifm_i[23-:8], {8{ifm_i[15]}}, ifm_i[15-:8], {8{ifm_i[7]}}, ifm_i[7-:8]};
	
	ser2par #(
		.DWI(32),
		.DWO(112)
	) u_s2p_ifm (
		.clk(clk),
		.rst_n(rst_n),
		.en(ifm_en),
		.din(ifm_i),
		.dout(ifm)
	);

	//read
	reg [32-1:0] ifm_ptr;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			ifm_ptr <= 0;
		else if(state[0])
			ifm_ptr <= ifm_ptr + 1;
	end
	
	assign ifm_addr = ifm_ptr;
	assign ifm_cs = state[0];
	assign ifm_we = state[0];
	assign ifm_wem = 4'hf;

//wht serial to parallel
	wire wht_en;
	//wire [4*16-1:0] wht_exp;
	wire [48-1:0] wht;

	assign wht_en = state[5];
	//assign wht_exp = {{8{wht_i[31]}}, wht_i[31-:8], {8{wht_i[23]}}, wht_i[23-:8], {8{wht_i[15]}}, wht_i[15-:8], {8{wht_i[7]}}, wht_i[7-:8]};
	
	ser2par #(
		.DWI(32),
		.DWO(48)
	) u_s2p_wht(
		.clk(clk),
		.rst_n(rst_n),
		.en(wht_en),
		.din(wht_i),
		.dout(wht)
	);	

	//read
	reg [32-1:0] wht_ptr;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			wht_ptr <= 0;
		else if(state[1])
			wht_ptr <= wht_ptr + 1;
	end
	
	assign wht_addr = wht_ptr;
	assign wht_cs = state[1];
	assign wht_we = state[1];
	assign wht_wem = 4'hf;

//pe init
	wire [1:0] pe_en;
	wire [18*32-1:0] pe_res;

	assign pe_en = state[3:2];

	genvar pe_i;
	generate
		for(pe_i=0; pe_i<2; pe_i=pe_i+1) begin: u_pe
			pe u_pe(
				.clk(clk),
				.rst_n(rst_n),
				.en(pe_en[pe_i]),
				.ifm_i(ifm[pe_i*7*8+:7*8]),
				.wht_i(wht[pe_i*3*8+:3*8]),
				.res_o(pe_res[pe_i*9*32+:9*32])
			);
		end
	endgenerate

//pa init
	wire [1:0] pa_en;
	wire [18*32-1:0] pa_res;

	assign pa_en = state[7:6];

	genvar pa_i;
	generate
		for(pa_i=0; pa_i<2; pa_i=pa_i+1) begin: u_pa
			part_adder #(
				.DW(288)
			) u_pa(
				.clk(clk),
				.rst_n(rst_n),
				.en(pa_en[pa_i]),
				.din(pe_res[pa_i*9*32+:9*32]),
				.dout(pa_res[pa_i*9*32+:9*32])
			);
		end
	endgenerate

//ba init
	wire ba_en;
	wire [9*32-1:0] ba_res;

	assign ba_en = state[8];

	block_adder #(
		.DWI(576),
		.DWO(288)
	) u_ba(
		.clk(clk),
		.rst_n(rst_n),
		.en(ba_en),
		.din(pa_res),
		.dout(ba_res)
	);

//ca init
	wire ca_en;
	wire [224-1:0] ca_res;

	assign ca_en = state[9];

	chnl_adder #(
		.DWI(288),
		.DWO(224)
	) u_ca(
		.clk(clk),
		.rst_n(rst_n),
		.en(ca_en),
		.din(ba_res),
		.dout(ca_res)
	);

//relu init
	wire relu_en;
	wire [224-1:0] relu_res;

	assign relu_en = state[10];

	relu #(
		.DW(224)
	) u_relu(
		.clk(clk),
		.rst_n(rst_n),
		.en(relu_en),
		.din(ca_res),
		.dout(relu_res)
	);

//par2ser init
	wire p2s_wen, p2s_ren;

	assign p2s_wen = state[11];
	assign p2s_ren = state[12];

	par2ser #(
		.DWI(224),
		.DWO(32)
	) u_p2s(
		.clk(clk),
		.rst_n(rst_n),
		.wen(p2s_wen),
		.ren(p2s_ren),
		.din(relu_res),
		.dout(res_o)
	);

	//write
	reg [32-1:0] res_ptr;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			res_ptr <= 32'b0;
		else if(state[12])
			res_ptr <= res_ptr + 1;
	end

	assign res_addr = res_ptr;
	assign res_wem = 4'hf;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			res_cs <= 1'b0;
			res_we <= 1'b0;
		end
		else if(state[12]) begin
			res_cs <= state[12];
			res_we <= state[12];
		end
	end

endmodule
