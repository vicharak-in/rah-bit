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
`pragma protect author="Vicharak"
`pragma protect author_info="Vicharak Computers Pvt Ltd"

`pragma protect key_keyowner="Efinix Inc."
`pragma protect key_keyname="EFX_K01"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=256)
`pragma protect key_block
kmBI3ZfDkYYo4OH/7lmbEXooguD9FauDOGqvDJpA21pOrSjc/LvzI9lY73A04JvR
H0gIonlpKNkajFLv291EobO0oETqvI2quvQL/RJnIpsCeNP27H7zckJZ8MkUqBhJ
kPe0ldd+BRqQLGJiN0yHMEUwmAxWfhA/5/V/ezZRWG9C8Jp4/LFWlcljpFZh14zY
VgA45522aCQ52ZZK593idwFI4eY4gubZydTSBuWCzU880VjZ7JceUqp8Ec7BV1b/
O26wtPitf8aIePfYBowhUuImhelSUrndrvyzGIWRCjIFpBKgkImu2YFYl+LRoeD7
uVObt8KvhjK69GT0RakYLw==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
EFjCjHBgOaxc3mW1kjaGO8KxMF74yCtgkj7UBs4wGBOBc/uCOE6O9DQYWpokFuOp
g3AjAFd0hgVIkyYIWM7DKl1HfKTcWVIVEd+a8H+5K1OLaq8Myv8EdTJ3tPgqHkyM
Eqifa1QZYe/E0dDl/NF99Uam7k9utl/Kd5ZWhuQcY3I=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=2947)
`pragma protect data_block
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
`pragma protect end_protected

endmodule
