module mux
(
    input [3:0] sel,
    input [31:0] in,
    output reg [7:0] out
);
    always@(sel or in)
        case(sel)
            4'b0001:out = in[7:0];
            4'b0010:out = in[15:8];
            4'b0100:out = in[23:16];
            4'b1000:out = in[31:24];
            default:out = 8'd0; 
        endcase
endmodule