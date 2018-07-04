import numpy
import re
import sys
from common import *


def frontCompiling():
	# '1' means printing the test info.
	printTest = 1

	fp_script = open('./includes/headers.p4','r')

	# header_field is a list, used to record each field's info, i.e., item_headerField;
	# header_info is a dict, includes {'name', 'length', 'fields'}, and 'fields', i.e., header_field;
	# headers is a list, used to record header_info;
	header_field = []
	header_info = {}
	headers = []

	'''
	# para_extract is a dict, includes {"$nameOfNode": $field_extract}
	# field_extract is a list, e.g., [{'field_name': x, 'regList': [], 'bitStartList': []},...]
	para_extract = {}headers
	field_extract = []
	'''
	reg_idx = 0

	# readHead_valid is a tag, '1' represent starting to read header format;
	# length_extractField is the length of fields needed to extract;
	# length_header is the length of each header;
	readHead_valid = 0
	length_extractField = 0
	length_header = 0

	# read headers.p4 to learn the format of headers
	lineList = fp_script.readlines()
	for idx in range(len(lineList)):
		itemList = lineList[idx].strip().split(' ')
		# end of  read header field
		if itemList[-1] == '}':
			readHead_valid = 0
			header_info['fields'] = header_field
			header_info['length'] = length_header
			headers.append(header_info)
			header_info = {}

		# start to read header filed
		if readHead_valid == 1:
			item_headerField = {}
			item_headerField['fieldName'] = itemList[0]
			item_headerField['length'] = int(itemList[2][0:-1])
			item_headerField['bStart'] = length_header
			if (len(itemList)) == 4:
				item_headerField['tag'] = reg_idx
				reg_idx += item_headerField['length']/8
				length_extractField += int(itemList[2][0:-1])
			header_field.append(item_headerField)
			length_header += item_headerField['length']

		# record the header type name
		if itemList[0] == 'header_type':
			header_info['name'] = itemList[1]
			readHead_valid = 1
			header_field = []
			length_header = 0


	#read parser.p4 to learn the process flow of prasing
	fp_script = open('./includes/l2parser.p4','r')

	# nodeDict is a dict, includes all "header" definitions, e.g., header ethernet_t ehternet;
	# firstNode is the first node of parserTrie, e.g., ehternet;
	# curNode is a point;
	# readHeader_valid is a tag, '1' represents to read "extract (type)", '2' represents to read
	#	each case, e.g. 0x0800 : ipv4;
	nodeDict = {}
	firstNode = None
	curNode = None
	readHead_valid = 0

	lineList = fp_script.readlines()
	for idx in range(len(lineList)):
		itemList = lineList[idx].strip().split(' ')
		# end of parser node
		if itemList[-1] == '}':
			readHead_valid = 0

		if readHead_valid == 2:
			if itemList[0] == 'default':
				if itemList[2][0:-1] == 'end':
					readHead_valid = 0
				else:
					readHead_valid = 0
			else:
				# add a son/bro relationship between two nodes;
				if curNode.son_node == None:
					curNode.son_node = nodeDict[itemList[2][0:-1]]
					nodeDict[itemList[2][0:-1]].par_node = curNode
				else:
					nodeDict[itemList[2][0:-1]].bro_onde = curNode.son_node
					curNode.son_node = nodeDict[itemList[2][0:-1]]
					nodeDict[itemList[2][0:-1]].par_node = curNode
				curNode.son_node.condition_value = itemList[0][2:]

		# start to read parser node
		if readHead_valid == 1:
			if itemList[0][0:-1] == 'end':
				readHead_valid = 0
			else:
				readHead_valid = 2
				curNode.condition_field = itemList[1][1:-2]

		# record the header type name
		if itemList[0] == 'parser':
			readHead_valid = 1
			curNode = nodeDict[itemList[1]]

		# create parserNode
		if itemList[0] == 'header':
			for each_item in headers:
				if itemList[1] == each_item['name']:
					# initial node, and append to nodeDict;
					nodeDict[itemList[2][0:-1]] = parserNode( itemList[2][0:-1],\
						each_item['fields'], each_item['length'])
				if firstNode == None:
					firstNode = nodeDict[itemList[2][0:-1]]

	if printTest:		
		for node_name, node in nodeDict.items():
			print node_name
			if node.son_node != None:
				print ('%s->%s'%(node_name, node.son_node.name))
			if node.bro_node != None:
				print ('%s-->%s'%(node_name, node.bro_node.name))
			
			#print node.header_field

	# WFS (width-first search) used to calculate the max length of pkt's header needed to parser;
	nodeToSearch = [firstNode]
	# initialization of firstNode
	firstNode.max_length = firstNode.length
	firstNode.header_bit_start = 0

	condition_field = firstNode.condition_field
	if condition_field =='':
		pass
	else:
		item_condition = search_headerField_by_name(condition_field,\
			firstNode.header_field)

	firstNode.condition_field_bit_start = item_condition['bStart']
	firstNode.condition_field_bit_end = item_condition['bStart'] + \
		item_condition['length']

	# begin to search parserTrie, add the son node to nodeToSearch;
	while nodeToSearch:
		each_node = nodeToSearch[0]
		#del current node from nodeToSearch list
		nodeToSearch.remove(each_node)
		if each_node.son_node == None:
			pass
		else:
			nodeToSearch.append(each_node.son_node)
			curNode = each_node.son_node
			curNode.header_bit_start = each_node.header_bit_start + \
				each_node.length
			if curNode.condition_field != '':
				item_condition = search_headerField_by_name(curNode.condition_field,\
					curNode.header_field)
			else:
				# fake condition, i.e., the last field to assure parsing completedly
				item_condition = curNode.header_field[-1]
			curNode.condition_field_bit_start = item_condition['bStart'] + \
				each_node.max_length
			curNode.condition_field_bit_end = item_condition['bStart'] +\
				item_condition['length']+ each_node.max_length
			check_bit_start_end(curNode.condition_field_bit_start, \
				curNode.condition_field_bit_end, 0)
			

			curNode.max_length = each_node.max_length + each_node.son_node.length

	#calculate the maximun length
	max_length = 0
	for node_name, each_node in nodeDict.items():
		if max_length < each_node.max_length:
			max_length = each_node.max_length

	if printTest:
		print ('max_length: %d'%(max_length))

	# initialise para_define
	para_define ={}
	para_define['NUM_OF_META_TOFILL'] = (length_extractField+127)/128
	para_define['NUM_OF_REG_TOFILL'] = para_define['NUM_OF_META_TOFILL'] *16
	para_define['READY_COUNT_TOFILL'] = para_define['NUM_OF_META_TOFILL']+1

	if printTest:
		print para_define

	# initialise para_proto_name
	para_proto_name = []
	for node_name, each_node in nodeDict.items():
		para_proto_name.append(node_name.upper()+'_P')
	para_proto_name.append('OTHER_P')

	if printTest:
		print para_proto_name

	#initialise protoType_in_pkt_...
	protoType_in_pkt_1 = {}
	protoType_in_pkt_2 = {}
	protoType_in_pkt_3 = {}
	protoType_in_pkt_4 = {}

	# assignProto initilization
	# to calculate the cases in each clk, i.e., case(state_parser)
	for idx in range((max_length+127)/128):
		assignProto = []
		for node_name, each_node in nodeDict.items():
			bit_start = each_node.condition_field_bit_start
			bit_end = each_node.condition_field_bit_end
			if bit_start/128 == idx:
				item_case = {}
				item_case['name'] = node_name.upper()+'_P'

				# subProto_list initilization
				item_case_subProto = []
				item_case['subProto_list'] = item_case_subProto
				if each_node.son_node:
					# append the son node
					curNode = each_node.son_node
					item_subProto ={}
					item_subProto['condition'] = set_condition(\
						bit_start, bit_end, curNode.condition_value)
					item_subProto['nextProto'] = curNode.name.upper()+'_P'
					item_subProto['nextState'] = \
						'READ_PKT_%d_S'%(idx+2)
					item_case_subProto.append(item_subProto)
					# append the bro node
					while curNode.bro_node:
						curNode = curNode.bro_node
						item_subProto ={}
						item_subProto['condition'] = set_condition(\
							bit_start, bit_end, curNode.condition_value)
						item_subProto['nextProto'] = curNode.name.upper()+\
							'_P'
						item_subProto['nextState'] = \
							'READ_PKT_%d_S'%(idx+2)
						item_case_subProto.append(item_subProto)
				else:
					item_subProto ={}
					item_subProto['condition'] = '1'
					item_subProto['nextProto'] = 'OTHER_P'
					item_subProto['nextState'] = 'READ_PKT_TAIL_S'
					item_case_subProto.append(item_subProto)
				
				# add  else case
				item_subProto = {}
				item_subProto['nextProto'] = 'OTHER_P'
				item_subProto['nextState'] = 'READ_PKT_TAIL_S'
				item_case_subProto.append(item_subProto)

				assignProto.append(item_case)


		if idx == 0:
			protoType_in_pkt_1['assignProto'] = assignProto
		elif idx == 1:
			protoType_in_pkt_2['assignProto'] = assignProto
		elif idx == 2:
			protoType_in_pkt_3['assignProto'] = assignProto
		elif idx == 3:
			protoType_in_pkt_4['assignProto'] = assignProto

	# assignReg initilization
	# to calculate the cases in each clk, i.e., case(state_parser)
	for idx in range((max_length+127)/128):
		assignReg = []
		for node_name, each_node in nodeDict.items():
			bit_header_start = each_node.header_bit_start
			bit_header_end = each_node.max_length + each_node.header_bit_start
			if bit_header_end <= (idx*128):
				continue
			item_case = {}
			item_case['name'] = node_name.upper()+'_P'
			item_case['regInfo'] = []
			for each_field in each_node.header_field:
				if (each_field.has_key('tag')) and \
	((each_field['bStart'] + each_node.header_bit_start) < (idx*128+128)) and\
	((each_field['bStart'] + each_field['length'] + each_node.header_bit_start) > (idx*128)):
					overReg_front = max(0, idx*128-(each_field['bStart'] + \
						each_node.header_bit_start))/8
					overReg_end = max(0, each_field['bStart']+each_field['length']+\
						each_node.header_bit_start - 128*idx-128)/8
					num_reg = each_field['length']/8 - overReg_front - overReg_end

					item_reg = {}
					item_reg['array'] = []
					for idx_reg in range(num_reg):
						item_reg['array'].append(idx_reg +each_field['tag']+\
							overReg_front)
					item_reg['b_start_reg'] = min(127, 127+128*idx - \
						each_field['bStart']-each_node.header_bit_start)
					item_reg['b_end_reg'] = item_reg['b_start_reg'] + 1 -\
						num_reg*8
					item_case['regInfo'].append(item_reg)
			if each_node.par_node:
				curNode = each_node.par_node
				for each_field in curNode.header_field:
					if (each_field.has_key('tag')) and \
	((each_field['bStart'] + curNode.header_bit_start) < (idx*128+128)) and \
	((each_field['bStart'] + each_field['length'] + curNode.header_bit_start) > (idx*128)):
						overReg_front = max(0, idx*128-(each_field['bStart'] + \
							curNode.header_bit_start))/8
						overReg_end = max(0, each_field['bStart']+each_field['length']+\
							curNode.header_bit_start - 128*idx-128)/8
						num_reg = each_field['length']/8 - overReg_front - overReg_end

						item_reg = {}
						item_reg['array'] = []
						for idx_reg in range(num_reg):
							item_reg['array'].append(idx_reg +each_field['tag']+\
								overReg_front)
						item_reg['b_start_reg'] = min(127, 127+128*idx - \
							each_field['bStart']-curNode.header_bit_start)
						item_reg['b_end_reg'] = item_reg['b_start_reg'] + 1 -\
							num_reg*8
						item_case['regInfo'].append(item_reg)
			if each_node.son_node:
				curNode = each_node.son_node
				for each_field in curNode.header_field:
					if (each_field.has_key('tag')) and \
	((each_field['bStart'] + curNode.header_bit_start) < (idx*128+128))and \
	((each_field['bStart'] + each_field['length'] + curNode.header_bit_start) > (idx*128)):
						overReg_front = max(0, idx*128-(each_field['bStart'] + \
							curNode.header_bit_start))/8
						overReg_end = max(0, each_field['bStart']+each_field['length']+\
							curNode.header_bit_start - 128*idx-128)/8
						num_reg = each_field['length']/8 - overReg_front - overReg_end

						item_reg = {}
						item_reg['array'] = []
						for idx_reg in range(num_reg):
							item_reg['array'].append(idx_reg +each_field['tag']+\
								overReg_front)
						item_reg['b_start_reg'] = min(127, 127+128*idx - \
							each_field['bStart']-curNode.header_bit_start)
						item_reg['b_end_reg'] = item_reg['b_start_reg'] + 1 -\
							num_reg*8
						item_case['regInfo'].append(item_reg)
				while curNode.bro_node:
					curNode = each_node.bro_node
					for each_field in curNode.header_field:
						if (each_field.has_key('tag'))and \
	((each_field['bStart'] + curNode.header_bit_start) < (idx*128+128)) and\
	((each_field['bStart'] + each_field['length'] + curNode.header_bit_start) > (idx*128)):
							overReg_front = max(0, idx*128-(each_field['bStart'] + \
								curNode.header_bit_start))/8
							overReg_end = max(0, each_field['bStart'] + \
	each_field['length'] + curNode.header_bit_start - 128*idx-128)/8
							num_reg = each_field['length']/8 - overReg_front - overReg_end

							item_reg = {}
							item_reg['array'] = []
							for idx_reg in range(num_reg):
								item_reg['array'].append(idx_reg +each_field['tag']+\
									overReg_front)
							item_reg['b_start_reg'] = min(127, 127+128*idx - \
								each_field['bStart']-curNode.header_bit_start)
							item_reg['b_end_reg'] = item_reg['b_start_reg'] + 1 -\
								num_reg*8
							item_case['regInfo'].append(item_reg)
			if item_case['regInfo'] == []:
				pass
			else:
				assignReg.append(item_case)

		if idx == 0:
			protoType_in_pkt_1['assignReg'] = assignReg
		elif idx == 1:
			protoType_in_pkt_2['assignReg'] = assignReg
		elif idx == 2:
			protoType_in_pkt_3['assignReg'] = assignReg
		elif idx == 3:
			protoType_in_pkt_4['assignReg'] = assignReg

	return para_define, para_proto_name, protoType_in_pkt_1, protoType_in_pkt_2, protoType_in_pkt_3, \
		protoType_in_pkt_4