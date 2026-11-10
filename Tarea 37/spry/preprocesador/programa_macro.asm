#define LIMITE #5
#define PASO #1

ORG 0x010
LDP $r0, LIMITE
LDP $r1, PASO
LDP $r2, PASO
LOOP:
CMP $r0, $r2
JZ FIN
MUL $r1, $r1, $r0
SUB $r0, $r0, $r2
JMP LOOP
FIN:
HLT

