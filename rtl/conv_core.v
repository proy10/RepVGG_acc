module conv_core (
	input 			clk,
	input 			rst_n,

	output [32-1:0]		ifm_addr,
	output			ifm_cs,
	output			ifm_we,
	output [32/8-1]		ifm_wem,
	input [32-1:0]		ifm_i,

	output [32-1:0]		wht_addr,
	output			wht_cs,
	output			wht_we,
	output [32/8-1]		wht_wem,
	input [32-1:0]		wht_i,

	input 			state,

	output [32-1:0]		res_o
);


//ifm serial to parallel
	wire [56*16-1:0] ifm;
	wire ifm_en;	

	assign ifm_en = state[0];
	
	ser2par u_s2p_ifm(
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
	wire [3*16-1:0] wht;
	wire wht_en;

	assign wht_en = state[1];
	
	ser2par u_s2p_wht(
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

endmodule
