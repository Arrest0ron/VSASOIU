; Вычисление 10 чисел Фибоначчи с записью в память
; R1 = F(n-2), R2 = F(n-1), R3 = Counter, R4 = Sum, R5 = MemPtr

START:
    ADDI R1, R0, 0      ; F(0) = 0
    ADDI R2, R0, 1      ; F(1) = 1
    ADDI R3, R0, 10     ; Счётчик = 10 (R3 инициализирован корректно)
    ADDI R5, R0, 0      ; Указатель памяти = 0
    STORE R1, [R5 + 0]  ; MEM[0] <- 0
    ADDI R5, R5, 1
    STORE R2, [R5 + 0]  ; MEM[1] <- 1
    ADDI R5, R5, 1

LOOP:
    ADD  R4, R1, R2     ; R4 = новое число
    STORE R4, [R5 + 0]  ; Сохранить в память
    ADDI R5, R5, 1      ; Сдвиг указателя
    ADDI R1, R2, 0      ; R1 <- R2
    ADDI R2, R4, 0      ; R2 <- R4
    ADDI R3, R3, -1     ; Счётчик--
    BEQ  R3, R0, END    ; Если R3 == 0 -> выход
    JUMP LOOP           ; Иначе повтор

END:
    HALT                ; Остановка