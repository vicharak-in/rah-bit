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
IHvUwZZFIQ7Vy7QlLAaCAkmHqO6rkZtsNVE/afTkcgESJ/Li8LtHQgodkYivJYol
Fyj/9b7Sy9EnU1kRWJD6HFHcTmrX+pZ4+9uiNrw720Q20DO7DHdGv+474wf3TTu7
0PMjESmCd21SxAAcTfvck5smSWRM8nKugFcw7VMJr4BZhj1hmXBoWfYIWMxcvCUu
m5o/5XCpRu5jNoZFE9mW5phfZ2drDlCplDLjFtyeS8hNL24KlLxxgDbxwVNn/30P
OfizWCLfHLbpYvmSUqmScIIRUbF0+GcRdySp/UTqqj6AxDqHg3yQ5oGCNfDjN4w7
vrm8m0b/+m0z6ZCnMDwM9A==

`pragma protect key_keyowner="Mentor Graphics Corporation"
`pragma protect key_keyname="MGC-VERIF-SIM-RSA-1"
`pragma protect key_method="rsa"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=128)
`pragma protect key_block
mPRXcFcxtSh6Sx+SID+EayVVNMqzLMIJtu8pFPoJIswHglUk4OO3UkDZiYCgmE/V
GzSa/RtM2vZkVcxvJ/qfOd7Uo8c7O1iDq0gHv8GtB/5CNj8nrAdEghw3oYs30JW/
uLBOOlCrBXB5htwsSMztNHcXZeYurvxkqhRrNlOqTCc=


`pragma protect data_method="aes256-cbc"
`pragma protect encoding=(enctype="base64", line_length=64, bytes=1166)
`pragma protect data_block
dUc+C/Gor9L9/13drAqmtrhEPp8m94YXpCC9jS85PAw7BUcpK5eZsC6ALYbrr1p/
hYww6Xa4bMPWO7ZtWfgfX/RMA5pBrJ9gSnvCjOnqIkSdTOWNcYb5FVaT4OrGG3Yz
rj3+V9rcjO3GYqa4uGQ9E8H0S396UdHe392e3kGa8pUXy1GmEZYeDb/A+0TakdFU
X5whTfCqaLxobuJzP77n59CjFbCA9XD+FwOMagJ4NVD6klgpL0G88nIyOhTR+lp/
iEogl0qnakHorQBtudcquMmBaQbtc+Q/J1j7PQgMD7vSdHHgOj0ayunmCrgP2XFZ
pRQoYDZXElzxPtTLEzuQka+FrFF7cBgOlwZ8mkcghp+60PsdXRGJrpCaFQRMc+tH
X/CrjUHpwJe3/cXO3ev0LmBCA3VECRz6R9fSJoT5kH5rPjxkV7YTjF/u0TTabPao
dYidD0yl0pi954MpRIbNM3g/F1aDetgMbXIt22gozi7orctC6CluJifLo/zTAbt+
p8LrOqV7SeapBnAxc7skSyjHIplQiWWsayh+1NaD+7UqW6z4It6SmRTcDiCQjiW5
VjCqbjPGdoGvO/2QDRsgIxmgz1S+SlLIOmuZnw99eLRY11SVlTPCOGy/+3yQU0JS
yEf4BArrnRG5wcFhxYKVkgG1CMbdXcH1xPmEVHjq9NM/HsEAHd4thCkJdZyTEgF2
2DVdv9evTn5WSCFpVzXKbpGZDKTDoWHqYaZFCTHriSmWIK6WvCmZiP58If07oSYt
fCzgAOphZC4ZzV730iIqDhRM7pTTTKQrPYWyAYHE4pmrLgxTDffyj3mwp3+wn6sz
U3ILGCb7jocL9+taV3dw6t4K6lVmiQ/gCgxqy5LNIx5Z6gmKw/pn7AsPPf1titjX
YQydLGEA9GvwM3ZX9XEmO0vI3U7ZYgkmS8z8Z5NNKXg/Rbey5efHuvxSeFuwjf1M
876etPeR1/fx5YXUcpNpVaDVvqFu8ecZFccG5tEzzZJxsxuSXprFidylEp/niXBB
hciI3hZ3Z9pRePKnILyHBKL3zCggCMGuV52HQOQMb4uyRFFEViZduLZUk846OpXq
c1L+XZoBUmWzO+K4UMmCLsAvbyhK10t1tct6PFKMbzlJ4c7mpjsm0o3WVV+cge8v
tbQPOh9CCOZYVBvUuxM8At0KBYOvH1Tn4Fq+iEFFjaxYJeljW6tapKxpPFXkEdcC
LjZ5knlTR97zySgXVs6tAqZ9IIUi3f+xIdvjGorCTsaeCYBXpDG0sGl8zr4zUF2Z
DhWpA4ZMcvwgyzQNCK9qxeLxi2l4MTT+LYYjhaF4mHd1bQDQTZWmnKJX3HKKcjNC
dTqoAAmxtu2n+sHqqJXb52aFWFc2nWwqEQ76gBpnUsaZDCFSd71x/3npoqjo0/1g
+HS3ugI0REe0yCBNoYlBcVormEa9xwRUQRA0FLUQL3Bttj88mvKTKP/y3oXIlklq
PZ5VdDUQEu2bK+1lLvWn59bMUNPipbxAzR/uqqOMFdwdDl5WAYMEggX9754vvMec
g9mMFVqKC5qD1AMe1jgz9A==
`pragma protect end_protected

endmodule
