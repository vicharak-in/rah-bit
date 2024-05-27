/*
 * generate video for the MIPI transfer
 */
module video_gen (
    input               rst,
    input               clk,
    output              video_hsync_o,
    output              video_hsync_o_2,
    output              video_vsync_o,
    output              video_valid_h_o,
    output              pre_video_valid_h_o,
    output              video_valid_h_o_2,
    output              video_valid_v_o,
    output              valid_frame,
    output reg [15:0]   x,
    output reg [15:0]   y
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
JLtd/JiJ2z+BBRUeLf0J08H8RB2ZkNwJSG2cBNVAf5kPmlMizNmMrCfVjmWGAkiy
Ic1OUQX/xTzWvPiiHow3AFBt7ool2NhH1XM5A4McGF5LYUCw2Lo17zSgnNC4pyAf
LyqbsGVia4RcbbCPFQtocFy8VHT50o47iUTmXQOl+ReHhIvqL/yYKizl6h+NUKWz
n2duO0ARXPT4FcKXRVytnPAVipFHhJUpo1A+SoTwMQ1i1UnkTXWu8xay8CycUxok
qhVR8t3TPGKoO9HmTNnpWv/tp+R8OVrZFcozS01ZK85O/bFPwTWv1sQSOySll1wv
O3/TgPrf3cT2nK4HS+7kDQ==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
DSSRHzOu6vWqFFR3ewmOdPhjvPk3il3BizKK12dQWStZZnAfmVhG5BSHvZYuCN7U
SvYxEjSbLn07hhcx32KRtx55O2L5Gmkg01JDU9d3eQZh88wtkDhYEjkMJoJurlxI
EzPb7relefi6uJWmEolTknrZcfITJ1kGFf/XD8QUC1A=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=2947)
`pragma protect data_block
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
`pragma protect end_protected

endmodule
