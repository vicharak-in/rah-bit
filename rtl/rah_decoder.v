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
E6MX60YgsHLZ5vCYEXDQJYm/4pLcAWA15my2k0fM9PAwRho9p+EtsFyjYPjqEPJy
e30Gqvw/FtpiP5rS/bhmRuzeQOn0wHDXztxLnYyYmta4p0PPYZUvBLdhDhs/+sTX
DgYJoxUqsfS8jOMp0qWUUqEUKIytCeCd1XiBdaJT81Rq8KLF3JmcjuGLT6KZu1vY
NDr2Ev+ACWMQSDpOw2eNyOb1jkqxiW/efj0zvWMLaZZFoBZtii07vgaL1HsuZoVP
cB5kx6kfWahpM3/ZB1PD7bIttTNFCUUtFgu7+vzLlJZO/vyGbX4gqAhE7NalxwtV
OUkEWXri4FGqeScmKKsVxg==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
mHHl7CinopGWv5iwpyON/clSFlmPizUzWK+brPCuIAGJb3mxtiSkf86+mFEtQCqy
sLhd/TXpxTY0d0UrvoUkdykSv+rXu8b+Lu0tZyr9SsjkYtmKF0O0T2mdleYXzFHe
0qvcU3SM4JvXAlBvvxdVcJINEKxvZbDsnNeD5Qt1m5M=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=2834)
`pragma protect data_block
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
nk2HHtQB7QbX9Ce2uHU0nw==
`pragma protect end_protected

endmodule
