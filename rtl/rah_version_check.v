`include "rah_var_defs.vh"

module rah_version_check (
	input                               clk,
	input [RAH_PACKET_WIDTH-1:0]        in_data,
    input                               q_empty,

	output reg                          request_data = 0,
	output reg                          w_en = 0,
    output reg [RAH_PACKET_WIDTH-1:0]   out_data = 0
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
Kfxm6koWqmukzRXkGV9iv49g2wPII7Qlxdu0Mis9vxDqzk8TWZRVZfEPn4feKOsP
zmkyQUaKpKFh/EqW1+UBIZJYFxavxauLzo5JJfmWcWil7+GkX9S/E4V+P+UuCJJ9
V+OYeXEc3vNhWbdTXbHe6geXLhROxr1Y/MAiLODkeUfjJ12gnKYSQKDJqMo16nyy
rKogK2sGS9M6LM4ghrYxZPezjlM4NhPkeCxFPZyEnUM9gLNudhPgahCS7UkC8dVw
y0qbI0+eUwBOGbb7HdznAd3IX5ukAqW86PqaoKmWZSxPfZKhWANTQGhfKVFIxihR
8GwNW+vK0R762IylKTNiAQ==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
kpQ8mOSuScyQp95GVU6YXhYL8wSTemTpmiU6gCy2VLnH71/6N7w+JmuQRI3wlhee
wG9IoUPPcxP1OQ+hlD8ErRP4Xoc68bJddkS+VOiQeSs0wM8kYEpE7sDJarTuuce6
qHRMVet8kU5LjpqXSYywu/rDLxxaoeC7m3IsGzLG11E=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=715)
`pragma protect data_block
xSHTs/tQiIWA6Z1EfHtCFQAZDzaUa7cIOaOlUA1rDI7Pxc2rNd2UCJuYW4mbNCJX
Y/47QLCFR7E14LxvnU/HJkv6NU9MXcrLpliE6evm5f62d5IFIyst9tCO4Qce9IvP
n4ipdJVaC1mf6Yz7zz4Z8hXfKF25nwZO4G/zK6CuaQJy0/j1PMfXdECZgh0k7qRp
FNyI5ToCA3JWNLyEfA9nGookfwPDH5LYqxSXwqW2u90DGsdJYe4wkrUewbwcJ8s8
dSAxM0DUW129cRlhkQDreu37Kb4oZGHRY0i6gH+sqk7z0jKb8adUQ1hGHnfYv87n
IY3gEDh6//oACG51vVZIJ4tMdSmTHu0bf5VEDDypaSZSKjTgHWsB02T1PziFwd3t
7FgkB0PVx5bYemLCo/ym9cFaemhe50A0fwRzLa2KzRjGqSDqk3l+X9sDoKCGNJKp
i26sgvjvUSzAgtDhlLnrAXIheW/OrvJQMlsHJxfh9CuywKexUSVEveoY3KXEah5S
u3DHYnYaZn+mImbb50A+TSermSDn+RvBoM/tClleNKpN3T1RMyXUS3PrawnpHUR+
4Y198bGDuFXfUEsi+WhMi0TwcSTDBbaxYzWVM+iRrfQVQ511vuSzkSH+PdoLTPwN
ISkx7Fd94xWj5EGK5Qb5U+1ELUiA7Xp7KUjzZ8PWeuRzSNiK/5CTT2YvCchFs55A
hFuaQyhlsVxMGJwFoSAjreviSGlLUieWmfXBZn+LshmXsdBEzBsOD+r1ZmVFhMpp
JkeMUJGG7J1zFAyavYB776oYgX1hcacc2pSHGyttdrVKBM/S7d5y9Ax8mnaFBPYU
AKOlozhZOM7pGjn/jlm5xA08YRZO6IpSJt/hEB/X1X2f/EQh7LJTCI7rOT1ZTi/+
tEEt9sSv6mDJuB8OVWXcePOHfw/xitRledOw68ecw7cQq6OPzVezEy2RL8kSz1F0
`pragma protect end_protected

endmodule
