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

readDfa:
  ; Open the file for reading.
  
  mov eax, 5 ; sys_open system call
  mov rbx, rdi ; file name
  mov ecx, 0 ; read only access
  mov edx, 0777 ; permissions (read, write, and execute for all)
  int 0x80 ; call kernel

  ; Check if the file was opened successfully.
  cmp eax, -1
  je error
  
  mov [fd], eax
  xor r9, r9
  xor r10, r10
  xor r11, r11
; Read from the file until the end of file is reached.
read_loop:

  mov eax, 3 ; sys_read system call
  mov ebx, [fd] ; file descriptor is in the rax register
  mov ecx, info ; buffer to store the read data
  mov edx, 1 ; number of bytes to read
  int 0x80 ; call kernel

  mov r8, [info]
  cmp r8, ','  ; Compare the least significant byte (AL) of eax with ASCII value of comma (',')
  je read_loop  ; Jump if equal to comma

  ; Check if the value in eax is equal to newline ('\n')
  cmp r8, 10  ; Compare AL with ASCII value of newline ('\n')
  je second_init  ; Jump if equal to newline
  ; Check if the end of file was reached.
  cmp eax, 0
  je end_of_file
  
  ; Print the info.
  ;mov eax, 4 ; sys_write system call
  ;mov ebx, 1 ; standard output file descriptor
  ;mov ecx, info ; buffer containing the read data
  ;mov edx, 1 ;eax ; number of bytes to print
  ;int 0x80 ; call kernel
  
  ; Check if r9 is 1, transition has been read
  cmp r9, 1
  jz move_transition

  ; Check if r9 is 0, state has been read
  cmp r9, 0
  jz move_state  ; Jump to move_data label if r9 is 0

  ; Go back to the beginning of the loop.
  jmp read_loop

move_state:
  mov rax, [info]  ; Move the byte from info to AL register
  mov [states], al      ; Move the value from AL to states ; Move data from info to states if r9 is 0

  inc r9
  jmp read_loop  

move_transition:
  mov rax, [info]  ; Move the byte from info to AL register
  mov [transitions], al      ; Move the value from AL to states ; Move data from info to states if r9 is 0

  movzx rdi, byte [states]  
  movzx rsi, byte [transitions]   
  sub rdi, '0'
  sub rsi, '0'
  call initDfa
  ; rax holds pointer to dfa struct
  ; assign it
  mov rdi, rax
  mov dword [rdi + DFA.startState], 0
  ;ret
  xor r8, r8
  jmp read_loop  

end_of_file:
  ; Close the file.
  mov eax, 6         ; sys_close system call
  mov ebx, [fd]       ; file descriptor is in the edi register
  int 0x80           ; call kernel

  mov rax, rdi
  ret

second_init:
  mov r11, [rdi + DFA.states]

  ; Load the number of states into rcx (assuming numStates is a member of the DFA structure)
  mov al, [rdi + DFA.numStates]
  movzx rsi, al
  xor r8, r8
  xor r9, r9

second_loop:
  xor r8, r8
  mov eax, 3 ; sys_read system call
  mov ebx, eax ; file descriptor is in the rax register
  mov ecx, info ; buffer to store the read data
  mov edx, 1 ; number of bytes to read
  int 0x80 ; call kernel

  mov r8, [info]
  cmp r8, ','  ; Compare the least significant byte (AL) of eax with ASCII value of comma (',')
  je second_loop  ; Jump if equal to comma

  ; Check if the value in eax is equal to newline ('\n')
  cmp r8, 10  ; Compare AL with ASCII value of newline ('\n')
  je third_init  ; Jump if equal to newline
  ; Check if the end of file was reached.
  cmp eax, 0
  je end_of_file

  ; Access the current state using rbx as the base pointer
  ; Load .id and .isAccepting fields into rdi and rsi respectively
  sub r8, '0'
  mov [r11 + State.id], r8
  mov byte [r11 + State.isAccepting], 0
  ; Move to the next state by adding the size of State struct to rbx
  ;mov rax, rdi
  ;ret
  add r11, State_size  ; Size of State struct (assuming id is 4 bytes, isAccepting is 1 byte)
  ; Increment the loop counter
  inc r9
  ; Compare the loop counter with the number of states
  cmp r9, rsi
  jl second_loop  ; Jump back to the loop if rdx < rcx (not reached the end of the array)

  ; End of the loop
  ; Print the info.
  ;mov eax, 4 ; sys_write system call
  ;mov ebx, 1 ; standard output file descriptor
  ;mov ecx, info ; buffer containing the read data
  ;mov edx, 1 ;eax ; number of bytes to print
  ;int 0x80 ; call kernel
  cmp r9, rsi
  je second_loop
  ; Too many values
  jmp error

third_init:
  mov r11, [rdi + DFA.states]
  ; Load the number of states into rcx (assuming numStates is a member of the DFA structure)
  mov al, [rdi + DFA.numStates]
  movzx rsi, al
  xor r8, r8
  xor r9, r9

third_loop:
  xor r8, r8
  mov eax, 3 ; sys_read system call
  mov ebx, eax ; file descriptor is in the rax register
  mov ecx, info ; buffer to store the read data
  mov edx, 1 ; number of bytes to read
  int 0x80 ; call kernel

  mov r8, [info]
  cmp r8, ','  ; Compare the least significant byte (AL) of eax with ASCII value of comma (',')
  je third_loop  ; Jump if equal to comma

  ; Check if the value in eax is equal to newline ('\n')
  cmp r8, 10  ; Compare AL with ASCII value of newline ('\n')
  je fourth_init  ; Jump if equal to newline
  ; Check if the end of file was reached.
  cmp eax, 0
  je end_of_file

  sub r8, '0'
  jmp init_Accepting
  ; Print the info.
  ;mov eax, 4 ; sys_write system call
  ;mov ebx, 1 ; standard output file descriptor
  ;mov ecx, info ; buffer containing the read data
  ;mov edx, 1 ;eax ; number of bytes to print
  ;int 0x80 ; call kernel

  ; Go back to the beginning of the loop.
  jmp error

init_Accepting:
 
  mov al, [r11 + State.id]
  cmp rax, r8
  je set_accepting
  
  add r11, State_size  ; Size of State struct (assuming id is 4 bytes, isAccepting is 1 byte)
  ; Increment the loop counter
  inc r9
  ; Compare the loop counter with the number of states
  cmp r9, rsi
  jl init_Accepting

  jmp error 

set_accepting:
  mov byte [r11 + State.isAccepting], 1
  jmp third_init

fourth_init:
  mov r11, [rdi + DFA.transitions]
  ; Load the number of transitions into rcx (assuming numTransitions is a member of the DFA structure)
  mov al, [rdi + DFA.numTransitions]
  movzx rsi, al
  ; Initialize loop counter
  xor r9, r9  ; rdx will be used as the loop counter for all lines
  xor r10, r10 ; line counter

fourth_loop:
  mov eax, 3 ; sys_read system call
  mov ebx, eax ; file descriptor is in the rax register
  mov ecx, info ; buffer to store the read data
  mov edx, 1 ; number of bytes to read
  int 0x80 ; call kernel

  ;mov eax, 4 ; sys_write system call
  ;mov ebx, 1 ; standard output file descriptor
  ;mov ecx, info ; buffer containing the read data
  ;mov edx, 1 ;eax ; number of bytes to print
  ;int 0x80 ; call kernel

  cmp eax, 0
  je end_of_file

  ;jmp fourth_loop

  mov r8, [info]
  cmp r8, ','  ; Compare the least significant byte (AL) of eax with ASCII value of comma (',')
  je fourth_loop  ; Jump if equal to comma

  ; Check if the value in eax is equal to newline ('\n')
  cmp r8, 10  ; Compare AL with ASCII value of newline ('\n')
  je reset_line_counter  ; Jump if equal to newline
  ; Check if the end of file was reached.
  
  ; Access the current transition using rbx as the base pointer
  ; Load .from, .to, and .symbol fields into rdi, rsi, and rdx respectively

  cmp r10, 0
  je set_from

  cmp r10, 1
  je set_to

  cmp r10, 2
  je set_symbol

  jmp error

  jmp end_of_file
; End of the loop

set_from:
  sub r8, '0'
  mov [r11 + Transition.from], r8
  inc r10
  jmp fourth_loop

set_to:
  sub r8, '0'
  mov [r11 + Transition.to], r8
  inc r10
  jmp fourth_loop

set_symbol:
  mov al, [info]
  mov [r11 + Transition.symbol], al
  inc r10
  jmp fourth_loop

reset_line_counter:
  xor r10, r10
  ; Move to the next transition by adding the size of Transition struct to rbx
  mov al, Transition_size
  add r11, Transition_size  ; Size of Transition struct (4 bytes for .from + 4 bytes for .to + 1 byte for .symbol)

  ; Increment the loop counter
  inc r9

  cmp r9, rsi
  jl fourth_loop  ; Jump back to the loop if rdx < rcx (not reached the end of the array)

  jmp end_of_file

error:
  ; Some error
  leave
  ret