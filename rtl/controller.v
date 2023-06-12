module controller(
	input 			clk,
	input 			rst_n,
	input [32-1:0]		ctrl,

	output reg [32-1:0]	status
);

	//status = {32'h0 -> 56*((56-7)//5+1){32{3{32'h3 -> 32'h33 ##2-> 32'h31 ##2-> 32'h11 -> 32'h10 -> 32'hc -> 32'hc0} -> 32'h100 -> 32'h200} -> 32'400 -> 32'800 -> 32'h1000 ##7}}
	//status = {32'b0, 56*8{32{3{32'b11, 32'b110011, 32'b110001, 32'b010001, 32'b010000, 32'b1100, 32'b11000000}, 32'b100000000, 32'b1000000000}, 32'b10000000000, 32'b100000000000, 32'b1000000000000}}

	localparam IDLE = 32'd0;
	localparam READ = 32'd1;
	localparam EN = 32'd2;
	localparam ROVER = 32'd3;
	localparam DISEN = 32'd4;
	localparam ROVER2 = 32'd5;
	localparam MAC = 32'd6;
	localparam PA = 32'd7;
	localparam BA = 32'd8;
	localparam CA = 32'd9;
	localparam RELU = 32'd10;
	localparam PAR = 32'd11;
	localparam OUT = 32'd12;

	wire start;
	reg [32-1:0] next_state, state;
	assign start = ctrl[0];
	always@(*) begin
		case(state)
			IDLE: if(start) next_state = READ; 
				else next_state = IDLE;
			READ: next_state = EN; 
			EN: if(cnt==flag) next_state = ROVER; 
				else next_state = EN;
			ROVER: if(cnt==flag) next_state = DISEN;  
				else next_state = ROVER;
			DISEN: next_state = ROVER2; 
			ROVER2: next_state = MAC;
			MAC: next_state = PA;
			PA: if(conv_col==3-1) next_state = BA;
				else next_state = READ;
			BA: next_state = CA;
			CA: if(channel==32-1) next_state = RELU;
				else next_state = READ;
			RELU: next_state = PAR;
			PAR: next_state = OUT;
			OUT: if(out==7-1 && cnt==560-1) next_state = IDLE;
				else if(out==7-1 && cnt<560-1) next_state = READ;
				else next_state = OUT;
			default: next_state = IDLE;
		endcase
	end

	wire en;
	assign en = ctrl[2];
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			state <= 32'h0;
		else if(en)
			state <= next_state;
	end

	always@(*) begin
		case(state)
			IDLE: status = 32'h0;
			READ: status = 32'h3;
			EN: status = 32'h33;
			ROVER: status = 32'h31;
			DISEN: status = 32'h11;
			ROVER2: status = 32'h10;
			MAC: status = 32'hc;
			PA: status = 32'hc0;
			BA: status = 32'h100;
			CA: status = 32'h200;
			RELU: status = 32'h400;
			PAR: status = 32'h800;
			OUT: status = 32'h1000;
			default: status = 32'h0;
		endcase
	end

	reg [32-1:0] flag;
	always@(*) begin
		case(state)
			EN: flag = 2-1;
			ROVER: flag = 2-1;
			default: flag = 0;
		endcase
	end

	reg [32-1:0] cnt;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			cnt <= 32'h0;
		else if(cnt==flag)
			cnt <= 32'h0
		else if(en)
			cnt <= cnt + 1;
	end

	reg [32-1] conv_col;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			conv_col <= 0;
		else if(state==PA) begin
			if(conv_col==3-1)
				conv_col <= 0;
			else
				conv_col <= conv_col + 1;
		end
	end

	reg [32-1] channel;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			channel <= 0;
		else if(state==CA) begin
			if(channel==32-1)
				channel <= 0;
			else
				channel <= channel + 1;
		end
	end

	reg [32-1] out;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			out <= 0;
		else if(state==OUT) begin
			if(out==7-1)
				out <= 0;
			else
				out <= out + 1;
		end
	end

	reg [32-1] col;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			col <= 0;
		else if(state==OUT) begin
			if(col==560-1)
				col <= 0;
			else
				col <= col + 1;
		end
	end

endmodule
