import numpy
import re
from paramIni import *


def bolt_initial(fl_w,name_boltTemp,parseGraph_temp):
	
	fl_bolt_tag = open ('./tag/bolt_template_tag.txt')

	name_boltTemp_tag = []
	value_boltTemp_tag = []
	name_boltIndex_tag = []
	name_boltPre_tag = []
	tag = 0;
	for line in fl_bolt_tag:
		lineList_bolt = line.strip().split(' ')
		if lineList_bolt[-1]=='name_boltTemp_tag':
			tag =1
		if lineList_bolt[-1]=='value_boltTemp_tag':
			tag = 2
		if lineList_bolt[-1]=='name_boltIndex_tag':
			tag = 3
		if lineList_bolt[-1]=='name_boltPre_tag':
			tag = 4
		if lineList_bolt[-1]=='//':
			tag = 0

		if lineList_bolt[0] == '//':
			continue
		elif tag == 1:
			for str_bolt in lineList_bolt:
				name_boltTemp_tag.append(str_bolt)
		elif tag == 2:
			for str_bolt in lineList_bolt:
				value_boltTemp_tag.append(str_bolt)
		elif tag == 3:
			for str_bolt in lineList_bolt:
				name_boltIndex_tag.append(str_bolt)
		elif tag == 4:
			for str_bolt in lineList_bolt:
				name_boltPre_tag.append(str_bolt)

	for num_bolt in range(len(name_boltTemp)):
		print(num_bolt)
		fl_bolt = open ('./template/bolt_template.v')
		parseGraph = parseGraph_temp[num_bolt]
		numPre = str(len(parseGraph))

		value_boltTemp_tag_temp = []
		for num_1 in range(len(value_boltTemp_tag)):
			value_boltTemp_tag_temp.append(value_boltTemp_tag[num_1].replace('index_tag',parseGraph[0])) # first
			if len(parseGraph) > 1 :	# the reast
				for num_2 in range(len(parseGraph)-1):
					value_boltTemp_tag_temp[num_1] = value_boltTemp_tag_temp[num_1] + ',' + value_boltTemp_tag[num_1].replace('index_tag',parseGraph[num_2+1])
			

		#replace
		for line in fl_bolt:
			line = line.replace('name_tag',name_boltTemp[num_bolt])
			line = line.replace(name_boltIndex_tag[0],str(num_bolt+1)).replace(name_boltPre_tag[0],numPre)
			for name_bolt_tag in name_boltTemp_tag:
				line = line.replace(name_bolt_tag,value_boltTemp_tag_temp[name_boltTemp_tag.index(name_bolt_tag)])
			fl_w.write(line)
		fl_w.write('\n')
		fl_bolt.close()
	fl_bolt_tag.close()



			

def parserTemplate_initial(fl_w,name_parserTemp,value_parserID,value_boltPre,name_parserTemp_param,value_parserTemp_param):
	for num in range(len(name_parserTemp)):
		fl_parser = open('./template/parser_template.v')
		for line_parser in fl_parser:

			line_parser = line_parser.replace('name_tag',name_parserTemp[num])
			line_parser = line_parser.replace('index_bolt_tag',value_boltPre[num])
			line_parser = line_parser.replace('index_tag',value_parserID[num])
			for param_tag in name_parserTemp_param:
				line_parser = line_parser.replace(param_tag,value_parserTemp_param[num][name_parserTemp_param.index(param_tag)])
			fl_w.write(line_parser)
		fl_w.write('\n\n')
		fl_parser.close()



	
#paramate
name_parserTop_param=[]
value_parserTop_param=[]
name_parserTemp=[]
value_parserID=[]
value_boltPre = []
name_boltTemp=[]
value_boltTemp=[]
name_parserTemp_param =[]
value_parserTemp_param=[]
parseGraph = []




name_parserTop_param, value_parserTop_param,name_parserTemp,value_parserID,value_boltPre,name_boltTemp,value_boltTemp,name_parserTemp_param,value_parserTemp_param,parseGraph=param_ini()
#print (name_parserTop_param)
#print (value_parserTop_param)

filename = './template/parser_top_template.v'
fl_w = open('./code_parser/parserTop_vxlan.v','w')
tag_module = 0
tag_param = 0
i=0
with  open(filename) as fl_parserTop:
	for line in fl_parserTop:
		lineList_parserTop =line.strip().split(' ')
		if lineList_parserTop[-1] == 'parameter_ini_begin':
			tag_param =1
		elif lineList_parserTop[-1] == 'parameter_ini_begin':
			tag_param =0
		if lineList_parserTop[-1] == 'module_begin':
			tag_module = 1
		else:
			tag_module = 0
		# initial parameter
		if tag_param == 1:
			for idx in range(len(value_parserTop_param)):
				line = line.replace(name_parserTop_param[idx],value_parserTop_param[idx])
		fl_w.write(line)
		# initial bolt
		if tag_module == 1:
			bolt_initial(fl_w,name_boltTemp,parseGraph)
			#for num in range(len(name_boltTemp)):
			#	bolt_initial(fl_w,name_boltTemp[num],str(num+1),parseGraph[num])
		# initial template
		if tag_module == 1:
			tag_module =0
			parserTemplate_initial(fl_w,name_parserTemp,value_parserID,value_boltPre,name_parserTemp_param,value_parserTemp_param)	# parser_template
fl_w.close()