header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;

parser ethernet_t {
	extract(etherType):
		0x0800 : ipv4_t;
		default : return;
}

parser ipv4_t {
	extract(protocol)
		0x06 : tcp_t;
		default : return ;
}

parser tcp_t {
	end
}