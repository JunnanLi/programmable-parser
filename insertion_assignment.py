import numpy
import re

# string definition
string_caseStart = 'case(protocol_type)\n'
string_caseDefault = '\tdefault: begin\n\t\treg_tag <= ~reg_tag;\n\t\tstate_parser <= READ_PKT_TAIL\
_S;\n\tend\nendcase\n'

# function used to insert metaReg assignment
def insert_metaReg(fp_inst, protoType_in_pkt):
	#e.g., write 'case(protocol_type)'
	fp_inst.write(string_caseStart)

	# item represents each case in protocol_type
	for item in protoType_in_pkt:
		# e.g.,write "IDLE: begin"
		fp_inst.write('\t%s: begin\n'%(item['name']))

		# subProto represents the next protocols generated from parent protocol_type
		# the format of subProto in FPGA should be:
		#	if(condition_1) ...
		#	else if(conditon_2) ...
		#	else ...
		subProto_listInItem = item['subProto_list']
		for item_subProto  in subProto_listInItem:
			#next protocol, e.g., write "if(metadata[x:y] == 0x0800) begin"
			#write "if..."
			if item_subProto == subProto_listInItem[0]:
				fp_inst.write('\t\tif(%s) begin\n'%(item_subProto['condition']))
			#wreite "else..."
			elif item_subProto ==subProto_listInItem[-1]:
				fp_inst.write('\t\telse begin\n')
			#wriete"else if"
			else:
				fp_inst.write('\t\telse if(%s) begin\n'%(item_subProto['condition']))
			#next protocol, e.g., write "protocol_type <= IP_P"
			fp_inst.write('\t\t\tprotocol_type <= %s;\n'%(item_subProto['nextProto']))

			#next state, e.g., state_parser <= READ_PKT_2_S
			if item_subProto['nextState'] == 'READ_PKT_TAIL_S':
				fp_inst.write('\t\t\treg_tag <= ~reg_tag;\n')
			fp_inst.write('\t\t\tstate_parser <= %s;\n' %(item_subProto['nextState']))

			#assign metaReg, e.g., {metaReg[1]} <= metadata[x:y]
			# check whether need to assign metaReg
			if(item_subProto.has_key('regInfo')):
				for field in item_subProto['regInfo']:
					# assign metaReg
					fp_inst.write('\t\t\t{')
					for reg in field['array']:
						regList = field['array']
						if reg == regList[-1]:
							fp_inst.write('metaReg[%d]}' % (reg))
						else:
							fp_inst.write('metaReg[%d],' % (reg))
					fp_inst.write('<= metadata_in[%d:%d];\n'% (field['b_start_reg'],
						field['b_end_reg']))
			# write end of if (subProto)
			fp_inst.write('\t\tend\n')
		#write end of each case
		fp_inst.write('\tend\n')
	#write default case and endcase
	fp_inst.write(string_caseDefault)


# insert metadata_temp assignment
def insert_metaTemp(fp_inst,para_define):
	for idx_meta in range(para_define['NUM_OF_META_TOFILL'] - 1):
		if idx_meta == para_define['NUM_OF_META_TOFILL']- 2:
			fp_inst.write('metadata_temp[%d] <= {2\'b00,4\'b0'%(idx_meta+1))
		else:
			fp_inst.write('metadata_temp[%d] <= {2\'b11,4\'b0'%(idx_meta+1))
		baseAddr = 16*idx_meta;
		for idx_reg in range(16):
			fp_inst.write(',metaReg[%d]'%(idx_reg+baseAddr))
		fp_inst.write('};\n')

