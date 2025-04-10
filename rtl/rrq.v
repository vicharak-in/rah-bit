module rrq (
    input clk,
    input [TOTAL_APPS-1:0] data_queue_empty,
    input read_done,
    input [TOTAL_APPS-1:0] fifo_re,
    input [FIFO_ADD_WIDTH-1:0] occupants,

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
Qg44AZl/GhuBMFe2/NhOzkf6gItZKSsosqY0J5qb/kJTCWhItvA5vhTNdnAU7iGj
iNjfmfqVrpaLSURxCgrqNWmlenHYgWQvviPBFXPKX03GAQXF0azRqXRAX7eMUR8u
ZTTsk+29x1yyRJKfqglCaiTEcDeZwcZnstqoWO9t6m2X40cF5/+hIQO6XLa0fbBS
912PsBBPUHv217U2F8XgqyXMYveunNLfz25fP2tjrahN9yls+MI8Qd1x2movIwHp
c8oGpY7OUhVhLZdqI/HpdGBPpVHwlHo41S8j3Cc0ZmAHxAnvZ8lnqjvJiIr38FrU
hhI5/+gWqj87X+/Zj3uvVg==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
cvc91L1dz2ahyKui1gFB7ztaBJlPCrTUGJvXiYcOPaCk67v+CT30gb82/knFhYg7
y65hrpM+NdZHw5yKoKX/cJwMxtwHz7vAfZ+0ZemczjXVmq51Uwc3YhIyOQCuk0vF
TFfcZ4jOcx1bnYJiYGfrOIbGaffhpsOX/Ndk/N6NqG8=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=1171)
`pragma protect data_block
qTxXWpl7LLlTvT5+HSqaD3b0tKAjMR5or3U5TMIG1SlX4HkysSgxRB3NkyobWI/P
2XBEHk2yb1kH8VcdPTsJOz4e3/eR+eEXde40JuKIlMAGo0X7Eer58eH9kTws+cSW
GQGGo507DOElR1kDL1Et1peg7fvnWCMhCZU4IFaIvHJizsg+TvRRRdgiEKSOTzpf
MZRYKw32EBr0YYuLelRKixrTFRswWAaIxAaImWyH/r19TRi+5KDC5RLmSxiWlZlM
mA9AM0AGxg0E9e7CEASusTgGDtZx/qzJNvvLp6ls/4YTfZ52Kdmoc70cq/OOEpMr
mgdGdRiEyjw0BXWE2px/JGH+1TjdJFrvqtexVfLjl39QuJw/gKXbdUfYx9Z4nd7k
xsvIxS+rOgON4G+VNiYqBNywzGOe5tOD/3rPYx+6UOQQIPG0jxkcr6dyQXpTUuz+
OwCRtcOiPTX/gm5geTkwKfcyrIL7ijZtfqBr5dADEUPT4R42WAJvblsI9tmS/ioz
jLAg9VUrgBRQ08qZy2y148NGaD9w4S1gu6xvEMiJdd+yJf3R/xayFKXVcQeEzjAW
/zCrpPNhUgfj7YshPGR2FQlgjsv+jAiOA56Ocq2bbjK2OvZ1DytWKz3Gjktm7ZCi
mCFH2Da+WJhtB57mL9qROkJNbEeLc+RkgdQHwuHkwoPIsZuZctrA4JOyW7Oh0OSA
aFPRu24bmWO0mmvzmCFWtKAkGFDKafJbkOL2Z9CEPrITUdUq4Sxo+ioCnJJo/fwQ
xk1nECNuwzYjg50KKTKH8BB/NyEJzfQb/rq7FB4tCurWajgp4QWpFV/c7jtVfP5o
sdtN0FLdFpcSotjMJAPDn7oo4Og6RqsYU4T4uW8l/MvAV01RtAGkeUyIyAyE80vS
0c5Heoi1gEclhxST20CqVtpGO3EP2aJ9pY7I6d78/CZ98u/RrDeRJEgOAubDybbK
EAkFK4JOLrxwjoQEolOmcdeT47dE0ADdgp5xGhZOZncnrcb/u0VzdEE2tyyB1Qm+
ZjzBQRELBNGd+uNviDLfKpIcNym3nJaqVGUa41cnW53tMmhvaUIh6yE212fCCPXU
RCtTbqLp+870GjIN/1zCyVMBaNrgap0GnKxR+4r8IhJxDbOgk34bZ6x9cvTq2RE0
vge1YJuuaNPsd4NdOeoY+pkz+o1rzklqJmg01AjVr9LKbFsk4eCpUbut+SDXKXD/
3+vjrhItgN91Y6gQS1QqlF9XOnBW8Xd9VwFUTwuDMgDgCijEClBPVSVf9eqGELpu
PSWOkwF9oYvH5P0W/r7Sd7EkVX9jfSnUh5GkARsRCPkp3/EckmJrHzzXSF8pMQvL
QZDeffZ84BhPCSuL7QchA5KNALt+IbKFgESUV77MIv8neYr6OUbDl15laWSeOrmp
VuyFYKlYQTEDs5yJ+3+zFXsIuwzHV/R7zJnA/iYJ3eJsZbOF5KDk5Mbafwr60uXf
2M7JHLWz5NAGmVp+NrO5OFGkTstmP780GO84EfFmWrEnZUI79UuXNgui35FKXmDw
lJsk1Pv/5El22sfbwHgKFhYXcbH9K1Px7xfRBI9w3ho=
`pragma protect end_protected

endmodule
