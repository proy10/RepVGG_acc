module acc_top (
	input			clk,
	input			rst_n,

	input			i_icb_cmd_valid,
	output			i_icb_cmd_ready,
	input [32-1:0]		i_icb_cmd_addr,
	input			i_icb_cmd_read,
	input [32-1:0]		i_icb_cmd_wdata,
	input [32/8-1:0]	i_icb_cmd_wmask,

	output reg		i_icb_rsp_valid,
	input			i_icb_rsp_ready,
	output 			i_icb_rsp_err,
	output reg [32-1:0]	i_icb_rsp_rdata
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
	reg [32-1:0] ctrl;
	wire [32-1:0] status;
	reg [32-1:0] icb_ifm_wdata;
	reg [32-1:0] icb_wht_wdata;
	reg icb_ifm_we, icb_wht_we, icb_ifm_cs, icb_wht_cs;
	reg [32-1:0] i_icb_cmd_addr_reg;
	reg [32/8-1:0] i_icb_cmd_wmask_reg;
	wire [32-1:0] res_rdata;
	reg [32-1:0] rdata;
	reg icb_res_ren;
	wire [32-1:0] ctrl_wire;
	wire [32-1:0] conv_ifm_addr, conv_wht_addr, conv_res_addr;
	wire conv_ifm_cs, conv_wht_cs, conv_res_cs, conv_ifm_we, conv_wht_we, conv_res_we;
	wire [32/8-1:0] conv_ifm_wem, conv_wht_wem, conv_res_wem;
	wire [32-1:0] ifm_conv_rdata, wht_conv_rdata, conv_res_wdata;
	wire [32-1:0] ifm_ram_din_wire, ifm_ram_dout_wire, ifm_ram_addr_wire;
	wire ifm_ram_we_wire, ifm_ram_cs_wire;
	wire [32/8-1:0] ifm_ram_wem_wire;
	wire ifm_ram_sel;
	wire [32-1:0] wht_ram_din_wire, wht_ram_dout_wire, wht_ram_addr_wire;
	wire wht_ram_we_wire, wht_ram_cs_wire;
	wire [32/8-1:0] wht_ram_wem_wire;
	wire wht_ram_sel;
	wire [32-1:0] res_ram_din_wire, res_ram_dout_wire, res_ram_addr_wire;
	wire res_ram_we_wire, res_ram_cs_wire;
	wire [32/8-1:0] res_ram_wem_wire;
	wire res_ram_sel;

	assign check_addr = (i_icb_cmd_addr[31:20] == BASE_ADDR[31:20]);
	assign i_icb_cmd_ready = i_icb_rsp_ready & check_addr;

	always@(posedge clk) begin
		i_icb_cmd_addr_reg <= i_icb_cmd_addr;
		i_icb_cmd_wmask_reg <= i_icb_cmd_wmask;
	end

	//write

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			ctrl <= 32'h0;
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
					icb_ifm_wdata <= i_icb_cmd_wdata;
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
	assign i_icb_rsp_err = 1'b0;
	//assign i_icb_rsp_valid = i_icb_cmd_valid & check_addr & i_icb_cmd_read;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			i_icb_rsp_valid <= 1'b0;
		else
			i_icb_rsp_valid <= i_icb_cmd_valid & check_addr & i_icb_cmd_read;
	end

	assign res_rdata = res_ram_dout_wire;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			icb_res_ren <= 1'b0;
			rdata <= 32'h0;
		end
		else if(i_icb_cmd_valid & i_icb_cmd_ready & i_icb_cmd_read) begin
			icb_res_ren <= 1'b0;
			if(i_icb_cmd_addr == CTRL_ADDR)
				rdata <= ctrl;
			else if(i_icb_cmd_addr == STATUS_ADDR)
				rdata <= status;
			else if(i_icb_cmd_addr >= RESULT_SRAM_ADDR) begin
				rdata <= res_rdata;
				icb_res_ren <= 1'b1;
			end
		end
	end

	always@(*) begin
		if(i_icb_rsp_valid & i_icb_rsp_ready)
			i_icb_rsp_rdata = rdata;
		else
			i_icb_rsp_rdata = 32'h0;
	end

//ctrl init
	assign ctrl_wire = ctrl;

	controller u_ctrl(
		.clk(clk),
		.rst_n(rst_n),
		.ctrl(ctrl_wire),
		.status(status)
	);

//conv core
	
	assign ifm_conv_rdata = ifm_ram_dout_wire;
	assign wht_conv_rdata = wht_ram_dout_wire;

	conv_core u_core(
		.clk(clk),
		.rst_n(rst_n),
		.state(status),
		.ifm_addr(conv_ifm_addr),
		.ifm_cs(conv_ifm_cs),
		.ifm_we(conv_ifm_we),
		.ifm_wem(conv_ifm_wem),
		.ifm_i(ifm_conv_rdata),
		.wht_addr(conv_wht_addr),
		.wht_cs(conv_wht_cs),
		.wht_we(conv_wht_we),
		.wht_wem(conv_wht_wem),
		.wht_i(wht_conv_rdata),
		.res_addr(conv_res_addr),
		.res_cs(conv_res_cs),
		.res_we(conv_res_we),
		.res_wem(conv_res_wem),
		.res_o(conv_res_wdata)
	);

//input feature map ram init
	
	assign ifm_ram_sel = ~icb_ifm_we & conv_ifm_we;
	assign ifm_ram_din_wire = icb_ifm_wdata;
	assign ifm_ram_addr_wire = (ifm_ram_sel) ? conv_ifm_addr : i_icb_cmd_addr_reg;
	assign ifm_ram_cs_wire = (ifm_ram_sel) ? conv_ifm_cs : icb_ifm_cs;
	assign ifm_ram_we_wire = (ifm_ram_sel) ? conv_ifm_we : icb_ifm_we;
	assign ifm_ram_wem_wire = (ifm_ram_sel) ? conv_ifm_wem : i_icb_cmd_wmask_reg;

	/*sirv_sim_ram #(
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
	);*/

	sram_top #(
		.DW(32),
		.MW(4),
		.AW(32)
	) u_ifm_ram(
		.clk(clk),
		.rst(rst_n),
		.din(ifm_ram_din_wire),
		.addr(ifm_ram_addr_wire),
		.cs(ifm_ram_cs_wire),
		.we(ifm_ram_we_wire),
		.wem(ifm_ram_wem_wire),
		.dout(ifm_ram_dout_wire)
	);

//weight ram init
	
	assign wht_ram_sel = ~icb_wht_we & conv_wht_we;
	assign wht_ram_din_wire = icb_wht_wdata;
	assign wht_ram_addr_wire = (wht_ram_sel) ? conv_wht_addr : i_icb_cmd_addr_reg;
	assign wht_ram_cs_wire = (wht_ram_sel) ? conv_wht_cs : icb_wht_cs;
	assign wht_ram_we_wire = (wht_ram_sel) ? conv_wht_we : icb_wht_we;
	assign wht_ram_wem_wire = (wht_ram_sel) ? conv_wht_wem : i_icb_cmd_wmask_reg;

	/*sirv_sim_ram #(
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
	);*/

	sram_top #(
		.DW(32),
		.MW(4),
		.AW(32)
	) u_wht_ram(
		.clk(clk),
		.rst(rst_n),
		.din(wht_ram_din_wire),
		.addr(wht_ram_addr_wire),
		.cs(wht_ram_cs_wire),
		.we(wht_ram_we_wire),
		.wem(wht_ram_wem_wire),
		.dout(wht_ram_dout_wire)
	);

//result ram init

	assign res_ram_sel = ~icb_res_ren & conv_res_we;
	assign res_ram_din_wire = conv_res_wdata;
	assign res_ram_addr_wire = (res_ram_sel) ? conv_res_addr : i_icb_cmd_addr_reg;
	assign res_ram_cs_wire = (res_ram_sel) ? conv_res_cs : icb_res_ren;
	assign res_ram_we_wire = (res_ram_sel) ? conv_res_we : ~icb_res_ren;
	assign res_ram_wem_wire = (res_ram_sel) ? conv_res_wem : 4'hf;

	/*sirv_sim_ram #(
		.DP(8192),
		.DW(32),
		.MW(32/8)
	) u_res_ram(
		.clk(clk),
		.din(res_ram_din_wire),
		.addr(conv_res_addr),
		.cs(res_ram_cs_wire),
		.we(res_ram_we_wire),
		.wem(res_ram_wem_wire),
		.dout(res_ram_dout_wire)
	);*/

	sram_top #(
		.DW(32),
		.MW(4),
		.AW(32)
	) u_res_ram(
		.clk(clk),
		.rst(rst_n),
		.din(res_ram_din_wire),
		.addr(conv_res_addr),
		.cs(res_ram_cs_wire),
		.we(res_ram_we_wire),
		.wem(res_ram_wem_wire),
		.dout(res_ram_dout_wire)
	);

endmodule
