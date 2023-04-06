module ctrl
#(
    parameter KERNEL_SIZE = 3,
    parameter CHANNELS = 4,
    parameter PAD = 1,
    parameter KERNEL_NUM = 2,
    parameter PE_COLS = 8,
    parameter FETCH_KERNEL_NUM = 8,
    parameter IFM_SIZE = 56,
    parameter AW = 14
)
(
    input clk,
    input rst_n,

    input conv_start,
    input wht_valid,
    input ifm_valid,

    input wht2sram_valid,
    input ifm2sram_valid,
    input pe_wht_i_valid,
    input pe_ifm_i_valid,
    input pe_psum_i_valid,
    input psum2pe_ready,
    input pe2sram_valid,

    input out_ready,

    output out_valid,
    output conv_end,
    output wht_ready,
    output ifm_ready,
    

    output wht2pe_valid,
    output ifm2pe_valid,
    output psum2pe_valid,
    output pe2sram_ready,
    output pe_out_valid,
    output pe_wht_i_ready, 
    output pe_ifm_i_ready,
    output pe_psum_i_ready,
    output pe_mul_une, 
    output pe_add_une, 
    output pe_acc_rst,
    output pe_reg_sft_en,
    output pe_psum_acc_start,

    output [AW - 1:0] wht_sram_rela_addr,
    output [AW - 1:0] ifm_sram_rela_addr,
    output [AW - 1:0] psum_sram_rela_addr,
    output [AW - 1:0] out_sram_rela_addr
); 
    localparam IFM_ROWS = KERNEL_SIZE + PE_COLS - 1;
    localparam IFM_BATCH_NUM = (IFM_SIZE + 2 * PAD) * IFM_ROWS * CHANNELS / 4;
    localparam WHT_BATCH_NUM = KERNEL_SIZE * KERNEL_SIZE * KERNEL_NUM * CHANNELS / 4;
    localparam IFM_2_PE_NUM = IFM_SIZE + 2 * PAD;
    localparam WHT_2_PE_NUM = CHANNELS * KERNEL_SIZE;
    localparam OUT_SRAM_NUM = (IFM_SIZE + 2 * PAD + 1 - KERNEL_SIZE) * PE_COLS *  KERNEL_NUM * FETCH_KERNEL_NUM;
    localparam MAC_CYCLES = (CHANNELS + 1) * KERNEL_SIZE;
    localparam PE_2_SRAM_NUM = PE_COLS * KERNEL_NUM;


    localparam IDLE = 4'd0;
    localparam IFM_IN_SRAM = 4'd1;
    localparam WHT_IN_SRAM = 4'd2;
    localparam IFM_1ST_2_PE = 4'd3;
    localparam WHT_2_PE = 4'd4;
    localparam PE_MAC = 4'd5;
    localparam PSUM_2_PE = 4'd6;
    localparam PE_PSUM_ACC = 4'd7;
    localparam PE_2_SRAM = 4'd8;
    localparam IFM_2_PE = 4'd9;
    localparam SRAM_OUT = 4'd10;

    reg[3:0] cstate,nstate;
    //counter
    reg [15:0] sram_in_cnt;
    wire       sram_in_ce;
    reg [4:0] pe_wht_cnt;
    wire      pe_wht_ce;
    reg [4:0] acc_cnt;
    wire      acc_ce;
    reg [2:0] psum_acc_cnt;
    wire      psum_acc_ce;
    reg [4:0] pe_2_sram_cnt;
    wire      pe_2_sram_ce;
    reg [4:0] chl_grp_cnt;
    wire      chl_grp_ce;
    reg [7:0] pe_ifm_cnt;
    wire      pe_ifm_ce;
    reg [4:0] psum_2_pe_cnt;
    wire      psum_2_pe_ce;
    reg [3:0] kernel_fetch_cnt;
    wire      kernel_fetch_ce;
    reg       kernel_fetch_ce_r;
    reg [15:0] out_sram_cnt;
    wire       out_sram_ce;
    reg [5:0] pro_cnt;
    wire      pro_ce;
    reg       pro_ce_r;

    reg [AW - 1:0] wht_sram_rela_addr_r;
    assign wht_sram_rela_addr = wht2pe_valid ? pe_wht_cnt + wht_sram_rela_addr_r : {AW{1'b0}};
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            wht_sram_rela_addr_r <= {AW{1'b0}};
        else if(wht_valid & wht_ready)
            wht_sram_rela_addr_r <= wht_sram_rela_addr_r + 1'b1;
        else if(nstate == IFM_1ST_2_PE)
            wht_sram_rela_addr_r <= {AW{1'b0}};
        else if(wht2pe_valid)
            wht_sram_rela_addr_r <= wht_sram_rela_addr_r + WHT_2_PE_NUM;
        else
            wht_sram_rela_addr_r <= wht_sram_rela_addr_r;
    end

    reg [AW - 1:0] ifm_sram_rela_addr_r;
    assign ifm_sram_rela_addr = ifm2pe_valid ? pe_ifm_cnt + ifm_sram_rela_addr_r : {AW{1'b0}};
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            ifm_sram_rela_addr_r <= {AW{1'b0}};
        else if(ifm_valid & ifm_ready)
            ifm_sram_rela_addr_r <= ifm_sram_rela_addr_r + 1'b1;
        else if(nstate == WHT_2_PE)
            ifm_sram_rela_addr_r <= {AW{1'b0}};
        else if(ifm2pe_valid)
            ifm_sram_rela_addr_r <= ifm_sram_rela_addr_r + IFM_2_PE_NUM * CHANNELS;
        else
            ifm_sram_rela_addr_r <= ifm_sram_rela_addr_r;
    end

    reg [AW - 1:0] psum_sram_rela_addr_r;
    assign psum_sram_rela_addr = psum_sram_rela_addr_r;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            psum_sram_rela_addr_r <= {AW{1'b0}};
        else if(pe2sram_valid & pe2sram_ready)
            psum_sram_rela_addr_r <= psum_sram_rela_addr_r + 1'b1;
        else if(nstate == PE_PSUM_ACC)
            psum_sram_rela_addr_r <= {AW{1'b0}};
        else if(psum2pe_valid & psum2pe_ready)
            psum_sram_rela_addr_r <= psum_sram_rela_addr_r + 1'b1;
        else    
            psum_sram_rela_addr_r <= psum_sram_rela_addr_r;
    end

    reg [AW - 1:0] out_sram_rela_addr_r;
    assign out_sram_rela_addr = out_sram_rela_addr_r;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            out_sram_rela_addr_r <= 32'd0;
        else if(out_valid)
            out_sram_rela_addr_r <= out_sram_rela_addr_r + 1'b1;
        else if(nstate == IFM_1ST_2_PE)
            out_sram_rela_addr_r <= 32'd0;
        else    
            out_sram_rela_addr_r <= out_sram_rela_addr_r;
    end

    assign sram_in_ce = ifm2sram_valid | wht2sram_valid; 
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            sram_in_cnt <= 16'd0;
        else if(sram_in_cnt == IFM_BATCH_NUM + WHT_BATCH_NUM & wht2sram_valid)
            sram_in_cnt <= 16'd0;
        else if(sram_in_ce)
            sram_in_cnt <= sram_in_cnt + 1'b1;
        else 
            sram_in_cnt <= sram_in_cnt;
    end

    assign pe_wht_ce = pe_wht_i_valid;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            pe_wht_cnt <= 5'd0;
        else if(pe_wht_cnt == WHT_2_PE_NUM & pe_wht_i_valid)
            pe_wht_cnt <= 5'd0;
        else if (pe_wht_ce)
            pe_wht_cnt <= pe_wht_cnt + 1'b1;
        else 
            pe_wht_cnt <= pe_wht_cnt;
    end

    assign pe_ifm_ce = pe_ifm_i_valid;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            pe_ifm_cnt <= 8'd0;
        else if(pe_ifm_cnt == IFM_2_PE_NUM & pe_ifm_i_valid)
            pe_ifm_cnt <= 8'd0;
        else if (pe_ifm_ce)
            pe_ifm_cnt <= pe_ifm_cnt + 1'b1;
        else 
            pe_ifm_cnt <= pe_ifm_cnt;
    end

    assign acc_ce = pe_psum_acc_start | pe_reg_sft_en;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            acc_cnt <= 5'd0;
        else if(acc_cnt ==  MAC_CYCLES + KERNEL_SIZE & pe_psum_acc_start)
            acc_cnt <= 5'd0;
        else if (acc_ce)
            acc_cnt <= acc_cnt + 1'b1;
        else 
            acc_cnt <= acc_cnt;
    end

    assign psum_2_pe_ce = psum2pe_valid & psum2pe_ready;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            psum_2_pe_cnt <= 5'd0;
        else if(psum_2_pe_cnt ==  PE_2_SRAM_NUM & psum_2_pe_ce)
            psum_2_pe_cnt <= 5'd0;
        else if (psum_2_pe_ce)
            psum_2_pe_cnt <= psum_2_pe_cnt + 1'b1;
        else 
            psum_2_pe_cnt <= psum_2_pe_cnt;
    end

    assign pe_2_sram_ce = pe2sram_valid;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            pe_2_sram_cnt <= 5'd0;
        else if(pe_2_sram_cnt ==  PE_2_SRAM_NUM & pe2sram_valid)
            pe_2_sram_cnt <= 5'd0;
        else if (pe_2_sram_ce)
            pe_2_sram_cnt <= pe_2_sram_cnt + 1'b1;
        else 
            pe_2_sram_cnt <= pe_2_sram_cnt;
    end

    assign kernel_fetch_ce = (~ kernel_fetch_ce_r) & nstate == WHT_IN_SRAM;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            kernel_fetch_cnt <= 4'd0;
        else if(kernel_fetch_cnt ==  FETCH_KERNEL_NUM)
            kernel_fetch_cnt <= 4'd0;
        else if (kernel_fetch_ce)
            kernel_fetch_cnt <= kernel_fetch_cnt + 1'b1;
        else 
            kernel_fetch_cnt <= kernel_fetch_cnt;
    end 

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            kernel_fetch_ce_r <= 1'b0;
        else
            kernel_fetch_ce_r <= nstate == WHT_IN_SRAM;
    end

    assign out_sram_ce = out_valid;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            out_sram_cnt <= 16'd0;
        else if(out_sram_cnt == OUT_SRAM_NUM & out_valid)
            out_sram_cnt <= 16'd0;
        else if (out_sram_ce)
            out_sram_cnt <= out_sram_cnt + 1'b1;
        else 
            out_sram_cnt <= out_sram_cnt;
    end 

    assign pro_ce = (~ pro_ce_r) & nstate == SRAM_OUT;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            pro_cnt <= 6'd0;
        else if(pro_cnt ==  64 /CHANNELS)
            pro_cnt <= 6'd0;
        else if (pro_ce)
            pro_cnt <= pro_cnt + 1'b1;
        else 
            pro_cnt <= pro_cnt;
    end 

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            pro_ce_r <= 1'b0;
        else
            pro_ce_r <= nstate == WHT_IN_SRAM;
    end


    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cstate <= IDLE;
        else 
            cstate <= nstate;
    end

    always @(*)begin
        nstate = cstate;
        case(cstate)
            IDLE:
                if(conv_start)
                    nstate = IFM_IN_SRAM;
                else 
                    nstate = IDLE;
            IFM_IN_SRAM:
                if(sram_in_cnt == IFM_BATCH_NUM)
                    nstate = WHT_IN_SRAM;
                else
                    nstate = IFM_IN_SRAM; 
            WHT_IN_SRAM:
                if(sram_in_cnt == IFM_BATCH_NUM + WHT_BATCH_NUM)
                    nstate = IFM_1ST_2_PE;
                else
                    nstate = WHT_IN_SRAM; 
            IFM_1ST_2_PE:
                if(pe_ifm_cnt == WHT_2_PE_NUM)
                    nstate = WHT_2_PE;
                else 
                    nstate = IFM_1ST_2_PE;
            WHT_2_PE:
                if(pe_wht_cnt == WHT_2_PE_NUM)
                    nstate = PE_MAC;
                else 
                    nstate = WHT_2_PE;
            PE_MAC:
                if(acc_cnt == WHT_2_PE_NUM)
                    nstate = PE_PSUM_ACC;
                else 
                    nstate = PE_MAC;
            PSUM_2_PE:
                if(psum_2_pe_cnt == PE_2_SRAM_NUM)
                    nstate = PE_PSUM_ACC;
                else
                    nstate = PSUM_2_PE;
            PE_PSUM_ACC:
                if(psum_acc_cnt == KERNEL_SIZE)
                    nstate = PE_2_SRAM;
                else
                    nstate = PE_PSUM_ACC;
            PE_2_SRAM : 
                if(pe_2_sram_cnt == PE_2_SRAM_NUM) begin
                    if(chl_grp_cnt == 64 / CHANNELS)
                        nstate = SRAM_OUT;
                    else if (pe_ifm_cnt == IFM_2_PE_NUM)
                        nstate = WHT_2_PE;
                    else if(kernel_fetch_cnt == FETCH_KERNEL_NUM)
                        nstate = IFM_1ST_2_PE;
                    else
                        nstate = IFM_2_PE;
                end
                else
                    nstate = PE_2_SRAM;
            IFM_2_PE :
                if(pe_ifm_i_valid)
                    nstate = PE_MAC;
                else 
                    nstate = IFM_2_PE;
            SRAM_OUT:
                if(pro_cnt == 28)
                    nstate = IDLE;
                else
                    nstate = IFM_IN_SRAM;
            default:
                nstate = IDLE;
        endcase
    end

    assign ifm_ready = nstate == IFM_IN_SRAM;
    assign wht_ready = nstate == WHT_IN_SRAM;
    assign out_valid = out_ready & nstate == SRAM_OUT;
    assign pe_out_valid = nstate == PE_2_SRAM;
    assign wht2pe_valid = nstate == WHT_2_PE;
    assign ifm2pe_valid = (nstate == IFM_1ST_2_PE) | (nstate == IFM_2_PE);
    assign pe_wht_i_ready = nstate == WHT_2_PE;
    assign psum2pe_valid = pe_psum_i_ready;
    assign pe_ifm_i_ready = (nstate == IFM_1ST_2_PE) | (nstate == IFM_2_PE);
    assign pe_psum_i_ready = nstate == PE_PSUM_ACC; 
    assign pe2sram_ready = nstate == PE_2_SRAM;
    assign pe_reg_sft_en = nstate == PE_MAC;
    assign pe_psum_acc_start = nstate == PE_PSUM_ACC;
    assign pe_mul_une = (nstate == PE_PSUM_ACC) | pe_ifm_i_valid;
    assign pe_mul_une = nstate == PSUM_2_PE ;
    assign pe_acc_rst = pe2sram_ready;
    
endmodule