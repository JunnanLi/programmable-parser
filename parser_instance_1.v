//=====================================================//
//	Module name: parser module for UniMon;
//	Communication with lijunnan(lijunnan@nudt.edu.cn)
//	Last edited time: 2018/06/08
//	Function outline: smartPipe_v0.1
//=====================================================//

`timescale 1ns/1ps
/** parameter definition:
*	NUM_OF_REG is the number of metaReg (8b) used to construct metadata/_temp;
*	NUM_OF_META is the number of metadata_temp used to write to meta_buffer;
*	READY_COUNT is the minmun clocks used to parse a packet to get metaRegs;
*/

`define NUM_OF_REG 32
`define NUM_OF_META 3
`define READY_COUNT 4

/** take UniMan with L2 switch for example
*	metadata_temp[1]:{dmac(6B), smac(6B), 4B}
*	metadata_temp[2]:{5-tuple(13)(i.e., protocol, srcIP, dstIP, srcPort, dstPort),
		tcp_flag(1B), 2B};

`define NUM_OF_REG 32
`define NUM_OF_META 3
`define READY_COUNT 4
*/

module parser(
	clk,
	reset,
	metadata_in_valid,
	metadata_in,
	metadata_out_valid,
	metadata_out,
	ready_in,
	ready_out
);

/** signals definition:
*	ready_in is used to backpress;
*	ready_out is used to tell cdp to input packets;
*/
input			clk;
input			reset;
input			metadata_in_valid;
input		[133:0]	metadata_in;
output	reg		metadata_out_valid;
output	reg	[133:0]	metadata_out;
input			ready_in;
output	reg		ready_out;

/*********************************************************************************/
/* 	variables	*/
/* packet and metadata buffer	
*/
reg	[133:0]	data_pktBuffer;
reg		rdreq_pktBuffer;
reg		wrreq_pktBuffer;
wire		empty_pktBuffer;
wire	[133:0]	ctx_pktBuffer;

reg	[133:0]	data_meta;
reg		rdreq_meta;
reg		wrreq_meta;
wire		empty_meta;
wire	[133:0]	ctx_meta;

/***Protocol_definition_toInsert*/
parameter
		IDLE_P	= 4'd0,
		ARP_P	= 4'd1,
		IP_P	= 4'd2,
		TCP_P	= 4'd3,
		OTHER_P	= 4'd4;
/** take UniMan with L2 switch for example 
parameter	IDLE_P		= 4'd0,
		ARP_P		= 4'd1,
		IP_P		= 4'd2,
		TCP_P		= 4'd3,
		OTHER_P	= 4'd4;
*/

/** define_regs:
*	metaReg is used to extract fileds from packet;
*	metadata_temp is used to combine metaReg;
*	count is used count clks to ensure parsing completely;
*	count_meta is used to count clks to ensure writing metadata completely;
*	reg_tag is used by metaReg to tell metadata_temp that metaReg is ready;
*	reg_tag_temp is used by metadata_temp whether metaReg is ready, i.e.,
*		reg_tag_temp = ~reg_tag;
*	protocol_type represents the type of parsed packets, is used to distinguish 
*		which metaReg should be assigned;
*/
reg	[7:0]	metaReg[`NUM_OF_REG-1:0];
reg	[133:0]	metadata_temp[`NUM_OF_META-1:0];
reg	[3:0]	count, count_meta;
reg		reg_tag, reg_tag_temp;
reg	[3:0]	protocol_type;

/*********************************************************************************/
/*	parser main logic	*/
reg	[3:0]	state_parser, state_readPkt, state_meta, state_input;
parameter	IDLE_S			= 4'd0,
		READ_PKT_1_S		= 4'd1,
		READ_PKT_2_S		= 4'd2,
		READ_PKT_3_S		= 4'd3,
		READ_PKT_4_S		= 4'd4,
		READ_PKT_5_S		= 4'd5,
		READ_PKT_6_S		= 4'd6,
		READ_PKT_7_S		= 4'd7,
		READ_PKT_TAIL_S	= 4'd8,
		WAIT_PADING_S	= 4'd9,
		READ_META_S		= 4'd1,
		READ_PKT_S		= 4'd2,
		WRITE_META_S		= 4'd1,
		WAIT_PKT_HEAD_S	= 4'd1,
		WAIT_PKT_TAIL_S	= 4'd2;

integer i, j;
integer meta_i, meta_j;

/****************************************************************************************/
/** state machine of parsing packets:
*	+>assign metaReg from packets;
*	+>count clks to ensure parsing completely, then assign reg_tag, and ready_out;
*/
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		for(i=0; i< `NUM_OF_REG; i = i+1)
			metaReg[i] <= 8'b0;
		count <= 4'b0;
		ready_out <= 1'b1;
		reg_tag <= 1'b0;
		protocol_type <= 4'b0;
		metadata_temp[0] <= 134'b0;
		state_parser <= IDLE_S;
	end
	else begin
		case(state_parser)
			IDLE_S: begin
				/** initial metaReg[j] */
				for(j=0; j< `NUM_OF_REG; j = j+1)
					metaReg[j] <= 8'b0;
				if((metadata_in_valid == 1'b1) && (ready_in == 1'b1) && 
					(metadata_in[133:132] == 2'b01))
				begin
/***assign_reg_from_pkt_0*/
					ready_out <= 1'b0;
					/** restore the previous metadata */
					metadata_temp[0] <= metadata_in;
					/** count parsed clks */
					count <= 4'd1;
					/** initial protocol_type */
					protocol_type <= 4'd0;
					state_parser <= READ_PKT_1_S;
				end
				else begin
					state_parser <= IDLE_S;
				end
			end
			READ_PKT_1_S: begin
				count <= count + 4'd1;
/***assign_reg_from_pkt_1*/
case(protocol_type)
	IDLE_P: begin
		if(metadata_in[31:16] == 16'h0800) begin
			protocol_type <= IP_P;
			state_parser <= READ_PKT_2_S;
		end
		else begin
			protocol_type <= ARP_P;
			reg_tag <= ~reg_tag;
			state_parser <= READ_PKT_TAIL_S;
		end
		{metaReg[0],metaReg[1],metaReg[2],metaReg[3],metaReg[4],metaReg[5]}<= metadata_in[127:80];
		{metaReg[6],metaReg[7],metaReg[8],metaReg[9],metaReg[10],metaReg[11]}<= metadata_in[79:32];
	end
	default: begin
		reg_tag <= ~reg_tag;
		state_parser <= READ_PKT_TAIL_S;
	end
endcase
				/**take UniMan with L2 switch for example
				case(protocol_type)
					IDLE_P: begin
						if(metadata_in[31:16] == 16'h0800) begin
							protocol_type <= IP_P;
							state_parser <= READ_PKT_2_S;
{metaReg[0],metaReg[1],metaReg[2],metaReg[3],metaReg[4],metaReg[5]} <= metadata_in[127:80];
{metaReg[6],metaReg[7],metaReg[8],metaReg[9],metaReg[10],metaReg[11]} <= metadata_in[127:80];
						end
						else begin
							protocol_type <= ARP_P;
							reg_tag <= ~reg_tag;
							state_parser <= READ_PKT_TAIL_S;
{metaReg[0],metaReg[1],metaReg[2],metaReg[3],metaReg[4],metaReg[5]} <= metadata_in[127:80];
{metaReg[6],metaReg[7],metaReg[8],metaReg[9],metaReg[10],metaReg[11]} <= metadata_in[127:80];
						end
					end
					default: begin
						reg_tag <= ~reg_tag;
						state_parser <= READ_PKT_TAIL_S;
					end
				endcase
				*/
			end
			READ_PKT_2_S: begin
				count <= count + 4'd1;
/***assign_reg_from_pkt_2*/
case(protocol_type)
	IP_P: begin
		if(metadata_in[71:64] == 8'h06) begin
			protocol_type <= TCP_P;
			state_parser <= READ_PKT_3_S;
		end
		else begin
			protocol_type <= OTHER_P;
			reg_tag <= ~reg_tag;
			state_parser <= READ_PKT_TAIL_S;
		end
		{metaReg[16]}<= metadata_in[71:64];
		{metaReg[17],metaReg[18],metaReg[19],metaReg[20]}<= metadata_in[47:16];
		{metaReg[21],metaReg[22]}<= metadata_in[15:0];
	end
	default: begin
		reg_tag <= ~reg_tag;
		state_parser <= READ_PKT_TAIL_S;
	end
endcase
				/**take UniMan with L2 switch for example
				case(protocol_type)
					IP_P: begin
						if(metadata_in[71:64] == 8'h06) begin
							protocol_type <= TCP_P;
							state_parser <= READ_PKT_3_S;
{metaReg[16]} <= metadata_in[71:64];
{metaReg[17],metaReg[18],metaReg[19],metaReg[20]} <= metadata_in[47:16];
{metaReg[21],metaReg[22]} <= metadata_in[15:0];
						end
						else begin
							protocol_type <= OTHER_P;
							reg_tag <= ~reg_tag;
							state_parser <= READ_PKT_TAIL_S;
						end
					end
					default: begin
						reg_tag <= ~reg_tag;
						state_parser <= READ_PKT_TAIL_S;
					end
				endcase
				*/
			end
			READ_PKT_3_S: begin
				count <= count + 4'd1;
/***assign_reg_from_pkt_3*/
case(protocol_type)
	TCP_P: begin
		if(1) begin
			protocol_type <= TCP_P;
			reg_tag <= ~reg_tag;
			state_parser <= READ_PKT_TAIL_S;
		end
		else begin
			protocol_type <= OTHER_P;
			reg_tag <= ~reg_tag;
			state_parser <= READ_PKT_TAIL_S;
		end
		{metaReg[23],metaReg[24]}<= metadata_in[127:112];
		{metaReg[25],metaReg[26]}<= metadata_in[111:96];
		{metaReg[27],metaReg[28]}<= metadata_in[95:80];
		{metaReg[29]}<= metadata_in[7:0];
	end
	default: begin
		reg_tag <= ~reg_tag;
		state_parser <= READ_PKT_TAIL_S;
	end
endcase
				/**take UniMan with L2 switch for example
				case(protocol_type)
					TCP_P: begin
						if(1) begin
							protocol_type <= TCP_P;
							reg_tag <= ~reg_tag;
							state_parser <= READ_PKT_TAIL_S;
{metaReg[23],metaReg[24]} <= metadata_in[127:112];
{metaReg[25],metaReg[26]} <= metadata_in[111:96];
{metaReg[27],metaReg[28]} <= metadata_in[95:80];
{metaReg[29]} <= metadata_in[7:0];
						end
						else begin
							protocol_type <= OTHER_P;
							reg_tag <= ~reg_tag;
							state_parser <= READ_PKT_TAIL_S;
						end
					end
					default: begin
						reg_tag <= ~reg_tag;
						state_parser <= READ_PKT_TAIL_S;
					end
				endcase
				*/
			end
			READ_PKT_4_S: begin
				count <= count + 4'd1;
/***assign_reg_from_pkt_4*/
				/**take UniMan with L2 switch for example*/
				/*
				if(metadata_in[133:132] == 2'b10) begin
					state_parser <= WAIT_PADING_S;
				end
				else begin
					reg_tag <= ~reg_tag;
					state_parser <= READ_PKT_TAIL_S;
				end
				*/
			end
			READ_PKT_5_S: begin
				count <= count + 4'd1;
/***assign_reg_from_pkt_5*/
				
			end
			READ_PKT_6_S: begin
				count <= count + 4'd1;
/***assign_reg_from_pkt_6*/
				
			end
			READ_PKT_7_S: begin
				count <= count + 4'd1;
/***assign_reg_from_pkt_7*/
				
			end
			READ_PKT_TAIL_S: begin
				count <= count + 4'd1;
				if(metadata_in[133:132] == 2'b10)
					state_parser <= WAIT_PADING_S;
				else
					state_parser <= READ_PKT_TAIL_S;
			end
			WAIT_PADING_S: begin
				if(count >= `READY_COUNT) begin
					ready_out <= 1'b1;
					state_parser <= IDLE_S;
				end
				else begin
					count <= count + 4'd1;
					state_parser <= WAIT_PADING_S;
				end
			end
			default: begin
				state_parser <= IDLE_S;
			end
		endcase
	end
end

/****************************************************************************************/
/** state machine of writing metadatas:
*	+>assign metadata_temp from metaReg;
*	+>count clks to ensure writing metaReg completely;
*/
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		for(meta_i = 1; meta_i < `NUM_OF_META; meta_i = meta_i + 1)
			metadata_temp[meta_i] <= 134'b0;
		reg_tag_temp <= 1'b0;
		count_meta <= 4'd0;
		wrreq_meta <= 1'b0;
		data_meta <= 134'b0;
		state_meta <= IDLE_S;
	end
	else begin
		case(state_meta)
			IDLE_S: begin
				if(reg_tag_temp != reg_tag) begin
					reg_tag_temp = reg_tag;
/***assign_metadata_temp*/
metadata_temp[1] <= {2'b11,4'b0,metaReg[0],metaReg[1],metaReg[2],metaReg[3],metaReg[4],metaReg[5],metaReg[6],metaReg[7],metaReg[8],metaReg[9],metaReg[10],metaReg[11],metaReg[12],metaReg[13],metaReg[14],metaReg[15]};
metadata_temp[2] <= {2'b00,4'b0,metaReg[16],metaReg[17],metaReg[18],metaReg[19],metaReg[20],metaReg[21],metaReg[22],metaReg[23],metaReg[24],metaReg[25],metaReg[26],metaReg[27],metaReg[28],metaReg[29],metaReg[30],metaReg[31]};
					/** take UuiMan with L2 switch for example
metadata_temp[1] <= {2'b11,4'b0,metaReg[0],metaReg[1],metaReg[2],metaReg[3],
						metaReg[4],metaReg[5],metaReg[6],metaReg[7],
						metaReg[8],metaReg[9],metaReg[10],metaReg[11],
						metaReg[12],metaReg[13],metaReg[14],metaReg[15]};
metadata_temp[2] <= {2'b00,4'b0,metaReg[16],metaReg[17],metaReg[18],metaReg[19],
						metaReg[20],metaReg[21],metaReg[22],metaReg[23],
						metaReg[24],metaReg[25],metaReg[26],metaReg[27],
						metaReg[28],metaReg[29],metaReg[30],metaReg[31]};
					*/	
						
					count_meta <= 4'd0;
					state_meta <= WRITE_META_S;
				end
			end
			WRITE_META_S: begin
				count_meta <= count_meta + 4'd1;
				if(count_meta < `NUM_OF_META) begin
					wrreq_meta <= 1'b1;
					for(meta_j = 0; meta_j < `NUM_OF_META; meta_j = meta_j+1)
					begin
						if(meta_j[3:0] == count_meta)
							data_meta <= metadata_temp[meta_j];
					end
					state_meta <= WRITE_META_S;
				end
				else begin
					wrreq_meta <= 1'b0;
					state_meta <= IDLE_S;
				end
			end
			default: begin
				state_meta <= IDLE_S;
			end
		endcase		
	end
end

/****************************************************************************************/
/** state machine of output packets:
*	+> start of metadata is 2'b01, body is 2'b11, and end is 2'b00;
*	+> start of pkt is 2'b01, body is 2'b11, and end is 2'b10;
*/
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		metadata_out_valid <= 1'b0;
		metadata_out <= 134'b0;

		rdreq_pktBuffer <= 1'b0;
		rdreq_meta <= 1'b0;
		state_readPkt <= IDLE_S;
	end
	else begin
		case(state_readPkt)
			IDLE_S: begin
				metadata_out_valid <= 1'b0;
				if(empty_meta == 1'b0) begin
					rdreq_meta <= 1'b1;
					state_readPkt <= READ_META_S;
				end
				else
					state_readPkt <= IDLE_S;
			end
			READ_META_S: begin
				metadata_out_valid <= 1'b1;
				metadata_out <= ctx_meta;
				if(ctx_meta[133:132] == 2'b00) begin
					state_readPkt <= READ_PKT_S;
					rdreq_pktBuffer <= 1'b1;
					rdreq_meta <= 1'b0;
				end
				else begin
					state_readPkt <= READ_META_S;
				end
			end
			READ_PKT_S: begin
				metadata_out_valid <= 1'b1;
				metadata_out <= ctx_pktBuffer;
				if(ctx_pktBuffer[133:132] == 2'b10) begin
					state_readPkt <= IDLE_S;
					rdreq_pktBuffer <= 1'b0;
				end
				else begin
					state_readPkt <= READ_PKT_S;
				end
			end
			default: state_readPkt <= IDLE_S;
		endcase
	end
end


/****************************************************************************************/
/** state machine of inputing packets:
*/
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		wrreq_pktBuffer <= 1'b0;
		data_pktBuffer <= 134'b0;
		state_input <= IDLE_S;	
	end
	else begin
		case(state_input)
			IDLE_S: begin
				if((metadata_in_valid == 1'b1) && (metadata_in[133:132] == 2'b01))
				begin
					wrreq_pktBuffer <= 1'b0;
					//data_pktBuffer <= metadata_in;
					state_input <= WAIT_PKT_HEAD_S;
				end
				else begin
					wrreq_pktBuffer <= 1'b0;
					state_input <= IDLE_S;
				end
			end
			WAIT_PKT_HEAD_S: begin
				if(metadata_in[133:132] == 2'b01) begin
					wrreq_pktBuffer <= 1'b1;
					data_pktBuffer <= metadata_in;
					state_input <= WAIT_PKT_TAIL_S;
				end
				else begin
					state_input <= WAIT_PKT_HEAD_S;
				end
			end
			WAIT_PKT_TAIL_S: begin
				wrreq_pktBuffer <= 1'b1;
				data_pktBuffer <= metadata_in;
				if(metadata_in[133:132] == 2'b10) begin
					state_input <= IDLE_S;
				end
				else begin
					state_input <= WAIT_PKT_TAIL_S;
				end
			end
			default: begin
				state_input <= IDLE_S;
			end
		endcase
	end
end


/*packet buffer(fifo) */
fifo packet_buffer(
.aclr(!reset),
.clock(clk),
.data(data_pktBuffer),
.rdreq(rdreq_pktBuffer),
.wrreq(wrreq_pktBuffer),
.empty(empty_pktBuffer),
.full(),
.q(ctx_pktBuffer),
.usedw()
);
defparam
	packet_buffer.width = 134,
	packet_buffer.depth = 8,
	packet_buffer.words = 256;

/*packet buffer(fifo) */
fifo meta_buffer(
.aclr(!reset),
.clock(clk),
.data(data_meta),
.rdreq(rdreq_meta),
.wrreq(wrreq_meta),
.empty(empty_meta),
.full(),
.q(ctx_meta),
.usedw()
);
defparam
	meta_buffer.width = 134,
	meta_buffer.depth = 5,
	meta_buffer.words = 32;

endmodule    
