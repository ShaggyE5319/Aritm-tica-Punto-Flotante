ORG 0x030
LDI $r0, #0x100
LDP $r1, #5
LDP $r2, #0
LDP $r3, #1
LOOP:
CMP $r1, $r3
JZ FIN
LOADA $r4, $r0
ADD $r2, $r2, $r4
ADD $r0, $r0, $r3
SUB $r1, $r1, $r3
JMP LOOP
FIN:
STORE $r2, 0x105
HLT

