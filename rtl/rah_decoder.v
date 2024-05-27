`include "rah_var_defs.vh"

module rah_decoder (
    /* rah raw input variables */
    input                                   clk,

    input [DATA_WIDTH-1:0]                  mipi_data,
    input                                   mipi_rx_valid,

    /* apps i/o definition */
    input [`TOTAL_APPS-1:0]                 rd_clk,
    input [`TOTAL_APPS-1:0]                 request_data,

    output reg                              end_of_packet = 0,
    output [`TOTAL_APPS-1:0]                data_queue_empty,
    output [`TOTAL_APPS-1:0]                data_queue_almost_empty,
    output [(`TOTAL_APPS*DATA_WIDTH)-1:0]   rd_data,
    output [`TOTAL_APPS-1:0]                error
);

`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="ipecrypt"
`pragma protect encrypt_agent_info="IP Encrypter LLC, http://ipencrypter.com, Version: 23.7.0"
`pragma protect author="author-a"
`pragma protect author_info="author-a-details"

`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
NLoBRX5GrEKgtFzAtBAqBgcl0jDeZs4icmY7X9hCny5ygL5xfziSVLyCUZynTrwW
PemZaMaXX98QKRfH3frui+MfHytHUv9y32UUOTtrQSbQb2eYfUuA5O3domMeplON
UOw4IfJA1i6u813/mMa8OZ7caD18/i9iyV0QRC0ehUkB105x/Sn5+z4SX2lZTkfO
iJSyKBbuY+yObf+Z0P1NNezOxuRbDDIjx0cb4EhAbBraNC+c34VYIsw76fBzeZKR
7xsV0Si6R1mJcciJzBq7fWiVYA6yuuSJ+M4gNxebZOBZ3ZN3zPSkOQPL2Ghr7C9I
/q614pGcPqQfboDuow6FGw==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
XB0gCV9XV/wauRGhqeih8RUrB/5fZpGWKQqPd1jVd2sNRb/CSlQ4BATzgR3LDygs
3phvzs/99Gt/aKkHUuzWum79IV2UcaTdkYQsqndieRy21knZDFlNfx8Xf7Vwrcaw
Jr4K8BHy5zcORP6hYhiz0vDEppSHLh+FE5u/oyJ8ees=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=2708)
`pragma protect data_block
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
`pragma protect end_protected

endmodule
