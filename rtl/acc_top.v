module acc_top (
	input				clk,
	input				rst_n,

	input				i_icb_cmd_valid,
	output				i_icb_cmd_ready,
	input [32-1:0]			i_icb_cmd_addr,
	input				i_icb_cmd_read,
	input [32-1:0]			i_icb_cmd_wdata,
	input [32/8-1:0]		i_icb_cmd_wmask,

	output				i_icb_rsp_valid,
	input				i_icb_rsp_ready,
	output				i_icb_rsp_err,
	output reg [32-1:0]		i_icb_rsp_rdata
);

//Address range: 0x1010_0000 -- 0x101F_FFFF
	localparam BASE_ADDR 		= 32'h1010_0000;
	localparam CTRL_ADDR 		= 32'h1010_0004; //RW
	localparam STATUS_ADDR 		= 32'h1010_1008; //R
	localparam IFM_SRAM_ADDR	= 32'h1014_0000; //RW
	localparam WHT_SRAM_ADDR	= 32'h1018_0000; //RW
	localparam RESULT_SRAM_ADDR	= 32'h101C_0000; //R


//Interface
	wire check_addr;
	assign i_icb_cmd_ready = i_icb_rsp_ready & check_addr;
	assign i_icb_rsp_valid = i_icb_cmd_valid & check_addr & i_icb_cmd_read;
	assign check_addr = (i_icb_cmd_addr[31:20] == BASE_ADDR[31:20]);

	reg [32-1:0] i_icb_cmd_addr_reg;
	reg i_icb_cmd_read_reg;
	reg [32/8-1:0] i_icb_cmd_wmask_reg;

	always@(posedge clk) begin
		i_icb_cmd_addr_reg <= i_icb_cmd_addr;
		i_icb_cmd_read_reg <= i_icb_cmd_read;
		i_icb_cmd_wmask_reg <= i_icb_cmd_wmask;
	end

	//write
	reg [32-1:0] ctrl;
	reg [32-1:0] status;
	reg [32-1:0] ifm_wdata;
	reg [32-1:0] icb_wht_wdata;
	reg icb_ifm_we, icb_wht_we, icb_ifm_cs, icb_wht_cs;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			ctrl <= 32'h0;
			status <= 32'h0;
		end
		else begin
			icb_ifm_we <= 1'b0;
			icb_wht_we <= 1'b0;
			icb_ifm_cs <= 1'b0;
			icb_wht_cs <= 1'b0;
			if(i_icb_cmd_valid & i_icb_cmd_ready & ~i_icb_cmd_read) begin
				if(i_icb_cmd_addr == CTRL_ADDR)
					ctrl <= i_icb_cmd_wdata;
				else if((i_icb_cmd_addr >= IFM_SRAM_ADDR) & (i_icb_cmd_addr < WHT_SRAM_ADDR)) begin
					ifm_wdata <= i_icb_cmd_wdata;
					icb_ifm_we <= 1'b1;
					icb_ifm_cs <= 1'b1;
				end
				else if((i_icb_cmd_addr >= WHT_SRAM_ADDR) & (i_icb_cmd_addr < RESULT_SRAM_ADDR)) begin
					icb_wht_wdata <= i_icb_cmd_wdata;
					icb_wht_we <= 1'b1;
					icb_wht_cs <= 1'b1;
				end
			end
		end
	end

	//read
	wire [32-1:0] res_rdata;
	reg [32-1:0] rdata;
	reg ren;
	always@(posedge clk or negedge rst_n) begin
		ren <= 1'b0;
		if(i_icb_cmd_valid & i_icb_cmd_ready & i_icb_cmd_read)
			if(i_icb_cmd_addr == CTRL_ADDR)
				rdata <= ctrl;
			else if(i_icb_cmd_addr == STATUS_ADDR)
				rdata <= status;
			else if(i_icb_cmd_addr >= RESULT_SRAM_ADDR) begin
				rdata <= res_rdata;
				ren <= 1'b1;
			end
	end

	always(*) begin
		if(i_icb_rsp_valid & i_icb_rsp_ready)
			i_icb_rsp_rdata = rdata;
		else
			i_icb_rsp_rdata = 32'hx;
	end

//input feature map ram init
	wire [32-1:0] ifm_ram_din_wire, ifm_ram_dout_wire, ifm_ram_addr_wire;
	wire ifm_ram_we_wire, ifm_ram_cs_wire;
	wire [32/8-1:0] ifm_ram_wem_wire;
	wire ifm_ram_sel;
	
	assign ifm_ram_sel = ~i_icb_cmd_read & conv_ifm_we;
	assign ifm_ram_din_wire = icb_ifm_wdata;
	assign ifm_ram_addr_wire = (ifm_ram_sel) ? conv_ifm_addr : i_icb_cmd_addr_reg;
	assign ifm_ram_cs_wire = (ifm_ram_sel) ? conv_ifm_cs : icb_ifm_cs;
	assign ifm_ram_we_wire = (ifm_ram_sel) ? conv_ifm_we : ~i_icb_cmd_read_reg;
	assign ifm_ram_wem_wire = (ifm_ram_sel) ? conv_ifm_wem : i_icb_cmd_wmask_reg;

	sirv_sim_ram #(
		.DP(8192),
		.DW(32),
		.MW(32/8)
	) u_ifm_ram(
		.clk(clk),
		.din(ifm_ram_din_wire),
		.addr(ifm_ram_addr_wire),
		.cs(ifm_ram_cs_wire),
		.we(ifm_ram_we_wire),
		.wem(ifm_ram_wem_wire),
		.dout(ifm_ram_dout_wire)
	);

//weight ram init
	wire [32-1:0] wht_ram_din_wire, wht_ram_dout_wire, wht_ram_addr_wire;
	wire wht_ram_we_wire, wht_ram_cs_wire;
	wire [32/8-1:0] wht_ram_wem_wire;
	wire wht_ram_sel;
	
	assign wht_ram_sel = ~i_icb_cmd_read & conv_wht_we;
	assign wht_ram_din_wire = icb_wht_wdata;
	assign wht_ram_addr_wire = (wht_ram_sel) ? conv_wht_addr : i_icb_cmd_addr_reg;
	assign wht_ram_cs_wire = (wht_ram_sel) ? conv_wht_cs : icb_wht_cs;
	assign wht_ram_we_wire = (wht_ram_sel) ? conv_wht_we : ~i_icb_cmd_read_reg;
	assign wht_ram_wem_wire = (wht_ram_sel) ? conv_wht_wem : i_icb_cmd_wmask_reg;

	sirv_sim_ram #(
		.DP(8192),
		.DW(32),
		.MW(32/8)
	) u_wht_ram(
		.clk(clk),
		.din(wht_ram_din_wire),
		.addr(wht_ram_addr_wire),
		.cs(wht_ram_cs_wire),
		.we(wht_ram_we_wire),
		.wem(wht_ram_wem_wire),
		.dout(wht_ram_dout_wire)
	);

//result ram init
	sirv_sim_ram #(
		.DP(8192),
		.DW(32),
		.MW(32/8)
	) u_res_ram(
		.clk(clk),
		.din(),
		.addr(),
		.cs(),
		.we(),
		.wem(),
		.dout()
	);

//conv core
	wire conv_wht_we;
	conv_core u_core(
		.clk(clk),
		.rst_n(rst_n),
		.
	);

endmodule
