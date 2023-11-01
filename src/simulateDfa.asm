%include "constants.inc"
global simulateDfa

section .text
;
; bool simulateDfa(dfaTest, testStrings[j]);
;
simulateDfa:
   mov rax, 1
    ret