module seri2para
#(
    parameter IN_NUM = 4,
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = IN_NUM * IN_WIDTH
)
(
    input clk,
    input rst_n,

    input in_valid,
    input out_ready,
    input [IN_WIDTH - 1 : 0] in,

    output in_ready,
    output out_valid,
    output [OUT_WIDTH - 1:0] out

);

    reg [OUT_WIDTH - 1 : 0] in_reg ;
    reg [8:0] cnt;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            cnt <= 4'd0;
        else if(cnt == IN_NUM & out_ready)
            cnt <= 4'd0;
        else if(in_valid)
            cnt <= cnt + 1'b1;
        else 
            cnt <= cnt;
    end

    
    assign out = in_reg;
    assign out_valid = cnt == IN_NUM & out_ready;
    
    assign in_ready = 1'b1;

    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            in_reg <= {OUT_WIDTH{1'b0}};  
        else if(in_valid & in_ready)
            in_reg <= {in_reg[OUT_WIDTH - IN_WIDTH - 1:0], in};
        else
            in_reg <= in_reg;
    end

endmodule