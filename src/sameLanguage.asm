%include "constants.inc"
global sameLanguage

section .text
;
;  bool result = sameLanguage(dfa1, dfa2);
;
sameLanguage:
   mov rax, 0 
    ret