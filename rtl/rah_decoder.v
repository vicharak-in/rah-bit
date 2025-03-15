module rah_decoder (
    /* rah raw input variables */
    input                                   clk,

    input [DATA_WIDTH-1:0]                  mipi_data,
    input                                   mipi_rx_valid,

    /* apps i/o definition */
    input [TOTAL_APPS-1:0]                  rd_clk,
    input [TOTAL_APPS-1:0]                  request_data,

    output reg                              end_of_packet = 0,
    output [TOTAL_APPS-1:0]                 data_queue_empty,
    output [TOTAL_APPS-1:0]                 data_queue_almost_empty,
    output [(TOTAL_APPS*DATA_WIDTH)-1:0]    rd_data,
    output [TOTAL_APPS-1:0]                 error
);

`pragma protect begin_protected
`pragma protect version=1
`pragma protect encrypt_agent="ipecrypt"
`pragma protect encrypt_agent_info="IP Encrypter LLC, http://ipencrypter.com, Version: 23.7.0"
`pragma protect author="Vicharak"
`pragma protect author_info="Vicharak Computers Pvt Ltd"

`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
HlqDHhuM/nbSFri/1NfK+GRyqAND3PZpwsT2xF+2WbGiucKNvCSPPkhw08wgaGnO
DcuMhctgKySNh8YEX8dW7HH7v/FNoy9du5mUZnGGVN4UvLITQM3ZttUV2ibw5BCy
tX8711Jir54YNP5V0Fw5yrbF8RtudYqCJo6xppEHhkEXpTMri3wpK2+ZETYPXq/b
hiwkTmXVUh5psGZQZQTThsyPkVHOKU4YNw/yR7Culzmsh44ieOr6fe5AgpOswdmb
SgVBNUFP0LrOdXgqnX9CyrdBnYNyTBbt5af977V0PBCTFmYxDPcNQ6H5UhqNyocz
Ezf4lArfHoQ/cv49rd0DPg==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
P30GvE2vTQb7VFc0nk2b44syWxpdP9e2wCE3Hq7x3XZnvpFOyGCEtTSKrPIEdTHI
x3Q1v+benluSv9CMfb775j2snECjNbk/9hD4lKWemdAoy4zrUJ6ueJz2nYyPbSSL
9h89PPA05bjXfPPby6rq/ot9Tae/kEN/hsyrSWq/uEw=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=2681)
`pragma protect data_block
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
`pragma protect end_protected

endmodule
