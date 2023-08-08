module csa #(
    parameter DW = 16
)(
    input [DW-1:0]      op1,
    input [DW-1:0]      op2,
    input [DW-1:0]      op3,

    output [DW-1:0]     sum,
    output [DW-1:0]     cout
);

    genvar i;
    generate
        for(i=0; i<DW; i=i+1) begin: add
            assign sum[i] = op1[i] ^ op2[i] ^ op3[i];
            assign cout[i] = (op1[i] & op2[i]) | (op3[i] & (op1[i] ^ op2[i]));
        end 
    endgenerate

endmodule

module cla #(
    parameter DW = 4
)(
    input [DW-1:0]      op1,
    input [DW-1:0]      op2,
    inout               cin,

    output [DW-1:0]     sum,
    output              cout
);

    wire [DW-1:0] G, P;

    genvar i;
    generate
        for(i=0; i<DW; i=i+1) begin: GP
            assign G[i] = op1[i] & op2[i];
            assign P[i] = op1[i] | op2[i];
        end
    endgenerate

    wire [DW-1:0] C;
    assign C[0] = cin;
    assign C[1] = G[0] | (P[0] & cin);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & cin);
    assign C[3] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & cin);
    assign cout = G[3] | (P[3] & G[2]) | (P[3] & P[2] & G[1]) | (P[3] & P[2] & P[1] & G[0]) | (P[3] & P[2] & P[1] & P[0] & cin);

    genvar j;
    generate
        for(j=0; j<DW; j=j+1) begin: sum
            assign sum[j] = op1[j] ^ op2[j] ^ C[j];
        end
    endgenerate

endmodule

module wallace_mul #(
    parameter DWI = 8,
    parameter DWO = 16
)(
    input [DWI-1:0]     op1,
    input [DWI-1:0]     op2,
    output [DWO-1:0]    out
);

    wire [DWI-1:0] intermediate [0:DWI-1];

    genvar i_mul;
    generate
        for(i_mul=0; i_mul<DWI; i_mul=i_mul+1) begin: mul
            assign intermediate[i_mul] = op1 & {DWI{op2[i_mul]}};
        end
    endgenerate

    wire [DWO-1] signed_exp_intermediate [0:DWI-1];
    
    genvar i_exp;
    generate
        for(i_exp=0; i_exp<DWI; i_exp=i_exp+1) begin: expand
            assign signed_exp_intermediate[i_exp] = {8{intermediate[i_exp][DWI-1]}, intermediate[i_exp]};
        end
    endgenerate

    // level 0, 8 row to 6 row
    wire [DWO-1:0] level_0_out_sum [0:1], level_0_out_cout [0:1];
    csa #(16) csa_level_0_0(.op1(signed_exp_intermediate[0]), .op2(signed_exp_intermediate[1]), .op3(signed_exp_intermediate[2]), .sum(level_0_out_sum[0]), .cout(level_0_out_cout[0])); 
    csa #(16) csa_level_0_1(.op1(signed_exp_intermediate[3]), .op2(signed_exp_intermediate[4]), .op3(signed_exp_intermediate[5]), .sum(level_0_out_sum[1]), .cout(level_0_out_cout[1])); 

    // level 1, 6 row to 4 row
    wire [DWO-1:0] level_1_out_sum [0:1], level_1_out_cout [0:1];
    cas #(16) cas_level_1_0(.op1(level_0_out_sum[0]), .op2(level_0_out_cout[0]<<1), .op3(signed_exp_intermediate[6]), .sum(level_1_out_sum[0]), .cout(level_1_out_cout[0]));
    cas #(16) cas_level_1_1(.op1(level_0_out_sum[1]), .op2(level_0_out_cout[1]<<1), .op3(signed_exp_intermediate[7]), .sum(level_1_out_sum[1]), .cout(level_1_out_cout[1]));

    // level 2, 4 row to 3 row
    wire [DWO-1:0] level_2_out_sum, level_2_out_cout;
    cas #(16) cas_level_2_0(.op1(level_1_out_sum[0]), .op2(level_1_out_cout[0]<<1), .op3(level_1_out_sum[1]), .sum(level_2_out_sum), .cout(level_2_out_cout));

    // level 3, 3 row to 2 row
    wire [DWO-1:0] level_3_out_sum, level_3_out_cout;
    cas #(16) cas_level_2_0(.op1(level_2_out_sum), .op2(level_2_out_cout), .op3(level_1_out_cout[1]<<1), .sum(level_3_out_sum), .cout(level_3_out_cout));

    // level 4
    wire [3:0] cout;
    cla #(4) cla_0(.op1(level_3_out_sum[3:0]), .op2((level_3_out_cout<<1)[3:0]), .cin(1'b0), .sum(out[3:0]), .cout(cout[0]));
    cla #(4) cla_0(.op1(level_3_out_sum[7:4]), .op2((level_3_out_cout<<1)[7:4]), .cin(cout[0]), .sum(out[7:4]), .cout(cout[1]));
    cla #(4) cla_0(.op1(level_3_out_sum[11:8]), .op2((level_3_out_cout<<1)[11:8]), .cin(cout[1]), .sum(out[11:8]), .cout(cout[2]));
    cla #(4) cla_0(.op1(level_3_out_sum[15:12]), .op2((level_3_out_cout<<1)[15:12]), .cin(cout[2]), .sum(out[15:12]), .cout(cout[3]));

endmodule