ORG 0x020
LDP $r0, #7
LDP $r1, #0
LDP $r2, #1
LDP $r3, #1
LOOP:
CMP $r0, $r3
JZ FIN
ADD $r4, $r1, $r2
MOV $r1, $r2
MOV $r2, $r4
SUB $r0, $r0, $r3
JMP LOOP
FIN:
HLT

