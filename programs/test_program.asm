; Test program for ASOIU-16 processor core.
; Expected final state:
; R1 = 5
; R2 = 7
; R3 = 12
; R4 = 12
; R5 = 0, because both error instructions are skipped
; R6 = 7
; R7 = 16'hFFFA
; MEM[10] = 12

ADDI  R1, R0, 5
ADDI  R2, R0, 7
ADD   R3, R1, R2
SUB   R6, R3, R1
AND   R7, R1, R2
OR    R7, R1, R2
XOR   R7, R1, R2
NOT   R7, R1
STORE R3, [R0 + 10]
LOAD  R4, [R0 + 10]
BEQ   R3, R4, 2
ADDI  R5, R0, 1
JUMP  14
ADDI  R5, R0, 2
HALT
