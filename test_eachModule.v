`timescale 1ns/1ps
module test_module(
);

parameter 		w_connTb = 68,
			d_connTb = 9,
			words_connTb = 512,
			w_hashTb = 17,
			d_hashTb = 9,
			words_hashTb = 512,
			w_flowKTb = 121,
			d_flowKTb = 9,
			words_flowKTb = 512;

/** test programmable parser */
reg 		clk;
reg 		reset;
reg		pkt_in_valid;
reg	[133:0]	pkt_in;
wire		pkt_out_valid;
wire	[133:0]	pkt_out;
wire		ready;

parser parser(
.clk(clk),
.reset(reset),
.metadata_in_valid(pkt_in_valid),
.metadata_in(pkt_in),
.metadata_out_valid(pkt_out_valid),
.metadata_out(pkt_out),
.ready_in(1'b1),
.ready_out(ready)
);


initial begin
	clk = 0;
	#5 reset = 1;
	#1 reset = 0;
	#1 reset = 1;
 	forever #1 clk = ~clk;
end

reg	[133:0]	meta[7:0];

initial begin
	meta[0] = {2'b01,4'd0,128'b0};
	//data[0] = {2'b01,4'd0,32'd1,32'd2,16'd3,16'd4,6'h01,26'b0};
	meta[1] = {2'b01,4'd0,48'h000011112222,48'h333344445555,16'h0800,16'h4500};
	meta[2] = {2'b11,4'b0,56'b0,8'h6,16'b0,32'h00001111,16'h2222};
	meta[3] = {2'b11,4'b0,16'h3333,16'h0001,16'h0002,72'b0,8'h11};
	meta[4] = {2'b10,4'b0,128'd1};
	meta[5] = {2'b11,4'b0,128'd2};
	

    	pkt_in_valid = 1'b0;
	pkt_in = 1'b0;
	#21 begin
		pkt_in_valid = 1'b1;
		pkt_in = meta[0];
	end
	#2 	pkt_in = meta[1];
	#2 	pkt_in = meta[2];
	#2 	pkt_in = meta[3];
	#2 	pkt_in = meta[4];
	#2	pkt_in_valid = 1'b0;
	#60 begin
		pkt_in_valid = 1'b1;
		pkt_in = meta[0];
	end
	#2 pkt_in = meta[1];
	#2 pkt_in = meta[2];
	#2 pkt_in = meta[3];
	#2 pkt_in = meta[5];
	#2 pkt_in = meta[4];
	#2 pkt_in_valid = 1'b0;
	/*
	#60 begin
		pkt_in_valid = 1'b1;
		pkt_in = meta[0];
	end
	#2 pkt_in = meta[3];
	#2 pkt_in = meta[2];
	#2 pkt_in = meta[1];
	#2 pkt_in = meta[5];
	#2 pkt_in_valid = 1'b0;
	
	#60 begin
		pkt_in_valid = 1'b1;
		pkt_in = meta[0];
	end
	#2 pkt_in = meta[7];
	#2 pkt_in = meta[2];
	#2 pkt_in = meta[3];
	#2 pkt_in = meta[5];
	#2 pkt_in_valid = 1'b0;
	
	#60 begin
		pkt_in_valid = 1'b1;
		pkt_in = meta[0];
	end
	#2 pkt_in = meta[4];
	#2 pkt_in = meta[2];
	#2 pkt_in = meta[1];
	#2 pkt_in = meta[5];
	#2 pkt_in_valid = 1'b0;
	
	#60 begin
		pkt_in_valid = 1'b1;
		pkt_in = meta[0];
	end
	#2 pkt_in = meta[6];
	#2 pkt_in = meta[2];
	#2 pkt_in = meta[1];
	#2 pkt_in = meta[5];
	#2 pkt_in_valid = 1'b0;
	*/
end

	



endmodule
