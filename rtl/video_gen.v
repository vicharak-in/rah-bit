/*
 * generate video for the MIPI transfer
 */
module video_gen (
    input               rst,
    input               clk,

    output              video_hsync,
    output              video_vsync,
    output              active_video,
    output              pre_active_video,
    output              valid_frame
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
ZesGX4sSUU8915BXOIVsD2v9qdE+GApZed+YSuSK/vXjISgBhM1E7fmdYZjB3zcW
wkVHCa2f6nlosF/Q4Fjo3lNjQSmekjVlGQh1bgnygL9AugXzwWWN1PFAiU32sMi0
lhLvjyADSz/lQ+WdKxeXqMkaOUHZ8NNPFLRFf5xWDfnsoe73s5020K2GBlKk9D7b
bRyku66vRyETAn4MydFvGiFeE97Nhbw/0TrNpJleFsgQFbguEV33ArDP3pp0VsZb
ciNkzzmZ4vpRWoHbQHQcFmB3GY/98vDoZ4S2F7XW9M66NcuXrZfrktdNUtHgVtkf
lV0xqNIv0bXx/uftWeWbvQ==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
C37hIh0AbouDmxwDDwLzKxBo/Ltx0N6cCHXdcKJ5BubIe6PNPmdfC5KIT/DFMxk3
o18RthiUmMfaiQHa8H8SvXmJnDNN2ZI3zc8n+rRvgmGEq5WX8wnAMaYKCIQxzYp7
TIfmpQi/fo/U31eVAFl842J/qw9Wfx+aREWuhlv3AJE=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=2067)
`pragma protect data_block
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
UnSf6B1kNzPja7w4d1rZ+w==
`pragma protect end_protected

endmodule
