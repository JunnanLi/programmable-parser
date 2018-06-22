//=====================================================//
//	Module name: top module for UniMon;
//	Communication with ...
//	Last edited time: 2018/05/20
//	Function outline: UniMon_v0.2
//=====================================================//

`timescale 1ns/1ps

module um(
	clk,
	reset,
	localbus_cs_n,
	localbus_rd_wr,
	localbus_data,
	localbus_ale,
	localbus_ack_n,
	localbus_data_out,

	um2cdp_path,
	cdp2um_data_valid,
	cdp2um_data,
	um2cdp_tx_enable,
	um2cdp_data_valid,
	um2cdp_data,
	cdp2um_tx_enable,
	um2cdp_rule,
	um2cdp_rule_wrreq,
	cdp2um_rule_usedw
);

input			clk;
input			reset;
input			localbus_cs_n;
input			localbus_rd_wr;
input		[31:0]	localbus_data;
input			localbus_ale;
output	reg		localbus_ack_n;
output	reg	[31:0]	localbus_data_out;

output	reg		um2cdp_path;
input			cdp2um_data_valid;
input		[138:0]	cdp2um_data;
output	reg		um2cdp_tx_enable;
output	wire		um2cdp_data_valid;
output	wire	[138:0]	um2cdp_data;
input			cdp2um_tx_enable;
output	wire		um2cdp_rule_wrreq;
output	wire	[29:0]	um2cdp_rule;
input		[4:0]	cdp2um_rule_usedw;

/*************************************************************************************/
/*	varialbe declaration */
/*	from parser to uniMon;
*/
wire		meta_valid_parser;
wire	[133:0]	meta_parser;

/*	from parser to conf;
*/
wire		confInfo_valid;
wire	[63:0]	confInfo;

/*	from uniman to firewall
*/
wire		meta_valid_unimon;
wire	[133:0]	meta_unimon;
wire		ready;

/*	from firewall to transmition
*/
wire		meta_valid_firewall;
wire	[133:0]	meta_firewall;


/*	from configuration to unimon;
*/
reg				ctrl_in_valid_uniman,ctrl_in_valid_firewall;
reg		[1:0]	ctrl_opt_uniman,ctrl_opt_firewall;
reg		[31:0]	ctrl_addr_uniman,ctrl_addr_firewall;
reg		[31:0]	ctrl_data_in_uniman,ctrl_data_in_firewall;
wire			ctrl_out_valid_uniman,ctrl_out_valid_firewall;
wire	[31:0]	ctrl_data_out_uniman,ctrl_data_out_firewall;	


/*	from conn_searcher and connection_outTime to builtIn_event_gen;
*/

/*	from conn_table_configuration to conn_outTime_inspector;
*	the priority of aging is lower than configuration;
*/


/*************************************************************************************/
/*	submodular declaration
*	parser used to identify packet's protocols and extract 4-tuple info, and
*		tcp flags;
*/

parser_L4 parser(
.clk(clk),
.reset(reset),
.metadata_in_valid(cdp2um_data_valid),
.metadata_in(cdp2um_data),
.metadata_out_valid(meta_valid_parser),
.metadata_out(meta_parser),
.confInfo_valid(confInfo_valid),
.confInfo(confInfo),
.ready(ready)
);

/*************************************************************************************/
/*	uniMon used to maintain tcp flow's state
*/
uniman_top uniman(
.clk(clk),
.reset(reset),
.pkt_in_valid(meta_valid_parser),
.pkt_in(meta_parser),
.pkt_out_valid(meta_valid_unimon),
.pkt_out(meta_unimon),
.ready(ready),
.ctrl_in_valid(ctrl_in_valid_uniman),
.ctrl_opt(ctrl_opt_uniman),
.ctrl_addr(ctrl_addr_uniman),
.ctrl_data_in(ctrl_data_in_uniman),
.ctrl_out_valid(ctrl_out_valid_uniman),
.ctrl_data_out(ctrl_data_out_uniman)
);

/*************************************************************************************/
/*	configuration used to configure uinmon
*/
always @(posedge clk or negedge reset) begin
	if(!reset) begin
		ctrl_in_valid_firewall <= 1'b0;
		ctrl_in_valid_uniman <= 1'b0;
		ctrl_data_in_firewall <= 32'b0;
		ctrl_data_in_uniman <= 32'b0;
		ctrl_opt_firewall <= 2'b0;
		ctrl_opt_uniman <= 2'b0;
		ctrl_addr_firewall <= 32'b0;
		ctrl_addr_uniman <= 32'b0;	
	end
	else begin
		if(confInfo_valid == 1'b1) begin
			if(confInfo[63:62] == 2'b0) begin
				ctrl_in_valid_uniman <= 1'b1;
				{ctrl_addr_uniman,ctrl_data_in_uniman} <= confInfo;
				ctrl_opt_uniman <= 2'd1;
				ctrl_in_valid_firewall <= 1'b0;
			end
			else begin
				ctrl_in_valid_firewall <= 1'b1;
				ctrl_in_valid_uniman <= 1'b0;
				{ctrl_addr_firewall,ctrl_data_in_firewall} <= confInfo;
				ctrl_opt_firewall <= 2'd1;
			end
		end
		else begin
			ctrl_in_valid_firewall <= 1'b0;
			ctrl_in_valid_uniman <= 1'b0;
		end
	end
end



firewall firewall(
.clk(clk),
.reset(reset),
.metadata_in_valid(meta_valid_unimon),
.metadata_in(meta_unimon),
.metadata_out_valid(meta_valid_firewall),
.metadata_out(meta_firewall),
.ctrl_in_valid(ctrl_in_valid_firewall),
.ctrl_opt(ctrl_opt_firewall),
.ctrl_addr(ctrl_addr_firewall),
.ctrl_data_in(ctrl_data_in_firewall),
.ctrl_out_valid(ctrl_out_valid_firewall),
.ctrl_data_out(ctrl_data_out_firewall)
);

/*************************************************************************************/
/*	transmition used to trans packet
*/
transmition trans(
.clk(clk),
.reset(reset),
.metadata_in_valid(meta_valid_firewall),
.metadata_in(meta_firewall),
.metadata_out_valid(um2cdp_data_valid),
.metadata_out(um2cdp_data),
.um2cdp_rule_wrreq(um2cdp_rule_wrreq),
.um2cdp_rule(um2cdp_rule),
.cdp2um_rule_usedw(cdp2um_rule_usedw),
.cdp2um_tx_enable(cdp2um_tx_enable)
);

	
/*************************************************************************************/
/*	state machine declaration
*	this state machine used to gen um2cdp_tx_enable;
*/
reg	state;

always @(posedge clk or negedge reset) begin
	if (!reset) begin
		um2cdp_path <= 1'b0;
		localbus_ack_n <= 1'b1;
		localbus_data_out <= 32'b0;
		state <= 1'b0;
		um2cdp_tx_enable <= 1'b0;
	end
	else begin
		case(state)
			1'b0: begin
				if(cdp2um_data_valid == 1'b0) begin
					state <= 1'b1;
					um2cdp_tx_enable <= 1'b1;
				end
				else begin
					state <= 1'b0;
					um2cdp_tx_enable <= 1'b0;
				end
			end
			1'b1: begin
				if(cdp2um_data_valid == 1'b1) begin
					state <= 1'b0;
					um2cdp_tx_enable <= 1'b0;
				end
				else begin
					state <= 1'b1;
					um2cdp_tx_enable <= 1'b1;
				end
			end
			default: state <= 1'b0;
		endcase
	end
end

endmodule    
