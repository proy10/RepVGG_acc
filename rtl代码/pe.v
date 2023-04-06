module pe
#(parameter CHANNELS = 4,
  parameter KERNEL_SIZE = 3)
(
    input clk,
    input rst_n,

    //ctrl signal
    input psum_acc_start,
    input reg_sft_en,
    input psum_sel,
    input acc_rst,
    input mul_une,
    input add_une,
    input if_i_en,
    input wht_i_en,
    input psum_i_en,

    //data
    input [7:0] wht,
    input [7:0] in,
    input [31:0] psum,
    output reg[31:0] out
);
    localparam RFW = CHANNELS * KERNEL_SIZE;// Width of Register Files
    reg [15:0] product;
    reg [7:0] if_reg[RFW - 1:0];
    reg [7:0] wht_reg[RFW - 1:0];

    wire[31:0] b;
    wire[31:0] a;

    reg p_start_r;
   /******************************************
    *Register file
    *******************************************/
    genvar i;
    generate 
        for(i = 1; i < RFW; i = i + 1) begin:ifmap_rf
            always@(posedge clk or negedge rst_n) begin
                if(!rst_n)        
                    if_reg[i] <= 8'd0;
                else if(if_i_en | reg_sft_en)   
                    if_reg[i] <= if_reg[i - 1];
                else              
                    if_reg[i] <= if_reg[i];
            end
        end
    endgenerate
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n) 
            if_reg[0] <= 8'd0;
        else if(if_i_en)
            if_reg[0] <= in;
        else if(reg_sft_en)
            if_reg[0] <= if_reg[RFW - 1]; 
        else 
            if_reg[0] <= if_reg[0];       
    end

    generate 
        for(i = 1; i < RFW; i = i + 1) begin:wht_rf
            always@(posedge clk or negedge rst_n) begin
                if(!rst_n)        
                    wht_reg[i] <= 8'd0;
                else if(reg_sft_en | wht_i_en) 
                    wht_reg[i] <= wht_reg[i - 1];
                else              
                    wht_reg[i] <= wht_reg[i];
            end
        end
    endgenerate
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)        
            wht_reg[0] <= 8'd0;
        else if(wht_i_en) 
            wht_reg[0] <= wht;
        else if(reg_sft_en) 
            wht_reg[0] <= wht_reg[RFW - 1];
        else              
            wht_reg[0] <= wht_reg[0];
    end


    /******************************************
    Multiply and accumulation
    *******************************************/
    //Multiply
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            product <= 16'd0;
        else if(mul_une)
            product <= 16'd0;
        else 
            product <= if_reg[RFW - 1] * wht_reg[RFW - 1]; 
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            p_start_r <= 1'b0;
        else 
            p_start_r <= psum_acc_start;
    end

    assign b = psum_sel ? psum  : {{16{product[15]}},product};

   // assign a = acc_rst ? 32'd0 :
     //          p_start_r ? a : out;
    //Adder
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n )
            out <= 32'd0;
        else if(add_une)
            out <= out;
        else if(acc_rst)
            out <= 32'd0;
        else
            out <= b + out; 
    end
endmodule