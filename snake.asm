.MODEL TINY
.STACK 10h                              ; Reserve stack, but not use here

.DATA
    width equ 46h                       ; Background width = 70
    height equ 14h                      ; Background height = 20
                                            
    key_code DB ?  
    
    wait_time equ 07D00h                ; The less wait_time, the faster snake moves
    wait_i DW ?  
    
    head_x DB 0Ah
    head_y DB 0Ah
    head_dir_y DB ?
    head_dir_x DB ?    
    
    body_x DB 100h dup (00h)            ; Reserve 256 zero bytes for body_x
    body_y DB 100h dup (00h)            ; Reserve 256 zero bytes for body_y
    body_len DW 03h    
    body_i DW ?                                              
    body_clear_x DB ? 
    body_clear_y DB ?
    
    clear_line DB 46h dup(0DBh)         ; clear_line length = width
    cell_symbol DB 0DBh                 ; Filled cell symbol = 219    
    
    food_x DB ?
    food_y DB ? 
    
.CODE
start:  
    mov ax, @data                       
    mov ds, ax                          ; Connect data segment to code
    mov es, ax                          ; Connect data segment to extra segment 
    
    ; GAME SET UP
    mov key_code, 0                     ; Use key_code before game as loop iterator
clear_lines_loop:                       ; Clear background
    mov al, 01h                         
    mov cx, width                       
    mov bp, offset clear_line           
                
    mov bl, 18h                        
    mov dl, 00h                       
    mov dh, key_code                     
    mov ah, 13h                        
    int 10h   
    
    inc key_code
    cmp key_code, height                  
    jl clear_lines_loop 
    
    mov key_code, 20h                   ; Set key_code to D button
    call spawn_food                     ; Generate random food coordinates 
    
    ; MAIN GAME LOOP
game_loop:
    call move_snake
    call check_food
    call draw_snake 
    call draw_food
             
    mov wait_i, 00h 
    
wait_loop:
    mov ah, 01h                         ; Check for keystroke
    int 16h 
    jz skip_key                         ; Z Flag set if no keystroke
                      
    mov ah, 00h                         ; Read key if keystroke 
    int 16h         
    mov key_code, ah    
           
skip_key:   
    inc wait_i 
    cmp wait_i, wait_time               ; wait_loop condition
    jl wait_loop                        

    cmp key_code, 11h                   ; If key_code UP
    je jump_key_up  
     
    cmp key_code, 1Fh                   ; If key_code DOWN
    je jump_key_down
   
    cmp key_code, 1Eh                   ; If key_code LEFT
    je jump_key_left
    
    cmp key_code, 20h                   ; If key_code RIGHT
    je jump_key_right
    
    cmp key_code, 01h                   ; If key_code ESC
    je jump_key_esc                                                               
    jmp game_loop                  
            
    jump_key_up:                        ; Set directions according to key_code
    mov head_dir_y, -01h
    mov head_dir_x, 00h
    jmp game_loop  
    
jump_key_down:
    mov head_dir_y, 01h
    mov head_dir_x, 00h
    jmp game_loop 
    
jump_key_left:
    mov head_dir_y, 00h
    mov head_dir_x, -01h
    jmp game_loop 
    
jump_key_right:
    mov head_dir_y, 00h
    mov head_dir_x, 01h
    jmp game_loop   
    
jump_key_esc:
    jmp exit
    
; PROCDURES  
draw_snake PROC    
    mov al, 01h                        
    mov cx, 01h                        
    mov bp, offset cell_symbol        
                                             
    mov bl, 1Ah                         ; Draw first body element to clear previous head position
    mov dl, body_x        
    mov dh, body_y         
    mov ah, 13h            
    int 10h
   
    mov bl, 12h                         ; Draw head position
    mov dl, head_x                      
    mov dh, head_y                      
    mov ah, 13h                        
    int 10h  
 
    mov bl, 18h                         ; Clear last body element
    mov dl, body_clear_x         
    mov dh, body_clear_y           
    mov ah, 13h           
    int 10h    
         
    ret
ENDP   
       
draw_food PROC    
    mov al, 01h                         ; Output mode
    mov cx, 01h                         ; String length
    mov bp, offset cell_symbol          ; Data to write
              
    mov bl, 01Ch                        ; Color. B/T - bg/text color in hex 
    mov dl, food_x                      ; Column (X)
    mov dh, food_y                      ; Line (Y)
    mov ah, 13h                        
    int 10h                             
   
    ret
ENDP

move_snake PROC   
    lea si, body_x                      ; Set body_clear_x
    add si, body_len
    dec si  
    mov al, byte ptr [si] 
    mov body_clear_x, al
    lea si, body_y                      ; Set body_clear_y
    add si, body_len
    dec si  
    mov al, byte ptr [si] 
    mov body_clear_y, al
    
    mov ax, body_len                    ; Move_body_loop
    mov body_i, ax
move_body_loop:
    dec body_i
    
    lea si, body_x                      ; Move body_x
    lea di, body_x
    add si, body_i 
    add di, body_i
    dec di   
    mov al, byte ptr [di]  
    mov byte ptr [si], al    
    
    lea si, body_y                      ; Move body_y
    lea di, body_y
    add si, body_i 
    add di, body_i
    dec di   
    mov al, byte ptr [di]  
    mov byte ptr [si], al 
                                            
    cmp body_i, 01h                     ; Move_body_loop condition
    jg move_body_loop 
    
    mov al, head_x                      ; First body move to head
    mov body_x, al
    mov al, head_y     
    mov body_y, al 
    
    mov al, head_x                      ; Move head
    add al, head_dir_x
    mov head_x, al
    mov al, head_y                      
    add al, head_dir_y
    mov head_y, al
    
    cmp head_x, 00h                     ; If leave left border
    jl leave_left_border
    
    cmp head_y, 00h                     ; If leave up border
    jl leave_up_border
      
    cmp head_x, width                   ; If leave right border
    jge leave_right_border
         
    cmp head_y, height                  ; If leave bottom border
    jge leave_bottom_border
    
    jmp move_snake_endp                 ; Else jump to move_snake_endp
    
leave_left_border:
    mov head_x, width-1
    jmp move_snake_endp

leave_up_border:
    mov head_y, height-1
    jmp move_snake_endp
    
leave_right_border:
    mov head_x, 00h
    jmp move_snake_endp    

leave_bottom_border:
    mov head_y, 00h
    jmp move_snake_endp
            
move_snake_endp:
    ret
ENDP

check_food PROC
    mov al, food_x                      ; If food_x not equal head_x
    cmp head_x, al
    jne check_food_endp   
    
    mov al, food_y                      ; If food_y not equal head_y
    cmp head_y, al
    jne check_food_endp   
                                         
    inc body_len                        ; Lengthen snake
    call spawn_food                     ; Generate random food coordinates
                   
check_food_endp:    
    ret
ENDP 

spawn_food PROC     
    mov ah, 00h                         ; Get system time. CX-DX hold number of clock ticks since midnight      
    int 1Ah                            
     
    xor dh, dh                          ; Count food_x 
    mov ax, dx 
    mov bl, width
    div bl                              ; AX/BL -> integer in AL, rest in AH
    mov food_x, ah        

    mov ax, dx                          ; Count food_y
    mov bl, height
    div bl        
    mov food_y, ah
    
    ret
ENDP    

exit:                                   ; Exit 
    mov ah, 4Ch
    int 21h 
    
end start