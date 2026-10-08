`include "rah_var_defs.vh"

module rah_meta_app (
    input                                               clk,
    input [RAH_PACKET_WIDTH-1:0]                        in_data,
    input                                               q_empty,

    output reg                                          request_data = 0,
    output reg                                          w_en = 0,
    output reg [RAH_PACKET_WIDTH-1:0]                   out_data = 0,
    output reg [(2*TOTAL_APPS*DRAM_ADDRESS_WIDTH)-1:0]  dram_start_addr = 0,
    output reg [(2*TOTAL_APPS*DRAM_ADDRESS_WIDTH)-1:0]  dram_stop_addr = 0,
    output [(2*TOTAL_APPS*APP_MODE_WIDTH)-1:0]          dram_app_mode
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
ZdYPOlXnWviA4VwRX3bO5CMgTfA+V9i0grK4x7G1nowtRHb3uIj+d9IbQZ8ykJfC
QqTRv2EWJ6TF3RfLAok0PNbysmuuW2I2juv2OMF1vJLk6r0lFibbFp5f8IdO8t/C
exF8lfPQ6Lx2+fMUfOcFJlS7Tx1lyuX3z+GFs8gUbKyDQROxFTorPb41g/T5eYhh
V9VYCQa+JgDJRwyzMxSXusCPHobJl96xQj6Ln+vbClwzoT8IuxGVhaNIX9DR/BI5
95OXAntrnZcjfezQn7rZfotSyhtkn2283BDiG5oCdfIWzYToZxmEV7PJgWeOebZ3
BJHzPFJwoP4qdYvemvsTEQ==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
TTWSfn5+pHuTox8Tjimlq+sPSgXBPM9Vnhi10+vYN667S80IBQ8YBHXEW8fZ00fW
aR9206N23CNJmrWx7MQwWC6Ug+rTz6sLWWFukXgucIemJRAR5hBjYjIjKWLexKoI
tXIol8wBNgVN+mMl2oT9XWCuAtPwaMJavzlM9/c7/yA=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=4011)
`pragma protect data_block
SR6u6uSOngbA7YXCKvMvBCCFT8bqrT8C6m1/ViJliffLGas2ILz5K56guTbpB7Ju
GR+O/UF5xhrJ+anLKdZAkdCunZ1KrhQLjwB0a08zG1g1hHDHR3f7Gn57Txc/v7nA
XLwdZCGGUuerG9U7roL26KOh6FrzoolvsUuRGdlmLcvBWJNp4DZluCrhe2a+TX/p
clo7xC/AQfgCIySgAo2L6WZorhSlFs4Cp3bnkIlGF3tIC29B9rZd5PYvv5amviPM
ytRe73JyWxpwnAHq/XjK4pSirECujSUXop38wSz12+AuUa2FdKov6Fkt96/d40Zc
a+BxalbJccVYJsiBirvQUjDzz6YNyG0pMrJ2NFAR9nJpjJiFqeFq9pNT+L6OjcIJ
JWp3Ti6fE4wK56gw0BZTZJdgFS1OMlPaAqzkCHKkQcXwObYMC+O0YDJd82JNMhKF
ez8haAW2HS/8XhNVxIWs/6j3mDoFy683mIq5zCmngeV7cGa7zCGHKbF9qdcg2bdh
xSvPk8hGc6nGN2i4m/kZdZ1hZ/gk867ICqe3kQI7qgTZhbEBVU5dbb7iCI7fwTvX
kQFEt6msE4H3YsLopoD4DEaOCdeeDnlt2634cl94/EoyMmGWU/He37oooh0rKDlN
9qNA1nTeSACvEuxa0KAYilbsEDOASjj3ZTqX89Prt5Ea1W5zutgj2ACGJuZEK4yk
++32pk7/LlDV8BZwJS0Tt1SCRIO/cG2fkUOu5HudfTkS841gJJNPhRgCJO9kGOot
1LswqWJidPeE21d0jcSe+TFoDok9GV8N/s7B/J5a6Nm9jqk8l+ROhn8y1IrxLM3R
nzQ2aDhbS3BaRFKQDls7PQ6SuSQZ0k892ByxSfVHZP6hVqsYrT8yDQTzRKgXnd8d
KPsEIYnaUsrThQs4CpRL0eLSFiH1gklWDVoZGp9P0742mvwTvVfB+wNnWcWl3m9T
tn+EVt227oIXww96Jtz7KBCCC6tU2Xtnd6pvxvGyqGyfCN75CA67r7NjXSP65gsN
jTjdc+LlAFMh56erMufg07auXsItfCpuEfbeVCNN5yoVhful2jqNruVqw2iT3Ik+
3lkMtoUBwIVPPgqkoX66CBT9qktntYgIqa9ewe2zQkatMbA/yM28Ss9adJh9uCyp
jV0xAFenffT1cQcZ/FgMk7PqU0gBKTvBwsZB6trcOHtjjIYmE+Cjnlx02d5VZ1yG
0xulDrfGRRXt+qTmj+5KOTiHf5z+6Tu3fy0pnWjlp41Jb0DGRC2PQtlI/cXcmFPx
7hECHC58iXY+/bsQTBPdTelkVo5h/uUIgMqDIvsAdlkjjrEOKGNOOBwl4riplTsw
WSztBR3z/lu8IY13HEhzgxqiWpUpPdtUhsxzis+S4uNUEOdwrsCB2RtUuQ7rnIJv
0Y7CJh4CPAjiePVedq4jqa/8MVzsd/0/shIN9bqOClwOPqoMXdkJfI69Gw9pODm3
ctM82lmB03nTzF2Bctl/cWfwhfDkaN9SfF09vsTiYiOUpUpXUpnB+s6WYvcvj8Zs
O8Bq7QRltp7HpWrFkkyh/9R9PW5FNSK0iPLGEXtADx+FsCqkfzkJ+vH2FCHGvhp3
Do6cF7dofBnTbTyY4MY2vqmXHnNihFJoVAXyhSWm9p4buPtbJwZk3KzPkr2auyp8
kAXTT7o0x6a4NzfD0+146UCYxw/r2iQlwPSiQQe/P2Q0sWSp9eWbh9q4EV2DXRFf
S/VCpYszoDoKgVVVtSrF0EjPJvCo+n4yWPDVb6yJht4hOC2r5kENx0pTxWJ5mCUL
PEIUhHZZk+Kybf+yHOSWExaECeXByodis9JaTeD70j9J+B+Y3aVW5KgTn6ny9pwS
3Rxh/j95tD1wEqNbBhh81xA/i46RPUyV66BJMz7kVkbtWx+MuxjzLzMYNBSFA9nx
bvO9tJLWq38CjHzQokDGcVXEABe+q1b+RjaBuq7XzgRqOVESVSijgkviUiOwp0wE
7qcOa45B+InSN536QYGMMDUuDzPC9y1OF1U9WF1VtloF9Fdgd13IpNQPvjzi9KkX
Ii9o0fd+u4oR2SUQFCozq6kCkqZAYwDXPkV1HMidHq5AwpNGdWcrA8aIiMcCn2ge
ObrxsmqCwtYYJG2U0n++ccc2RdPrUKM2eor+d4Uz08Gz3h7jbcsC8rdlSTAnxsTU
tXSeRYJev3mYMrEjBwTiP+ENn4RAeydq81pLfbEgspQEU4ANSfp+/7ZhiBqQDXU5
vYVxdlYiNe1Hi0U3SEoxr599vCqYdEuHxuRsPxmI4OcV5YCPpZ9OKlV15IclYnGA
0AlPdeoSm9pEt9vCEI6PJHL1JHn3FNCMFt/mAh5NsxgQWQGdTRngN6EFzFtTfTme
8nyWIcTmzxGPjdFYo+FMCrRd4/e3HMGr4NvIiRuPJLzfVSP4HmsjNFuAV7bLQNRU
L6QvCXOXzNL9eKjFC3Ih9ERrl2kHfjXmzqGe9VfqHDnKElfRPLwRd3dr/UNoZPgh
mddofXUHBnwPRm4nzX6GbouBJa8hJUdiksrvbcbvv4MOaDZDmQngRbCHbraVDSe4
KyEKT2F4FvPMHOyp00DSUACgJmcQzDFHM/XaEvnVXhXUHP8/ZfSycAu3mhQxRa3B
LDCWfhAOWbZaMKkFtMZcKxj/FGybBe5odaimIO9i/TwSd9bifGqKHHTz8/sl8Gyb
ca2b861MMdjL6h3y3a2NrO8f5aPh/x2/odtN0NnbMq8QhTI/XcGsxdA1fgIJUo58
NdWYL6PzcB6SYRub0Syy0xmvEYqhmzNjV5x0dhX5SN/uTphsmwJa1ETGo74o552b
71P0er5SvKNRWuZlP5Qrur/qnkLMIIu/uhzzJFdG7FSGYsDaNE8XoXTreYD4F1Xa
uuvdaAThj+wlJuycawlF9veWS3fBUUN4SVw/q7QPbJzAxG4X4qur/4PipVWjl3nB
lSQBnNbiuy5ryWY2OobmvSOOGlfGDR1kz9+bM1GdqKyAnblIJntdr5AKIwv+Neuh
8DrhNdOmAUbGi+hXHwFm1wuxSdsq/VzDNKvVkhojh/h1ksPKhuJ4rD8qL3m0FyBy
TGn7YsRRCuGnv/UWD1Sz0m/oi99RzeJiYV9aJY19+djhIDOJFnoR5q0Tf8oro5YQ
ygwh+stG/62tqYpKunxGL+ap9OY9u75G3ZgP808DTYj02ihAuls8VTv6/j1bpixz
iSQasZo5l4fWce3bzzLyC51Z8HOtYe62+gz8FJ4ZjvIkxVaARmRWllgPGSBXDjRb
Nb/sRrLEgdMCc2DqJmaNgVggt9zeZsxhT3a9+1wvp9hasC6vPN1TxGK0brW17ZPu
Wn9SPNv9FV+9gPLUiUslyAuEJHvk9FbUD2fPl9A9lnXQJ0ruTCK2KdnzDiNueDKI
WMdM9Vza/3DJfTJJcRs+qu/m7iTml7nWzJuVYlQXjvtBfxtrIiV2ukUvf1FVq0bK
Y86mjRU1sqxQorYX7dn9/ld0jddO7r98DCZzICmGJbjHK4V8WhusdDZavra4gOG4
b6HaaMsR8EfoF1zX8r5Z7o5Avy6KmqW198PL5qSHcW6XrNbd9VOM+on5EWaz+84a
zY5anv2f9bvwnJstC88lKgQ3mLj1ulXUL2t/yplab90qRMz3YrARqjMM2DZy7wBl
hffBnGFTBuTYeOHrDHWJgOW2gc3elGFnOhfuCNCeFQ8Bl1KsZ0WTbPWruEKCgc2m
vT3Bviy1pLGZfFMj+YbKWslZO3iNq9RUa1QVkPcKrikrh+Cilqp/xYOGpjGhIU19
qAc7pTeav+0nzcV4MpIVQpjtmhtWEaUfymCkP8Aivj795RlMF65VYqfJ7gHPpG2Q
Z5pmDUPZ/HOSqoRAsiXMlMLW6kifBNhaYKL91KpTBwE1zRDoBS+9VP6EaF8PkkI9
3biJueoKkRRfNI5b4Y6ied4QAKCGgfBxw2lpMbAj4E4iFT+Okr8PxKtx+E72yVFm
iUXtT2Yq0fDcUEWez+UKIJ+IfVUx3ydLWSaIKIYQKYVgfCVg9otNm10s6rLRgkpV
gv1LG+36YgJyseS73ySAdvz/T/ajfQvEQsea9isG+KVGyywNJXBktXQvxaHeM7OJ
Q3oi8GMFhbrCZ3GmD/0Bs/Y88IIjjKw57+IClGX+O+8Gqr90h3bu2scrAp0V03cm
goTYaJhqKBDWJZMJ7a46PaM+aELb3sCDnoW/f2T5ldERG7O2SD4oTi+xmajkDpvU
LHnLrTJChsETJ1dexRlB8yAAXRghWCEZTlc5FeFO9BIfCUr1PZTVR5d7Dn/DN3Kh
iKzrAAXPjjxbd9yWHPuPQlqkOqwgR7DKrk6twvaxVE7Gr7XQf7XqQgAFh/Azqmbo
6Qh8xl4kGgMLeA58oPuH95d7OINW74QDu0vIHsP1zePNH18ZXz9JqIyRj39FtH+K
Ym8LkN+nS20CXV8ib4Vzd1AjRgeauegVhH8NBycW1ARcOHPqaUV8hX6mgbPmOPu4
DXV2rrr+mJp1aU3J77rxNoCSj18QEIzWMtzV33EH9cFG0jvPdoN9u47q5YHFV3dR
NkWGHna7D0F4t2FM+2NL/eDDLvxZ+JhbdSk5U81izKSGEBVlqs+RycFXTkEUfp9S
TJLZRPqaOrjrs6NN4AtezS0XTpROov2F3pPpl5+nwub29sR+CB7ZZJB/XnSyXSL5
e7eliiDYis4Wq4k21lk6xRxUZkul52X4vFwjUIeZSb6t7rgzCGRM70jVyRXe5jME
aYPox+g3ZVWhAeTM5LCtQ7/l/vDW8q0Inc8NObtr00mT+ulstVh5Znc4u4dnfX4k
DO1wJvhyyF3tOMI4VPlM19ngWvW2xV+JbKJ34ybVfREx1nArG2BADYYzYzWnhbf6
qGV4iFKCsQy+ROA4GCTbmFbmQ5txXqJN76hdeaB0xukvuhso5YHD9qGjJDFmXFwq
sB8iMn/6oibQzNjp8AUqxKHe14TuguKW9dnNQ2pyFcbtB6FGxLYSRjPZmZ+x4BMA
cr4R8t1LYIMYbuzfvIptRxVvZt0T1VKGMp5+gCAOGsS4ZqPHsmzKj8xuH7WyQhm6
mB0faiJsgtEwwDbrbTlcEOfAv+5UiFVtNsC/vu2NlVFB5PYcEC3uHM446LRGuvBO
pK/PDmx4bKExWhoO2rxm5mx47EY8fbuPDiUpbwy8/s2LcXQ/IH3dokaZxIBOCjD5
29BLE5VyusErA/Ts/YftMbatMur4RIa1xrz9n/WRANAqagLSe7JCNr3C+wD8yHis
o4JeL/3VS8szwDjfYuXrK+M9Pp5cLpVREIFE2U+9X+ML4buxBsgbPPIp6Lr8LBgU
sblG8IUorAF7fPAhZxzIQDLg7lPsKpjBySCPwX2t9J4=
`pragma protect end_protected

endmodule
