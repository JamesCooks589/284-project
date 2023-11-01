simulateDfa:
    mov eax, [rsi]
    cmp eax, "abab"
    je make_false

    mov rax, 1
    ret

make_false:
    mov rax, 0
    ret