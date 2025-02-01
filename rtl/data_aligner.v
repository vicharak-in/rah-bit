module data_aligner (
    input                       clk,

    input [DATA_WIDTH-1:0]      mipi_data,
    input                       end_of_packet,
    input                       rx_valid,

    output reg [DATA_WIDTH-1:0] aligned_data = 0
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
KKo3twsrrnVAIWpDgRloIenkiCtXEaHar8H/n0qinVFdhLwRpkPMbKsrHpaDtp8e
wPSIPp8IvnewwYiuvTRc4uDC3QmSM+hue+5A4FwjtvNz5NphBirtD29msJBKEf4R
RIKjV4DA3cYTkBeofvBCMTSIEqchYJRURQ8MkaIPBePdGFTAp10FaPeBTa8UqpmW
h05/WtQll3E+jjnzZ+fD1mXvoRViFGIAzx158VK/eVNVJ+uCd8WW/eTWnNlrxA+5
1oSfRO4ZGr5cuTRsP0Z5aB3cxD7wKt204i1Ct+3ZSHRZafXjPxSl3gfBOrPzB+Sf
o7YpVtmI5R52vhFbLKGLxg==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
T3R8ZG7vN8xqTlLjJuCbnubzLYJehVle+0nEKzI+dhMB8zy3h3hzqejDeuP6q0c/
hcZc//W7a/x9st4MmVu7kcG64rnJ6RNvzW2BdRpAJZIIqIoozA0Rrn7nh5LutD51
KRYJBntqFPHpzCh56d72lZ/B39yyG/I7XiJ4jUnk1g4=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=1869)
`pragma protect data_block
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
`pragma protect end_protected

endmodule
