module rrq (
    input clk,
    input [TOTAL_APPS-1:0] data_queue_empty,
    input read_done,

    output reg read_queue = 0,
    output reg [APP_ID_WIDTH-1:0] app_id = 0 
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
NCq1Q6fiqo5RYEFAwjaePrV8uHLvi2rvkBbEXDkp4PU72wKGECWoW3bOQVtNCN7m
FURPVqOqYM8kSXf05kVIZK6r6/VbI2EFCtIb678XFmzo8KRYpKkM8AY+ojslGR/b
2NCa7S8jaB50HlAKJecWP3VsN6uwcmUQpgoonMd/vQQhjVUCLB1yVDxaEgL7u1KI
/8dkQSwp/ncvm/pXIMqrN67eIqdR3fery/kmrHJSH4O2jg1xWqi3Qpb2w58qXUQj
IvGRbPVQWDBdGzDLQG+nPKHmeC22Tyn3PbQm6mLV94By8gvZ89VrrsdmO2dU2ac3
+mDNQ66NesUWdQPZrUivzw==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
FN3K0xoZIS1rQ+b5nsmGmax9kKKd8yo7Y7AEzz6aqQteFneWZg21wmYhR/9tOazV
0lbFKgHegL20ktle2ROWIkY4MNLy+juOxwS1ewQudrwmbi5J2TBv2oumG/io80ci
NkyfbIB8fh0jU0/C6SpoxD3hrzN/qeX8m/fg7VmJcBU=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=753)
`pragma protect data_block
0t+1lCgb0ot1lFc9wFnT3pl7HI2pZFgPhGW4Oo2XarxNv2+2aS5308RwNXJ/67Hm
eRi62UWM9GBFHcq2KzIvVsuNhicOWAqdwZteiXz0m+KBlbdN+naphRUd5Fs16z+4
D575gfAExkjDgQFxdLyD/TZirfCSbLdUkRWK01VKk+3iuAo6BunN7FP0A+OlqTB4
KlxXDZ+rntCpv5q+9Gy9a9QJbv7zUqIFf2iBQVWjhYiVNa1/OR5ayo+mFrdwNJMl
eV5wALP6ttCr2sWenPphEEiBU0g2PLrWlnfIv1AI+oRW4xItf8XfluoEA3U6vcGu
kyTKkUDhbJyJKdzv2fkJIu5CID2gUt3HTCienTWv3WoHh9MHv1jdTWPaC92abuH1
ZMUXyKDCGaTqJxie5b8VNKxskri9haMNYmu4fvX4eP7IYs0fWnrgUxgfGdQazrmb
GI1pGr8yLUBj1ifiM68tyPgfxwXtSsbPVR72GoysBCf8dphGEKHJzGz53wQIwzCA
WZYtZYPDdJMHvHZsHUCGzBFGQn4FS3Uta/PhtD1/Iw/TONmhMhCFk7r61IpCdP6K
1cED5uRcX88OakbsgQukXLXedyqdMUvLZsAmkwroUbF/11ORqaxGtJbQPwvK6qrN
F0G4sO0YcKW0PatLd3EMrmO9BeIUGjhjYTRKn8v6gYXqdAutUJ3qf50d5dn/2R64
ytKf8KCDQCipWQlOFOcC3FNc1MA+GvQuvwG2CnvZwdY4RK3rPIf1IhqUz82YWyEX
xOrXNXYN99q8dhwXlUGL4Os/KfCaBja/8x4UDuIzZ5OJ0i4pSuV666uaMFk6p8vi
YqHgU6DS+57cDX3IpSYILUvaX8Z12f+PUaI9O/UVLE3bQ476VxE3Nldog7JIweb4
Sf8tj+82j9POO9aeTs4Xwpti6V7PSmexJinEBIGq28qO1a5usyfUCfrSTcPe86eE
i4VCKU5NNY4dlh5VvMODXpA7imt3HPx0MDCiV7MzTBTvgfPVAIDIY/0Q/sXzJ5NG
`pragma protect end_protected

endmodule
