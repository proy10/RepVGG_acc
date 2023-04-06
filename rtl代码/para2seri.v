module para2seri
#(  
    parameter IN_NUM = 8,
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 32
)
(
    input clk,
    input rst_n,

    input in_valid,
    input out_ready,
    input [IN_WIDTH * IN_NUM - 1:0] in,
    
    output in_ready,
    output out_valid,
    output [OUT_WIDTH - 1:0] out
);

    reg [OUT_WIDTH - 1 : 0] out_r [IN_NUM - 1:0];
    reg [IN_NUM - 1:0] in_valid_r;
    genvar i;
    assign in_ready = 1'b1;

    assign out_valid = | in_valid_r;
    assign out = out_r[0];

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n) 
            in_valid_r <= {IN_NUM{1'b0}};
        else if(!out_ready)  
            in_valid_r <= in_valid_r;
        else     
            in_valid_r <= {in_valid_r[IN_NUM - 2:0], in_valid};
    end
    
    
    generate 
        for(i = 0; i < IN_NUM - 1; i = i + 1) begin:out_r_i
            always @(posedge clk or negedge rst_n)begin
                if(!rst_n) 
                    out_r[i] <= {OUT_WIDTH{1'b0}};
                else if(out_valid & out_ready)
                    out_r[i] <= out_r[i + 1];
                else if(in_valid & in_ready)
                    out_r[i] <= in[OUT_WIDTH * ( i + 1) - 1:OUT_WIDTH * i];
                else
                    out_r[i] <= out_r[i];
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n) 
            out_r[IN_NUM - 1] <= {OUT_WIDTH{1'b0}};
        else if(out_valid & out_ready)
            out_r[IN_NUM - 1] <= out_r[0];
        else if(in_valid & in_ready)
            out_r[IN_NUM - 1] <= in[OUT_WIDTH * IN_NUM - 1:OUT_WIDTH * (IN_NUM - 1)];
        else
            out_r[IN_NUM - 1] <= out_r[IN_NUM - 1];
    end

endmodule