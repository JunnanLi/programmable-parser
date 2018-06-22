import numpy
import re
import sys

fp_script = open('./includes/headers.p4','r')

headers = []
header_info = {}
header_field = []

readHead_valid = 0
length_extractField = 0

# read headers.p4
lineList = fp_script.readlines()
for idx in range(len(lineList)):
	itemList = lineList[idx].strip().split(' ')
	# end of  read header field
	if itemList[-1] == '}':
		readHead_valid = 0
		header_info['fields'] = header_field
		headers.append(header_info)
		header_info = {}

	# start to read header filed
	if readHead_valid == 1:
		item_headerField = {}
		item_headerField['fieldName'] = itemList[0]
		item_headerField['length'] = itemList[2][0:-1]
		if (len(itemList)) == 4:
			item_headerField['tag'] = 1
			length_extractField += int(itemList[2][0:-1])
		header_field.append(item_headerField)

	# record the header type name
	if itemList[0] == 'header_type':
		header_info['name'] = itemList[1]
		readHead_valid = 1
		header_field = []


#parsing process
fp_script = open('./includes/l2parser.p4','r')
lineList = fp_script.readlines()
for idx in range(len(lineList)):
	itemList = lineList[idx].strip().split(' ')
	# end of  read header field
	if itemList[-1] == '}':
		readHead_valid = 0

	# start to read header filed
	if readHead_valid == 1:
		item_headerField = {}
		item_headerField['fieldName'] = itemList[0]
		item_headerField['length'] = itemList[2][0:-1]
		if (len(itemList)) == 4:
			item_headerField['tag'] = 1
			length_extractField += int(itemList[2][0:-1])

	# record the header type name
	if itemList[0] == 'parser':
		header_info['name'] = itemList[1]
		readHead_valid = 1



# initialise para_define
para_define ={}

para_define['NUM_OF_REG_TOFILL'] = length_extractField/8
para_define['NUM_OF_META_TOFILL'] = (length_extractField+127)/128
para_define['READY_COUNT_TOFILL'] = max(para_define['NUM_OF_META_TOFILL'], 0)

print para_define

'''
fp_para = open('./conf/parameter.txt','r')
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
#print(line_list)