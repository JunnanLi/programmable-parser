library verilog;
use verilog.vl_types.all;
entity parser is
    generic(
        IDLE_P          : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi0, Hi0);
        ARP_P           : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi0, Hi1);
        IP_P            : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi1, Hi0);
        TCP_P           : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi1, Hi1);
        OTHER_P         : vl_logic_vector(0 to 3) := (Hi0, Hi1, Hi0, Hi0);
        IDLE_S          : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi0, Hi0);
        READ_PKT_1_S    : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi0, Hi1);
        READ_PKT_2_S    : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi1, Hi0);
        READ_PKT_3_S    : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi1, Hi1);
        READ_PKT_4_S    : vl_logic_vector(0 to 3) := (Hi0, Hi1, Hi0, Hi0);
        READ_PKT_5_S    : vl_logic_vector(0 to 3) := (Hi0, Hi1, Hi0, Hi1);
        READ_PKT_6_S    : vl_logic_vector(0 to 3) := (Hi0, Hi1, Hi1, Hi0);
        READ_PKT_7_S    : vl_logic_vector(0 to 3) := (Hi0, Hi1, Hi1, Hi1);
        READ_PKT_TAIL_S : vl_logic_vector(0 to 3) := (Hi1, Hi0, Hi0, Hi0);
        WAIT_PADING_S   : vl_logic_vector(0 to 3) := (Hi1, Hi0, Hi0, Hi1);
        READ_META_S     : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi0, Hi1);
        READ_PKT_S      : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi1, Hi0);
        WRITE_META_S    : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi0, Hi1);
        WAIT_PKT_HEAD_S : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi0, Hi1);
        WAIT_PKT_TAIL_S : vl_logic_vector(0 to 3) := (Hi0, Hi0, Hi1, Hi0)
    );
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        metadata_in_valid: in     vl_logic;
        metadata_in     : in     vl_logic_vector(133 downto 0);
        metadata_out_valid: out    vl_logic;
        metadata_out    : out    vl_logic_vector(133 downto 0);
        ready_in        : in     vl_logic;
        ready_out       : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of IDLE_P : constant is 1;
    attribute mti_svvh_generic_type of ARP_P : constant is 1;
    attribute mti_svvh_generic_type of IP_P : constant is 1;
    attribute mti_svvh_generic_type of TCP_P : constant is 1;
    attribute mti_svvh_generic_type of OTHER_P : constant is 1;
    attribute mti_svvh_generic_type of IDLE_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_1_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_2_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_3_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_4_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_5_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_6_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_7_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_TAIL_S : constant is 1;
    attribute mti_svvh_generic_type of WAIT_PADING_S : constant is 1;
    attribute mti_svvh_generic_type of READ_META_S : constant is 1;
    attribute mti_svvh_generic_type of READ_PKT_S : constant is 1;
    attribute mti_svvh_generic_type of WRITE_META_S : constant is 1;
    attribute mti_svvh_generic_type of WAIT_PKT_HEAD_S : constant is 1;
    attribute mti_svvh_generic_type of WAIT_PKT_TAIL_S : constant is 1;
end parser;
