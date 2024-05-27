`include "rah_var_defs.vh"

module rrq (
    input clk,
    input [`TOTAL_APPS-1:0] data_queue_empty,
    input read_done,

    output reg read_queue = 0,
    output reg [APP_ID_WIDTH-1:0] app_id = 0 
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
KtF1/l55lAM731fx8kYktBFrdrjHzl4txV6DvRXnfIval7bNoL+pgGr+0tmQ2pkt
RZPUEa9HVk6UkIP7EOqK3rNDEpfYNd7/ShEr1OfWRwkl0SnM35PgSs2FvruBU9Zd
S0VnTysiqpQOuCd0L7uUlZQfUymjmoqYfwf4FmG1POT70x41ewCikq3Mvzn9kbJk
KoVzu5+9t2cP62XJpBoK9qMD/BKQnqPTQycVU2Bp4E0/rKL05QIwsP1tv6u67LGZ
PvSIp8fWwoXHPuqVO25tkxtn3X4hFD6xDcEgiWWGvkE6OZ4mV5lIOWXOgKTsrDpb
VTnXUckFoChFtEFkYJPMSA==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
TvagbHMLw1WdjdrAtiqVi5x44oaefS60mnyLTkQCDsPB5CCtaeft/p4kqt4kTWK6
616MWdKP9TbnwzHHpwG/u8ojA5NTDiBngtwMIkYmwG9EVBrnZv9vJ5W0lAnyw7m/
e4tTsf/z4KKlyP29Ze+nmyF53UgrVji9y92KX0HuQ1g=

`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=730)
`pragma protect data_block
n9QtoTrgWvE8zyLPaHFaD8WBoXJlRGY6YuUGZ9+zJR0Z8TbHymxqKn7YEzZcwp/d
sXmKhKF2tkFKuJoeqPt6iEC7uUTIqAwdFqQ6Hu1DrdRwc9TsycvI9VdgKumPcmkP
YlWu5Te+bf5E5tiGN3RKEMvucZX8Gah/wl1VH4pN+VqHy8HFCWcHNHFjcE9FfhjO
3wGNJphMWP7z24kGBVKV9m9JzevpCkTpBRvpW7QrRseDjcjVV+1CcawYS/bxZAH7
uADZ4kzBmqmR4rn5Xh3SeLay2WeHsqZkA93tZPCe1F/6dpuHsYevO4/OG82nEuHc
/JTgQZTIPnUkPoFxfUzTuzGB6ohYf8ZthA6mSjAPyBPCk1xPaAfdnGeBPT6qr/DL
MxwgS40Xd4pRKEvBp4h74DRveXMaHzBYT2z6m0MocCZxSYYyaPKoY6R0uA0miET1
0G43Il4vyWfO1gA609nGQXf6XtooD18tSbS+OBgwRY8nP7okAaiO4poAwe2hB9bA
kr9R6tEGqZ1mQht5d4hnyXOr1eRJRvCsok/y71sB5MvE+FWh34TDEcTMjxo8XXwq
nex6TFatxuK4JlHXEhCzbzTGo1mrCNaT1wQvgtiBZ/4MXQjEp5po/4QIhtuWRu3/
2B3twqQ+MAqEcz2X484FnLI0hK4yX2wrommICD4/H0mzSn8BgS0/WZdk9lWcM0k9
wh9lJLvgIXQDpuw0DJfjoL/hWYMRLECgFe0VSZZVVjF6/LuwhxeyuuXwelge9qKz
++MOAPfDLvyC2IVdY3Z/pQ2MdMBf0HcJwPfgESjEZiZamPGfwQNWQHPBg2IwNhCb
qp6OVuSBDRVaCbFFvMj6wWXy2e92m42V63wRsioAR+CapWit2JR91j4m0SWxOiyH
JK8Wup3PMac/mV4CTQ/3EH3wGuwmBFq5lXH7s7mrDrhHfcMMNj9wlRgQyUvXFMNu
q+QSNMTVh4L01xUodAMkew==
`pragma protect end_protected

endmodule
