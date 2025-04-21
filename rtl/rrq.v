module rrq (
    input clk,
    input [TOTAL_APPS-1:0] data_queue_empty,
    input read_done,
    input is_busy,

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
OraaImAjJTcHlLCdPotJcQo3TWYQnGaiADhmaot7AiAwCX1C4qszOq+Kzofde/nk
PskJ5MYn+xpXwSUxc7JWIFDkA/++xmT0XRMPt/QGFK2WEMsBseKNcgMlfmg8v3Kw
y8RasQpTKstcDMLXLUKNOugppuHpVxMAwINqdrBhtqhOPYIisIk77JtAVQPTmPZn
OGJRuSWeZQgOTJlCkXxhAlM/soMIn9ctVQU+blYT0igWoC++H/Ttd+CpHqa5B6kS
NXpvewrgy8CDFHtE2hP2fXHeSLups5O9hPBdWMrouVwIYrZjiOQ//Hssfh4z01WT
9m1kUngf0QPezE0V/uZoiA==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
kNrgrg5v0RKamzIc/WHG1r4YGFIOsG/0BZK6bOXqTkysQaLbyhZ8soyQt73V6lO/
4kTfZYefEN3nGhAKsIMEAuLZaNY1Mm7fuPDJ5V9kg0dXzRAQsf5ZxIIt1OWZSRj2
v99GM7M0jheE4lx/hIOFzdtyDFw3Spl3uetHgqeVXKg=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=837)
`pragma protect data_block
qBy3TC0n9I+80/XOLcjNwvTBou8UiefIFqp6xse8TYqzpGp19RgK0PfTuUKYTp+1
DAFCuS0AHOO6W+T7lOgOvUQZ3XTtZEfRG9sq+kYm9SdbR2OlRIoEtjP2lzfHjOop
FGjUR7lQMY9FaXeQPtWJR97qQ1ngB4mouNPxCZqCSry6ar/2lg3RiXWRZB5KPwY0
rb4uDZ3cUmNZBAYhxOBR1+LAb8ZVQaHMpO/8dgytBo+l2RqYsNBjdqj7oUAybIv/
Wj5Gd5Z7g7yzYchy41kNqVtrYqZFFBTj2upKp34NYqfZsBMHt1iDxOk3JefMLGu+
8US55cCyyvIZhUS80rBBd9zuiHGt+IxtiTPEhFXbhb+rTbI1CDC48cfQZ60r619M
gDX7QPirwbYcoXc7/zmJYfVQh66knHNaZ+4kwdXgTivirx50DSu9OStivye8PU8w
DCqF8ybEs05R2rnTgop1io1HU9K7NDFiNWyeee9Niyze/j+OgE/3R8u58alUganU
V/6NPngJP1aW4ntm//S81XENlcNdLglesPMaJMEEE+idLZaKX5iBfC2Dsrlo8/yr
3zUYyQkhcCZZL9zvtfoRcx6mJD1Itdgz3oLqdCZ3ilZCGuFgC6zWf44vAqqw3UeJ
dbbZzlvjFOvsREC/J8aVMvTULgDJMkHATJDfMa4RgZw8JVIn6DIVIKDR4eiAK6c7
LXT9MZOOfaW5sNngLFQUb61HQf6hcmyY2reStM119amSX42niljV2alVwMLfZ6gB
LmbSzC1F5OIryjVHbRMzd+Y2TZuPncWmIb57ZPJ9J3xdhPa6vhkJvtXn9FTr2TRB
DVbtFf1PblAjAHtu2b9Niyj96WRzw7+jAEgla9Ct0xNmb/nlcGAdAHyyTMls2cLT
32eZFdasu7J07UgklTas8qW4Ut5/KwZyr4L0AydiPUhkTwrvNfyJLuBKB3S+MyCB
019y/3HgDXyRrUaD5U5aHubTSr46dmGojw6M45q9f8eICvr3ZiV2Aan2uRxBM33Y
nXqh8ZFZS5dqKjQVmjMiTxQKbUsbeFKmFoAtnxrMXk2kxF3iNPMITtV72rV9i320
qimnVae7I+hbftEZO7GKCfPMZZXTu4uIsj6GOuZFIRk=
`pragma protect end_protected

endmodule
