START:
    ADDI R1, R0, 5      ; R1 = 5
    ADDI R2, R0, 6      ; R2 = 6
    SUB  R1, R1, R2     ; R1 = 5 - 6 = -1 (0xFFFF)
    HALT                ; Остановка процессора