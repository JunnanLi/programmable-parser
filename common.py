import numpy
import re
import sys


class parserNode(object):
	"""docstring for parserNode
	name: the header's name;
	header_field: list of headers (headers is a dicr, includes{fieldName, length, tag})
	length: the header's length;
	condition_field: field of type/protocol;
	condition_value: the value of pre type/protocol, which represent current protocol;
	son_node:
	bro_node:
	max_length: the maximun length in packet header;
	"""
	def __init__(self, name, header_field, length):
		self.name = name
		self.header_field = header_field
		self.length = length
		self.condition_field = ''
		self.header_bit_start = 0
		self.condition_field_bit_start = 0
		self.condition_field_bit_end = 0
		self.condition_value = ''
		self.son_node = None
		self.par_node = None
		self.bro_node = None
		self.max_length = 0
		

def check_bit_start_end(bit_start, bit_end, firstNode_tag):
	print bit_start
	print bit_end
	if (bit_start/128) != (bit_end/128):
		print ('type is cross two packet!')
		sys.exit()
	else:
		if firstNode_tag:
			if (bit_start/128) != 0:
				print ('currently do only support parsing start \
					from ehternet!')
				sys.exit()	


def set_condition(b_start, b_end, field_value):
	b_start = 128 - (b_start - b_start/128 *128)
	b_end = 128 - (b_end - b_end/128 *128)
	conditon = 'metadata_in[%d:%d] == %d\'h%s'%(b_start-1, b_end, \
		(b_start-b_end), field_value)
	return conditon

def search_headerField_by_name(field_name, header_field):
	for each_item in header_field:
		if field_name == each_item['fieldName']:
			return each_item
	print 'do not find field in header_field!'
	sys.exit()