module rah_decoder (
    /* rah raw input variables */
    input                                   clk,

    input [DATA_WIDTH-1:0]                  mipi_data,
    input                                   mipi_rx_valid,

    /* apps i/o definition */
    input                                   rd_clk,
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
U9PqjlOzZHsixt4goljF/D8H0J46Ns4tS9WKvcO1fB/J3uUg96YEOsJ8POE7BKDH
1nPQuh0NtW3DSmU7p47hW5IxYwTHM7W2xtX/0pZZDbhVDDbqbzxuxrAlCnt87iqQ
Rux8pJ8WkAQet4BddnADGG8wvT82zcl+SSGBDsVaMDqZKtmo5dvNl9jGCXvswlst
xHp34MCoRXkXb+rBZ+oL0FSJk7BQzPXN71qwHHGBaTj3wMgmmMDTqmMtEJA0x1Mm
7gcQjtKb86qKcm1h4Z2/hXv408pWoEjiZph7pGQ1UTWMeFqM0rbiGrZe3+rwuTZN
9qbYYPaAomKKloyd+BSQCA==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
O4OBCviD08GfII69vlfewQcIZ36rLRSTVocrDf+zYqpoD6mjfr1+EQHL9WpbTUOf
bc0LQJyMtEoj/Ys8woFD72jKWDdwHgOvWifoBopq0Gqpzn6Tzp2tVPjaOiy7Agc5
7lvxmP2w7BtgOak8vl/CawXkgywKdKAAkoFLkeEQDdk=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=3326)
`pragma protect data_block
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
aonQwvfZSaBkG/0WDOMs0g==
`pragma protect end_protected

endmodule
