module conv_acc_top
#(
    parameter KERNEL_SIZE = 3,
    parameter KERNEL_NUM = 2,
    parameter PE_COLS = 8,
    parameter CHANNELS = 4,
    parameter PAD = 1,
    parameter FETCH_KERNEL_NUM = 8,
    parameter IFM_SIZE = 56

)
(
    input clk,
    input rst_n,

    input conv_start,
    input relu_en,
    input wht_valid,
    input ifm_valid,
    input out_ready,
    input [7:0] ifm,
    input [7:0] wht,

    output [31:0] out,
    output out_valid,
    output conv_end,
    output wht_ready,
    output ifm_ready
);
    localparam AW = 14;
    localparam IFM_ROWS = KERNEL_SIZE + PE_COLS - 1; 
    localparam IFM_BASE_ADDR = 0;
    localparam WHT_BASE_ADDR = (IFM_SIZE * IFM_ROWS * CHANNELS) / 4;
    localparam OUT_BASE_ADDR = WHT_BASE_ADDR + KERNEL_SIZE * KERNEL_SIZE * CHANNELS * KERNEL_NUM * FETCH_KERNEL_NUM;

    reg [8 * IFM_ROWS - 1:0] ifm_bus;
    reg [8* KERNEL_SIZE * KERNEL_NUM - 1:0] wht_bus;
    wire [32 * PE_COLS * KERNEL_NUM - 1:0] out_bus;
    wire [32 * PE_COLS * KERNEL_NUM - 1:0] psum_bus;
    
    wire pe2sram_ready,pe2sram_valid;
    wire wht2sram_valid,ifm2sram_valid;
    wire wht2pe_valid,ifm2pe_valid;
    wire psum2pe_valid,psum2pe_ready;

    wire [31:0] wht2sram,ifm2sram;
    wire [7:0] wht2pe,ifm2pe;
    wire [31:0] psum2pe;
    wire [31:0] pe2sram;

    wire pe_wht_i_ready,pe_ifm_i_ready,pe_psum_i_ready,pe_out_ready;
    wire pe_wht_i_valid,pe_ifm_i_valid,pe_psum_i_valid,pe_out_valid;
    wire pe_mul_une,pe_add_une;
    wire pe_psum_acc_start;
    wire pe_reg_sft_en;
    wire pe_acc_rst;


    wire[AW - 1:0] wht_sram_rela_addr;
    wire[AW - 1:0] ifm_sram_rela_addr;
    wire[AW - 1:0] psum_sram_rela_addr;
    wire[AW - 1:0] out_sram_rela_addr;

    wire[31:0] dout;
    reg cs;
    reg we;
    reg [3:0] wem;
    reg [AW - 1:0] addr;
    reg [31:0] din;
    assign psum2pe_ready = 1'b1;
    mux mux_i(.sel(wem),.in(dout),.out(wht2pe));
    assign ifm2pe = wht2pe;
    assign psum2pe = dout;
    assign out = (relu_en & dout[31]) ? 32'd0: dout;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            cs <= 1'b0;
            addr <= 32'd0;
            we <= 1'b0;
            din <= 32'd0;
            wem <= 4'd0;
        end
        else if(wht_valid & wht_ready) begin
            cs <= 1'b1; 
            addr <= {2'b00, wht_sram_rela_addr >> 2} + WHT_BASE_ADDR;
            we <= 1'b1;
            din <= wht2sram;
            wem <= 4'hf;
        end
        else if(ifm_valid & ifm_ready) begin
            cs <= 1'b1; 
            addr <={2'b00, ifm_sram_rela_addr >> 2} + IFM_BASE_ADDR;
            we <= 1'b1;
            din <= ifm2sram;
            wem <= 4'hf;
        end
        else if(wht2pe_valid) begin
            cs <= 1'b1; 
            addr <= {2'b00, wht_sram_rela_addr >> 2} + WHT_BASE_ADDR;
            we <= 1'b0;
            wem <= wht_sram_rela_addr[1:0];
        end
        else if(ifm2pe_valid) begin
            cs <= 1'b1; 
            addr <= {2'b00, ifm_sram_rela_addr >> 2} + IFM_BASE_ADDR;
            we <= 1'b0;
            wem <= ifm_sram_rela_addr[1:0];
        end 
        else if(pe2sram_valid & pe2sram_ready) begin
            cs <= 1'b1; 
            addr <= psum_sram_rela_addr + OUT_BASE_ADDR;
            we <= 1'b1;
            din <= pe2sram;
            wem <= 4'hf;
        end
        else if(psum2pe_valid&&psum2pe_ready) begin
            cs <= 1'b1; 
            addr <= psum_sram_rela_addr + OUT_BASE_ADDR;
            we <= 1'b0;
            wem <= 4'hf;
        end
        else if(out_valid) begin
            cs <= 1'b1; 
            addr <= out_sram_rela_addr + OUT_BASE_ADDR;
            we <= 1'b0;
            wem <= 4'hf;
        end
        else begin
            cs <= 1'b0;
            addr <= addr;
            wem <= wem;
            we <= we; 
        end
    end


    

    ctrl
    #(
        .KERNEL_SIZE(KERNEL_SIZE),
        .CHANNELS(CHANNELS),
        .PAD(PAD),
        .KERNEL_NUM(KERNEL_NUM),
        .PE_COLS(PE_COLS),
        .FETCH_KERNEL_NUM(FETCH_KERNEL_NUM),
        .IFM_SIZE(IFM_SIZE),
        .AW(AW)
    )
    ctrl_i(
        .clk(clk),
        .rst_n(rst_n),

        .conv_start(conv_start),
        .ifm_valid(ifm_valid),
        .wht_valid(wht_valid),

        .wht2sram_valid(wht2sram_valid),
        .ifm2sram_valid(ifm2sram_valid),
        .pe_wht_i_valid(pe_wht_i_valid),
        .pe_ifm_i_valid(pe_ifm_i_valid),
        .pe_psum_i_valid(pe_psum_i_valid),
        .pe2sram_ready(pe2sram_ready),
        
        .out_ready(out_ready),

        .out_valid(out_valid),
        .conv_end(conv_end),
        .ifm_ready(ifm_ready),
        .wht_ready(wht_ready),

        .wht2pe_valid(wht2pe_valid),
        .ifm2pe_valid(ifm2pe_valid),
        .psum2pe_valid(psum2pe_valid),
        .psum2pe_ready(psum2pe_ready),
        .pe_out_valid(pe_out_valid),
        .pe_wht_i_ready(pe_wht_i_ready),
        .pe_ifm_i_ready(pe_ifm_i_ready),
        .pe_psum_i_ready(pe_psum_i_ready),
        .pe_mul_une(pe_mul_une),
        .pe_add_une(pe_add_une),
        .pe_acc_rst(pe_acc_rst),
        .pe_reg_sft_en(pe_reg_sft_en),
        .pe_psum_acc_start(pe_psum_acc_start),

        .wht_sram_rela_addr(wht_sram_rela_addr),
        .ifm_sram_rela_addr(ifm_sram_rela_addr),
        .psum_sram_rela_addr(psum_sram_rela_addr),
        .out_sram_rela_addr(out_sram_rela_addr)
    );

    genvar i;
    generate 
        for(i = 0; i < KERNEL_NUM; i = i + 1) begin:pe_array_i
            pe_array 
            #(  .CHANNELS(CHANNELS),
                .KERNEL_SIZE(KERNEL_SIZE),
                .PE_COLS(PE_COLS),
                .IFM_ROWS (IFM_ROWS))
            pe_array_i(  
                .clk(clk),
                .rst_n(rst_n),

                .psum_acc_start(pe_psum_acc_start),
                .reg_sft_en(pe_reg_sft_en),
                .acc_rst(pe_acc_rst),
                .mul_une(pe_mul_une),
                .add_une(pe_add_une),
                .out_valid(pe_out_valid),
                .wht_i_valid(pe_wht_i_valid),
                .if_i_valid(pe_ifm_i_valid),
                .wht_i_ready(pe_wht_i_ready),
                .if_i_ready(pe_ifm_i_ready),
                .psum_i_valid(pe_psum_i_valid),
                .psum_i_ready(pe_psum_i_ready),


                .ifm(ifm_bus),
                .wht(wht_bus[8 * KERNEL_SIZE * (i + 1) - 1: 8 * KERNEL_SIZE * i]),
                .out(out_bus[32 * PE_COLS * (i + 1) - 1:32 * PE_COLS * i]),
                .psum(psum_bus[32 * PE_COLS * (i + 1) - 1:32 * PE_COLS * i]),
                .out_ready(pe_out_ready)
                );
        end
    endgenerate 

    seri2para
    #(
        .IN_NUM(4),
        .IN_WIDTH(8)
    )
    seri2para_ifm2sram(
        .clk(clk),
        .rst_n(rst_n),

        .in_valid(ifm_valid),
        .out_ready(1'b1),
        .in(ifm),
        .in_ready(ifm_ready),
        .out(ifm2sram),
        .out_valid(ifm2sram_valid)
    );

    seri2para
    #(
        .IN_NUM(4),
        .IN_WIDTH(8)
    )
    seri2para_wht2sram(
        .clk(clk),
        .rst_n(rst_n),

        .in_valid(wht_valid),
        .out_ready(1'b1),
        .in(wht),
        .in_ready(wht_ready),
        .out(wht2sram),
        .out_valid(wht2sram_valid)
    );

    para2seri
    #(
        .IN_NUM(PE_COLS * KERNEL_NUM),
        .IN_WIDTH(32),
        .OUT_WIDTH(32)
    )
    para2seri_pe2sram(
        .clk(clk),
        .rst_n(rst_n),

        .in_valid(pe_out_valid),
        .out_ready(pe2sram_ready),
        .in(out_bus),
        .in_ready(pe_out_ready),
        .out(pe2sram),
        .out_valid(pe2sram_valid)
    );

    seri2para
    #(
        .IN_WIDTH(8),
        .IN_NUM(KERNEL_SIZE * KERNEL_NUM)
    )
    seri2para_wht2pe
    (
        .clk(clk),
        .rst_n(rst_n),

        .in_ready(),
        .in_valid(wht2pe_valid),
        .in(wht2pe),
        .out(wht_bus),
        .out_valid(pe_wht_i_valid),
        .out_ready(pe_wht_i_ready)
    );

    seri2para
    #(
        .IN_WIDTH(8),
        .IN_NUM(IFM_ROWS)
    )
    seri2para_ifm2pe
    (
        .clk(clk),
        .rst_n(rst_n),

        .in_ready(),
        .in_valid(ifm2pe_valid),
        .in(ifm2pe),
        .out(ifm_bus),
        .out_valid(pe_ifm_i_valid),
        .out_ready(pe_ifm_i_ready)
    );

    seri2para
    #(
        .IN_WIDTH(32),
        .IN_NUM(PE_COLS * KERNEL_NUM)
    )
    seri2para_psum2pe
    (
        .clk(clk),
        .rst_n(rst_n),

        .in_ready(),
        .in_valid(psum2pe_valid),
        .in(psum2pe),
        .out(psum_bus),
        .out_valid(pe_psum_i_valid),
        .out_ready(pe_psum_i_ready)
    );

    sram_top ram_i
    (
        .clk(clk),
        .rst(rst_n),
        .cs(cs),
        .we(we),
        .wem(wem),
        .din(din),
        .addr(addr),
        .dout(dout)
    ) ;

endmodule