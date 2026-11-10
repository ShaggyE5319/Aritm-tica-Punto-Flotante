
ORG 0x010
LDP $r0, #5
LDP $r1, #1
LDP $r2, #1
LOOP:
CMP $r0, $r2
JZ FIN
MUL $r1, $r1, $r0
SUB $r0, $r0, $r2
JMP LOOP
FIN:
HLT

