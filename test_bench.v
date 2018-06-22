`timescale 1ns/1ps
module test(
);


reg 		clk;
reg 		reset;
reg		pkt_in_valid;
reg		[133:0]	pkt_in;
wire	pkt_out_valid;
wire	[133:0] pkt_out;
reg		ctrl_in_valid;
reg		[1:0]	ctrl_opt;
reg		[31:0]	ctrl_addr;
reg		[31:0]	ctrl_data_in;
wire	ctrl_out_valid;
wire	[31:0]	ctrl_data_out;

unimon_top unimon(
.clk(clk),
.reset(reset),
.pkt_in_valid(pkt_in_valid),
.pkt_in(pkt_in),
.pkt_out_valid(pkt_out_valid),
.pkt_out(pkt_out),
.ctrl_in_valid(ctrl_in_valid),
.ctrl_opt(ctrl_opt),
.ctrl_addr(ctrl_addr),
.ctrl_data_in(ctrl_data_in),
.ctrl_out_valid(ctrl_out_valid),
.ctrl_data_out(ctrl_data_out)
);

initial begin
    clk = 0;
    #5 reset = 1;
    #1 reset = 0;
    #1 reset = 1;
    forever #1 clk = ~clk;
end

reg	[133:0]	data[5:0];

initial begin
    pkt_in_valid <= 1'b0;
	pkt_in <= 1'b0;

	//data;
	data[0] = {2'b01,4'd0,32'd2,32'd1,16'd4,16'd3,6'h12,26'b0};
	//data[0] = {2'b01,4'd0,32'd1,32'd2,16'd3,16'd4,6'h01,26'b0};
	data[1] = {2'b11,4'd0,128'd1};
	data[2] = {2'b11,4'd0,128'd2};
	data[3] = {2'b11,4'd0,128'd3};
	data[4] = {2'b11,4'd0,128'd4};
	data[5] = {2'b10,4'd0,128'd5};
	//data;
	#301 begin
		pkt_in_valid = 1'b1;
		pkt_in = data[0];
	end
	#2 pkt_in = data[1];
	#2 pkt_in = data[2];
	#2 pkt_in = data[4];
	#2 pkt_in = data[5];
	#2 pkt_in_valid = 1'b0;
	
end

/* configuration */
reg	[31:0]	entry[4:0];



initial begin
	ctrl_addr = 32'b0;
	ctrl_opt = 2'd1;
	ctrl_addr = 32'b0;
	ctrl_data_in = 32'b0;
	ctrl_in_valid = 1'b0; 
	
	{entry[4],entry[3],entry[2],entry[1],entry[0]} = {24'b0,
		32'd2,32'd1,16'd4,16'd3, // 4-tuple info
		3'b0,1'b1,2'd1,2'd0,	// state; Requested(cli),closed(ser);
		8'hff,		// pkt_in_cnd;
		4'b1,4'b0, // forward;
		16'h4};		// next index
		//32'b0,		// pkt count
		//32'b0};		// byte count
	
	
	// read;
	#21 begin
		ctrl_addr = {8'd0,4'd0,16'd3,4'd0};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = entry[0];
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	#20 begin
		ctrl_addr = {8'd0,4'd0,16'd3,4'd1};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = entry[1];
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	#20 begin
		ctrl_addr = {8'd0,4'd0,16'd3,4'd2};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = entry[2];
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	#20 begin
		ctrl_addr = {8'd0,4'd0,16'd3,4'd3};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = entry[3];
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	#20 begin
		ctrl_addr = {8'd0,4'd0,16'd3,4'd4};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = entry[4];
	end
	/* del connTb */
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	#20 begin
		ctrl_opt = 2'd0;
		ctrl_addr = {8'd0,4'd0,16'd3,4'd0};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = entry[4];
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	/* hash chain in connTb
	#20 begin
		ctrl_addr = {8'd0,4'd0,16'd4,4'd4};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = entry[4];
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	*/
	/* hash table */
	#20 begin
		ctrl_opt = 2'd1;
		ctrl_addr = {8'd0,4'd1,16'd6,4'd0};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = {16'h3,16'd2};
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	#20 begin
		ctrl_addr = {8'd0,4'd2,16'd2,4'd0};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = {16'h4,16'd3};
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	/* del hashTb 
	#20 begin
		ctrl_opt = 2'd2;
		ctrl_addr = {8'd0,4'd2,16'd2,4'd0};
		ctrl_in_valid = 1'b1;
		ctrl_data_in = {16'h4,16'd3};
	end
	#2 begin
		ctrl_in_valid = 1'b0;
	end
	*/
end


endmodule
