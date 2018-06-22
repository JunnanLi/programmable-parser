//=====================================================//
//	Module name: transmition module for UniMon;
//	Communication with lijunnan(lijunnan@nudt.edu.cn)
//	Last edited time: 2018/06/04
//	Function outline: UniMon_v0.3
//=====================================================//

`timescale 1ns/1ps

module transmition(
	clk,
	reset,
	metadata_in_valid,
	metadata_in,
	metadata_out_valid,
	metadata_out,
	um2cdp_rule_wrreq,
	um2cdp_rule,
	cdp2um_rule_usedw,
	cdp2um_tx_enable
);

input				clk;
input				reset;
input				metadata_in_valid;
input		[133:0]	metadata_in;
output	reg			metadata_out_valid;
output	reg	[138:0]	metadata_out;
output	reg			um2cdp_rule_wrreq;
output	reg	[29:0]	um2cdp_rule;
input		[4:0]	cdp2um_rule_usedw;
input				cdp2um_tx_enable;

/*********************************************************************************/
/* 	variables	*/
/* packet buffer	
*/
reg				rdreq_pktBuffer;
wire			empty_pktBuffer;
wire	[133:0]	ctx_pktBuffer;

/** ram used for multicast*/
reg		[7:0]	idx_pkt;
reg				rden_pkt,wren_pkt;
reg		[133:0]	data_pkt;
wire	[133:0]	ctx_pkt;

/* state machine */
reg	[7:0]	outPort;
reg	[47:0]	dstMac,srcMac;
reg	[15:0]	ethType,ipHead_tag;
reg	[79:0]	ipDefault;
reg	[31:0]	srcIP,dstIP;
reg	[127:0]	payload;
reg	[7:0]	protocol;
reg			forward_temp;	// used to tag whether need to be forwarded;

/*********************************************************************************/
reg	[4:0]	state_trans;
parameter	IDLE_S				= 5'd0,
			READ_FIFO_S			= 5'd1,
			READ_META_2_S		= 5'd2,
			WRITE_RULE_S		= 5'd3,
			WAIT_SEND_PKT_S		= 5'd4,
			WAIT_SEND_PKT_C_S	= 5'd5,
			WAIT_PKT_TAIL_S		= 5'd6,
			SEND_PKT_ETH_S		= 5'd7,
			SEND_PKT_IP_S		= 5'd8,
			SEND_PKT_PAYLOAD_S	= 5'd9,
			SEND_PKT_TAIL_S		= 5'd10,
			SEND_PKT_HEAD_S		= 5'd11,
			DISCARD_S			= 5'd12,
			TRANS_RAM_PKT_S		= 5'd13,
			WAIT_TRANS_RAM_PKT_S= 5'd14,
			WAIT_RAM_1_S		= 5'd15,
			WAIT_RAM_2_S		= 5'd16,
			READ_RAM_S			= 5'd17;

/* write packet buffer */
always @(posedge clk or negedge reset) begin
	if (!reset) begin
		metadata_out_valid <= 1'b0;
		metadata_out <= 138'b0;
		um2cdp_rule_wrreq <= 1'b0;
		um2cdp_rule <= 30'b0;

		outPort <= 8'd0;
		protocol <= 8'b0;
		rdreq_pktBuffer <= 1'b0;
		rden_pkt <= 1'b0;
		wren_pkt <= 1'b0;
		data_pkt <= 134'b0;
		idx_pkt <= 8'b0;
		
		dstMac <= 48'h0000_1111_1111;
		srcMac <= 48'h0000_2222_2222;
		ethType <= 16'h0800;
		ipHead_tag <= 16'h4500;
		ipDefault <= {16'h0032,16'h706b,16'h4000,8'h7f,8'd252,16'h0};
		srcIP <= 32'h0000_2222;
		dstIP <= 32'h0000_1111;
		payload <= 128'b0;
		forward_temp <= 1'b0;

		state_trans <= IDLE_S;
	end
	else begin
		case(state_trans)
			IDLE_S: begin
				metadata_out_valid <= 1'b0;
				wren_pkt <= 1'b0;
				um2cdp_rule_wrreq <= 1'b0;
				outPort <= 8'd0;
				forward_temp <= 1'b0;
				if((cdp2um_rule_usedw <= 5'd28) &&
					(empty_pktBuffer == 1'b0)) 
				begin
					rdreq_pktBuffer <= 1'b1;
					state_trans <= READ_FIFO_S;
				end
				else begin
					state_trans <= IDLE_S;
				end
			end
			READ_FIFO_S: begin	/** read metadata[0] */
				/** assign outport */
				if(ctx_pktBuffer[123:120] == 4'd0) 		outPort <= 8'd2;
				else if(ctx_pktBuffer[123:120]==4'd1)	outPort <= 8'd1;
				else outPort <= 8'd0;
				protocol <= ctx_pktBuffer[119:112];
				state_trans <= READ_META_2_S;
			end
			READ_META_2_S: begin /** read metadata[1] */
				rdreq_pktBuffer <= 1'b0;
				
				/** pkt_in message */
				if(ctx_pktBuffer[81] == 1'b1) begin
					/** this bit may be valid only when it is a tcp packet */
					forward_temp <= ctx_pktBuffer[80];
					payload <= ctx_pktBuffer[127:0];
					um2cdp_rule_wrreq <= 1'b1;
					um2cdp_rule <= {29'b0,1'b1};
					state_trans <= WAIT_SEND_PKT_C_S;
				end
				else begin
					forward_temp <= 1'b0;
					if(protocol == 8'd6) begin
						if(ctx_pktBuffer[80] == 1'b0) begin
							state_trans <= DISCARD_S;
							rdreq_pktBuffer <= 1'b1;
						end
						else begin
							um2cdp_rule_wrreq <= 1'b1;
							um2cdp_rule <= {22'b0,outPort};
							state_trans <= WAIT_SEND_PKT_S;
						end
					end
					else begin
						um2cdp_rule_wrreq <= 1'b1;
						um2cdp_rule <= {22'b0,outPort};
						state_trans <= WAIT_SEND_PKT_S;
					end
				end
			end
			WRITE_RULE_S: begin
				metadata_out_valid <= 1'b0;
				um2cdp_rule_wrreq <= 1'b1;
				um2cdp_rule <= {22'b0,outPort};
				state_trans <= WAIT_SEND_PKT_S;
			end
			WAIT_SEND_PKT_S: begin
				um2cdp_rule_wrreq <= 1'b0;
				if(cdp2um_tx_enable == 1'b1) begin
					forward_temp <= 1'b0;
					rdreq_pktBuffer <= 1'b1;
					state_trans <= WAIT_PKT_TAIL_S;
				end
			end
			WAIT_PKT_TAIL_S: begin
				idx_pkt <= idx_pkt + 8'd1;
				data_pkt <= ctx_pktBuffer;
			
				metadata_out_valid <= 1'b1;
				/** change 134b to 139b */
				metadata_out[127:0] <= ctx_pktBuffer[127:0];
				metadata_out[131:128] <= 4'b0;
				metadata_out[135:132] <= ctx_pktBuffer[131:128];
				case(ctx_pktBuffer[133:132])
					2'b01: metadata_out[138:136] <= 3'b101;
					2'b11: metadata_out[138:136] <= 3'b100;
					2'b10: metadata_out[138:136] <= 3'b110;
					default: metadata_out[138:136] <= 3'b100;
				endcase
				/** check pkt tail */
				if(ctx_pktBuffer[133:132] == 2'b10) begin
					rdreq_pktBuffer <= 1'b0;
					if(forward_temp == 1'b1) begin
						forward_temp <= 1'b0;
						state_trans <= TRANS_RAM_PKT_S;
					end
					else
						state_trans <=IDLE_S;
				end
				else state_trans <= WAIT_PKT_TAIL_S;
			end
			WAIT_SEND_PKT_C_S: begin
				um2cdp_rule_wrreq <= 1'b0;
				if(cdp2um_tx_enable == 1'b1) begin
					state_trans <= SEND_PKT_ETH_S;
				end
			end
			SEND_PKT_ETH_S: begin
				metadata_out_valid <= 1'b1;
				metadata_out <= {3'b101,4'hf,4'b0,dstMac,srcMac,ethType,ipHead_tag};
				state_trans <= SEND_PKT_IP_S;
			end
			SEND_PKT_IP_S: begin
				metadata_out <= {3'b100,4'hf,4'b0,ipDefault,srcIP,dstIP[31:16]};
				state_trans <= SEND_PKT_PAYLOAD_S;
			end
			SEND_PKT_PAYLOAD_S: begin
				metadata_out <= {3'b100,4'hf,4'b0,dstIP[15:0],payload[127:16]};
				if(payload[96:88] == 8'd16)
					/** event type == OUT_TIME */
					state_trans <= SEND_PKT_TAIL_S;
				else begin
					rdreq_pktBuffer <= 1'b1;
					state_trans <= SEND_PKT_HEAD_S;
				end
			end
			SEND_PKT_TAIL_S: begin
				metadata_out <= {3'b110,4'hf,4'b0,128'b0};
				state_trans <= IDLE_S;
			end
			SEND_PKT_HEAD_S: begin
				idx_pkt <= 8'b0;
				data_pkt <= ctx_pktBuffer;
				wren_pkt <= 1'b1;
			
				metadata_out_valid <= 1'b1;
				metadata_out <= {3'b100,4'hf,4'd0,ctx_pktBuffer[127:0]};
				state_trans <= WAIT_PKT_TAIL_S;
			end
			DISCARD_S: begin
				if(ctx_pktBuffer[133:132] == 2'b10) begin
					rdreq_pktBuffer <= 1'b0;
					state_trans <= IDLE_S;
				end
				else begin
					state_trans <= DISCARD_S;
				end
			end
			TRANS_RAM_PKT_S: begin
				metadata_out_valid <= 1'b0;
				wren_pkt <= 1'b0;
				if(outPort!=8'b0) begin
					um2cdp_rule_wrreq <= 1'b1;
					um2cdp_rule <= {22'b0,outPort};
					state_trans <= WAIT_TRANS_RAM_PKT_S;
				end
				else
					state_trans <= IDLE_S;
			end
			WAIT_TRANS_RAM_PKT_S: begin
				um2cdp_rule_wrreq <= 1'b0;
				if(cdp2um_tx_enable == 1'b1) begin
					state_trans <= WAIT_RAM_1_S;
					
					idx_pkt <= 8'd0;
					rden_pkt <= 1'b1;
				end
				else
					state_trans <= WAIT_TRANS_RAM_PKT_S;
			end
			WAIT_RAM_1_S: begin
				idx_pkt <= idx_pkt + 8'd1;
				state_trans <= WAIT_RAM_2_S;
			end
			WAIT_RAM_2_S: begin
				idx_pkt <= idx_pkt + 8'd1;
				state_trans <= READ_RAM_S;
			end
			READ_RAM_S: begin
				idx_pkt <= idx_pkt + 8'd1;
				metadata_out_valid <= 1'b1;
				/** change 134b to 139b */
				metadata_out[127:0] <= ctx_pkt[127:0];
				metadata_out[131:128] <= 4'b0;
				metadata_out[135:132] <= ctx_pkt[131:128];
				case(ctx_pkt[133:132])
					2'b01: metadata_out[138:136] <= 3'b101;
					2'b11: metadata_out[138:136] <= 3'b100;
					2'b10: metadata_out[138:136] <= 3'b110;
					default: metadata_out[138:136] <= 3'b100;
				endcase
				if(ctx_pkt[133:132] == 2'b10) begin
					rden_pkt <= 1'b0;
					state_trans <= IDLE_S;
				end
				else
					state_trans <= READ_RAM_S;
			end
			default: state_trans <= IDLE_S;
		endcase
	end
end

/*packet buffer(fifo) */
fifo packet_buffer(
.aclr(!reset),
.clock(clk),
.data(metadata_in),
.rdreq(rdreq_pktBuffer),
.wrreq(metadata_in_valid),
.empty(empty_pktBuffer),
.full(),
.q(ctx_pktBuffer),
.usedw()
);
defparam
	packet_buffer.width = 134,
	packet_buffer.depth = 8,
	packet_buffer.words = 256;

ram packet_ram(
.address_a(idx_pkt),
.address_b(8'b0),
.clock(clk),
.data_a(data_pkt),
.data_b(134'b0),
.rden_a(rden_pkt),
.rden_b(1'b0),
.wren_a(wren_pkt),
.wren_b(1'b0),
.q_a(ctx_pkt),
.q_b()
);
defparam
	packet_ram.width = 134,
	packet_ram.depth = 8,
	packet_ram.words = 256;
	
	

endmodule    
