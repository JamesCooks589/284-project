%include "constants.inc"
global simulateDfa

section .text
;
; bool simulateDfa(dfaTest, testStrings[j]);
;
;James, Carter and Qwinton
simulateDfa:
   mov rax, 0