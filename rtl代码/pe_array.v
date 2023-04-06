module pe_array
#(parameter CHANNELS = 4,
  parameter KERNEL_SIZE = 3,
  parameter PE_COLS = 8,
  parameter IFM_ROWS = 10)
(
    input clk,
    input rst_n,
    
    input psum_acc_start,
    input reg_sft_en,
    input mul_une,
    input add_une,
    input acc_rst,
    input out_ready,
    input wht_i_valid,
    input if_i_valid,
    input wht_i_ready,
    input if_i_ready,
    input psum_i_valid,
    input psum_i_ready,
    
    input[8 * IFM_ROWS -1:0] ifm,
    input[8 * KERNEL_SIZE - 1:0] wht,
    input[32 * PE_COLS -1:0] psum,
    output[32 * PE_COLS -1:0] out,
    output out_valid
);
    wire if_i_en,wht_i_en,psum_i_en;
    //wire if_i_en,wht_i_en;

    wire [31:0] pe_o[(KERNEL_SIZE + 1) * PE_COLS - 1: 0];
    reg [KERNEL_SIZE - 1 : 0]psum_sel;

    //assign out_valid = out_ready;

    assign if_i_en = if_i_valid & if_i_ready;
    assign wht_i_en = wht_i_valid & wht_i_ready;
    assign psum_i_en = psum_i_valid & psum_i_ready;
    genvar i,j;

    generate 
        for(i = 0; i < PE_COLS; i = i + 1) begin : assign_out
            assign out[(i + 1) * 32 - 1 : i * 32] = pe_o[ i * (KERNEL_SIZE + 1)];
        end
    endgenerate

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            psum_sel <= {KERNEL_SIZE{1'b0}};
        else 
            psum_sel <= {psum_i_en, psum_sel[KERNEL_SIZE - 1:1]}; 
    end

    generate 
        for(i = 1; i <= PE_COLS; i = i + 1)begin:pe_o_i
            assign pe_o[i * (KERNEL_SIZE + 1) - 1] = psum[i * 32 - 1:( i - 1) * 32];
        end
    endgenerate


    generate //i = 1表示第0行
        for(i = 0; i < PE_COLS; i = i + 1)begin:pe_cols_inst_i
           
            for(j = 0; j < KERNEL_SIZE; j = j + 1) begin:pe_cols_inst_j
                pe
                    #(  .CHANNELS(CHANNELS),
                        .KERNEL_SIZE(KERNEL_SIZE))
                pe_i(   
                    .clk(clk),
                    .rst_n(rst_n),

                    .psum_acc_start(psum_acc_start),
                    .reg_sft_en(reg_sft_en),
                    .psum_sel(psum_sel[j]),
                    .acc_rst(acc_rst),
                    .mul_une(mul_une),
                    .add_une(add_une),
                    .if_i_en(if_i_en),
                    .wht_i_en(wht_i_en),
                        
                    .in(ifm[(j + i + 1) * 8 - 1 : (j + i) * 8]),
                    .wht(wht[(j + 1) * 8 - 1: j * 8]),
                    .psum(pe_o[i * (KERNEL_SIZE + 1 ) + j + 1]),
                    .out(pe_o[i * (KERNEL_SIZE + 1) + j])  
                    );
                end
        end
    endgenerate

endmodule

