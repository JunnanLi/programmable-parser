header ethernet_t ethernet;
header ipv4_t ipv4;
header tcp_t tcp;

parser ethernet {
	extract (etherType):
		0x0800 : ipv4;
		default : end;
}

parser ipv4 {
	extract (protocol):
		0x06 : tcp;
		default : end;
}

parser tcp {
	end;
}