%include "constants.inc"
global readDfa

section .data
  states: db 0
  transitions: db 0
  fd: dd 0

section .bss
  info resb 2
  
section .text
extern initDfa 

;James, Carter and Qwinton

readDfa:
  mov eax, 5 				  ; sys_open
  mov ecx, 0 				  ; read only access
  mov rbx, rdi 				; filename
  mov edx, 0777 			; read, write, execute permissions 
  int 0x80 				    ; call kernel

  
  cmp eax, -1				  ; Check successful open
  je exit
  
  mov [fd], eax

  xor r9, r9  				;clear registers
  xor r10, r10
  xor r11, r11

fileReader:
  mov eax, 3 				  ; sys_read
  mov ebx, [fd] 			; file descriptor in rax
  mov ecx, info 			; store read data in buffer
  mov edx, 1 				  ; # bytes to read
  int 0x80 				    ; call kernel

  mov r8, [info]
  cmp r8, ','  				              ; check for comma
  je fileReader				              ; Jump if equal to comma

  cmp r8, 10  				              ; check for newline
  je fileReader_two_init		        ; Jump if equal to newline

  cmp eax, 0				                ; Check if end of file
  je end
  
  cmp r9, 1				                  ; Check if transition was read
  jz transition				              ; Jump to transition

  cmp r9, 0				                  ; Check if state was read
  jz state				                  ; Jump to state

  jmp fileReader			              ; Repeat fileReader

fileReader_two_init:
  mov r11, [rdi + DFA.states]
  mov al, [rdi + DFA.numStates]		  ; Load # states into rcx
  movzx rsi, al
  xor r8, r8
  xor r9, r9

fileReader_two:
  xor r8, r8
  mov eax, 3 				                ; sys_read
  mov ebx, eax 				              ; file descriptor in rax
  mov ecx, info 			              ; store read data in buffer
  mov edx, 1 				                ; # bytes to read
  int 0x80 				                  ; call kernel

  mov r8, [info]
  cmp r8, ','  				              ; check for comma
  je fileReader_two			            ; Jump if equal to comma

  cmp r8, 10  				              ; Compare AL to newline character ('\n')
  je fileReader_three_init  		    ; Jump if equal to newline

  cmp eax, 0				                ; Check for end of file
  je end

  sub r8, '0'
  mov [r11 + State.id], r8		      ; Load id into rdi
  mov byte [r11 + State.isAccepting], 0	; Load isAccepting into rsi

  add r11, State_size  			        ;id = 4 bytes, isAccepting = 1 byte
  
  inc r9				                    ; Increment loop counter
  
  cmp r9, rsi				                ; Compare loop counter with # states
  jl fileReader_two			            ; if rdx < rcx
  cmp r9, rsi
  je fileReader_two			            ;else if rdx = rcx
  jmp exit				                  ;else

fileReader_three_init:
  mov r11, [rdi + DFA.states]
  mov al, [rdi + DFA.numStates]		  ; Load # states into rcx
  movzx rsi, al
  xor r8, r8
  xor r9, r9

fileReader_three:
  xor r8, r8
  mov eax, 3 				                ; sys_read
  mov ebx, eax 				              ; file descriptor in rax
  mov ecx, info 			              ; store read data in buffer
  mov edx, 1 				                ; # bytes to read
  int 0x80 				                  ; call kernel

  mov r8, [info]
  cmp r8, ','  				              ; check for comma
  je fileReader_three			          ; Jump if equal to comma

  cmp r8, 10  				              ; Compare AL with newline character ('\n')
  je fileReader_four_init  		      ; Jump if equal to newline

  cmp eax, 0				                ; Check for end of file
  je end

  sub r8, '0'
  jmp accepting_init			          ; Jump to accepting
  jmp exit				                  ; Jump to exit

fileReader_four_init:
  mov r11, [rdi + DFA.transitions]
  mov al, [rdi + DFA.numTransitions]; Load # transitions into rcx
  movzx rsi, al
  xor r9, r9				                ; Init loop counter
  xor r10, r10				              ; Init line counter

fileReader_four:
  mov eax, 3 				                ; sys_read
  mov ebx, eax 				              ; file descriptor in rax
  mov ecx, info 			              ; store read data in buffer
  mov edx, 1 				                ; # bytes to read
  int 0x80 				                  ; call kernel

  cmp eax, 0				                ; Check for end of file
  je end

  mov r8, [info]
  cmp r8, ','  				              ; check for comma
  je fileReader_four 			          ; Jump if equal to comma

  cmp r8, 10  				              ; Compare AL with newline character ('\n')
  je reset_counter  			          ; Jump if equal to newline

  cmp r10, 0				                ; Check if from
  je origin				                  ; Jump to origin
  cmp r10, 1				                ; Check if to
  je destination					          ; Jump to destination
  cmp r10, 2				                ; Check if symbol
  je symbol				                  ; Jump to symbol

  jmp exit
  jmp end

state:
  mov rax, [info]			              ; Move info byte into AL
  mov [states], al			            ; Move AL into states

  inc r9				                    ; inc counter
  jmp fileReader			              ; Repeat fileReader

transition:
  mov rax, [info]			              ; Move info byte into AL
  mov [transitions], al			        ; Move AL intoto transitions

  movzx rdi, byte [states]  
  movzx rsi, byte [transitions]   
  sub rdi, '0'
  sub rsi, '0'
  call initDfa

  mov rdi, rax				              ; rax contains dfa pointer
  mov dword [rdi + DFA.startState], 0
  xor r8, r8
  jmp fileReader

accepting_init:
  mov al, [r11 + State.id]
  cmp rax, r8
  je accepting			                ; Jump to set
  
  add r11, State_size  			        ; id = 4 bytes, isAccepting = 1 byte
  
  inc r9				                    ; Increment the loop counter
  cmp r9, rsi				                ; Compare the loop counter with the number of states
  jl accepting_init			            ; Jump to accepting

  jmp exit				                  ; Jump to exit

accepting:
  mov byte [r11 + State.isAccepting], 1
  jmp fileReader_three_init

origin:
  sub r8, '0'
  mov [r11 + Transition.from], r8 	; Load from into rdi
  inc r10
  jmp fileReader_four

destination:
  sub r8, '0'
  mov [r11 + Transition.to], r8 	  ; Load to into rsi
  inc r10
  jmp fileReader_four

symbol:
  mov al, [info]
  mov [r11 + Transition.symbol], al	; Load symbol into rdx
  inc r10
  jmp fileReader_four

reset_counter:
  xor r10, r10
  mov al, Transition_size		        ; Move to the next transition
  add r11, Transition_size  		    ; 4 bytes for .from + 4 bytes for .to + 1 byte for .symbol)
  inc r9				                    ; Inc loop counter
  cmp r9, rsi				                ; Compare rsi to loop counter
  jl fileReader_four			          ; Jump back if rdx < rcx
  jmp end

end:
  mov eax, 6         			          ; sys_close
  mov ebx, [fd]      			          ; file descriptor in edi
  int 0x80           			          ; call kernel
  mov rax, rdi
  ret

exit:
  leave
  ret