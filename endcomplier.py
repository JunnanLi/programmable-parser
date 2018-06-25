import numpy
import re
from insertion_assignment import *

#fp_para = open('./conf/parameter.txt','wr')
fp_temp = open('parser_template.v', 'r')
fp_inst = open('parser_instance_1.v', 'w')

'''
fp_para = open('./conf/parameter.txt','r')
para_define = {}
line = fp_para.readline()
line = fp_para.readline()
while line != '':
	line = line[0:len(line)-1]
	lineList_temp = line.strip().split(' ')
	if len(lineList_temp) != 2:
		print 'error of parameter initialization!'
		sys.exit()
	para_define[lineList_temp[0]] = int(lineList_temp[1])
	line = fp_para.readline()
print para_define
'''

# get parameter from fp_para is on the way...
para_define = {'NUM_OF_REG_TOFILL': 32, 'NUM_OF_META_TOFILL': 3, 'READY_COUNT_TOFILL': 4}
para_proto_name = ['IDLE_P', 'ARP_P', 'IP_P', 'TCP_P', 'OTHER_P']
protoType_in_pkt_1 = [{'name': 'IDLE_P', 'regInfo':\
#metaReg list:
	[{'array': [0,1,2,3,4,5], 'b_start_reg': 127, 'b_end_reg': 80}, \
	{'array': [6,7,8,9,10,11], 'b_start_reg': 79, 'b_end_reg': 32}], \
	'subProto_list': \
# sub protocol list:
# 	list-> dirt -> ('regInfo' has) list -> dirt -> ('array' has) list 
# 	e.g.,
# 	metaReg[0]...metaReg[5] <= metadata_in[b_start_reg:b_end_reg]
# 	...
# 	if(metadata_in[b_start: b_end] == value) begin
# 		protocol_type <= nextProto; 
# 		state_parser <= REAR_PKT_2_S;
# 	end
# 	else if(...) end
# 		...
# 	end
# 	...
# 	else begin
# 		...
# 	end
	[{'condition': 'metadata_in[31:16] == 16\'h0800', 'nextProto': 'IP_P', 'nextState': 'READ_PKT_2_S'},\
	{'nextProto': 'ARP_P', 'nextState': 'READ_PKT_TAIL_S'}
]}]


protoType_in_pkt_2 = [{'name': 'IP_P', 'regInfo':\
#metaReg list:
	[{'array': [16], 'b_start_reg': 71, 'b_end_reg': 64}, \
	{'array': [17,18,19,20], 'b_start_reg': 47, 'b_end_reg': 16},\
	{'array': [21,22], 'b_start_reg': 15, 'b_end_reg': 0}],\
	'subProto_list': \
# sub protocol list:
	[{'condition': 'metadata_in[71:64] == 8\'h06', 'nextProto': 'TCP_P', 'nextState': 'READ_PKT_3_S'},\
	{'nextProto': 'OTHER_P', 'nextState': 'READ_PKT_TAIL_S'}
]}]

protoType_in_pkt_3 = [{'name': 'TCP_P', 'regInfo': \
#metaReg list:
	[{'array': [23,24], 'b_start_reg': 127, 'b_end_reg': 112}, \
	{'array': [25,26], 'b_start_reg': 111, 'b_end_reg': 96},\
	{'array': [27,28], 'b_start_reg': 95, 'b_end_reg': 80},\
	{'array': [29], 'b_start_reg': 7, 'b_end_reg': 0}],\
	'subProto_list': \
# sub protocol list:
	[{'condition': '1', 'nextProto': 'TCP_P', 'nextState': 'READ_PKT_TAIL_S'},\
	{'nextProto': 'OTHER_P', 'nextState': 'READ_PKT_TAIL_S'}
]}]

for line in fp_temp:
	line = line.replace('NUM_OF_REG_TOFILL', str(para_define['NUM_OF_REG_TOFILL']))
	line = line.replace('NUM_OF_META_TOFILL', str(para_define['NUM_OF_META_TOFILL']))
	line = line.replace('READY_COUNT_TOFILL', str(para_define['READY_COUNT_TOFILL']))
	fp_inst.write(line)
	
	lineList_temp = line.strip().split(' ')
	# define the parameter of protocol needed to parser
	if lineList_temp[0] == '/***Protocol_definition_toInsert*/' :
		fp_inst.write('parameter')
		for index in range(len(para_proto_name)):
			fp_inst.write('\n\t\t%s\t= 4\'d%d'%(para_proto_name[index], index))
			if(index == len(para_proto_name)-1):
				fp_inst.write(';\n')
			else:
				fp_inst.write(',')
	# assign metaReg from packet
	elif  lineList_temp[0] == '/***assign_reg_from_pkt_0*/' :
		insert_type = 2
	elif  lineList_temp[0] == '/***assign_reg_from_pkt_1*/' :
		#inser metaReg assignment
		insert_metaReg(fp_inst, protoType_in_pkt_1)	
	elif  lineList_temp[0] == '/***assign_reg_from_pkt_2*/' :
		#inser metaReg assignment
		insert_metaReg(fp_inst, protoType_in_pkt_2)
	elif  lineList_temp[0] == '/***assign_reg_from_pkt_3*/' :
		#inser metaReg assignment
		insert_metaReg(fp_inst, protoType_in_pkt_3)
	elif  lineList_temp[0] == '/***assign_reg_from_pkt_4*/' :
		insert_type = 6
	elif  lineList_temp[0] == '/***assign_reg_from_pkt_5*/' :
		insert_type = 7
	elif  lineList_temp[0] == '/***assign_reg_from_pkt_6*/' :
		insert_type = 8
	elif  lineList_temp[0] == '/***assign_reg_from_pkt_7*/' :
		insert_type = 9
	elif  lineList_temp[0] == '/***assign_metadata_temp*/' :
		#insert metadata_temp assignment
		insert_metaTemp(fp_inst, para_define)
	else:
		insert_type = 0



fp_temp.close()
#fp_para.close()
fp_inst.close()