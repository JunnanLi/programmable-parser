header_type ethernet_t {
dstAddr : 48; extract
srcAddr : 48; extract
etherType : 16;
}

header_type ipv4_t {
version_ihl : 8;
diffserv : 8;
totalLen : 16;
identification : 16;
flags_info : 16;
ttl : 8;
protocol : 8; extract
hdrChecksum : 16;
srcAddr : 32; extract
dstAddr: 32; extract
}

header_type tcp_t {
srcPort : 16; extract
dstPort : 16; extract
seqNo : 32; extract
ackNo : 32;
dataOffset : 8;
ctrl : 8; extract
window : 16;
checksum : 16;
urgentPtr : 16;
}
