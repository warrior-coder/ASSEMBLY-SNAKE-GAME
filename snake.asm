.MODEL SMALL
.STACK 10h                              

.DATA
    G_WIDTH         EQU 28h             ; Game width = 50
    G_HEIGHT        EQU 14h             ; Game height = 20
                                            
    wait_time       EQU 7D00h           ; The less wait_time, the faster snake moves
    wait_i          DW ?  
        
    key_code        DB ?  
    
    head_x          DB 0Ah              
    head_y          DB 0Ah
    head_dir_y      DB ?
    head_dir_x      DB ?    
    
    body_x          DB 0FFh DUP (?)     ; Reserve 256 bytes for body position
    body_y          DB 0FFh DUP (?)          
    body_len        DW 03h    
    body_clear_x    DB ? 
    body_clear_y    DB ?
                     
    clear_line      DB G_WIDTH DUP (0DBh)
    cell_symbol     DB 0DBh             ; Filled cell symbol = 219    
    
    food_x DB ?
    food_y DB ? 
    
.CODE
main:  
    mov ax, @data                       
    mov ds, ax                          ; Connect data segment to code
    mov es, ax                          ; Connect data segment to extra segment 
    
    ; GAME SET UP
    mov key_code, 0                     ; Use key_code before game as loop iterator
clear_lines_loop:                       ; Clear background
    mov al, 01h                         
    mov cx, G_WIDTH                       
    mov bp, offset clear_line           
                
    mov bl, 18h                        
    mov dl, 00h                       
    mov dh, key_code                     
    mov ah, 13h                        
    int 10h   
    
    inc key_code
    cmp key_code, G_HEIGHT                  
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
    jz process_key                      ; Z Flag set if no keystroke
                      
    mov ah, 00h                         ; Read key if keystroke 
    int 16h         
    mov key_code, ah
    jmp process_key

; PROCESSING KEY
jump_key_up:                            ; Set directions according to key_code after process_key
    cmp head_dir_y, 01h                 ; If opposite direction 
    je game_loop    
    mov head_dir_y, -01h
    mov head_dir_x, 00h
    jmp game_loop  
    
jump_key_down:
    cmp head_dir_y, -01h
    je game_loop
    mov head_dir_y, 01h
    mov head_dir_x, 00h
    jmp game_loop 
    
jump_key_left:
    cmp head_dir_x, 01h
    je game_loop
    mov head_dir_y, 00h
    mov head_dir_x, -01h
    jmp game_loop 

jump_key_right:
    cmp head_dir_x, -01h
    je game_loop
    mov head_dir_y, 00h
    mov head_dir_x, 01h
    jmp game_loop   
    
jump_key_esc:
    jmp exit

process_key:                        
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
    
    jmp game_loop                       ; Else

; PROCDURES  
draw_snake PROC    
    mov al, 01h                        
    mov cx, 01h                        
    mov bp, offset cell_symbol        
    mov ah, 13h
    
    mov bl, 1Ah                         ; Draw first body element to clear previous head position
    mov dl, body_x        
    mov dh, body_y         
    int 10h
   
    mov bl, 12h                         ; Draw head position
    mov dl, head_x                      
    mov dh, head_y                      
    int 10h  
 
    mov bl, 18h                         ; Clear last body element
    mov dl, body_clear_x         
    mov dh, body_clear_y           
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
    mov si, body_len                    ; Set body_clear position
    dec si    
    mov al, body_x[si]                  
    mov body_clear_x, al
    mov al, body_y[si]                 
    mov body_clear_y, al
    
    mov di, body_len                    ; Move body loop start
move_body_loop:
    dec di
    mov si, di
    dec si
    
    mov al, body_x[si]                  ; Move every body element to previous
    mov body_x[di], al
    mov al, body_y[si]
    mov body_y[di], al
                                      
    cmp di, 01h                         ; Move body loop condition
    jg move_body_loop 
    
    mov al, head_x[00h]                 ; First body move to head
    mov body_x[00h], al
    mov al, head_y[00h]     
    mov body_y[00h], al 
    
    mov al, head_x                      ; Move head
    add al, head_dir_x
    mov head_x, al
    mov al, head_y                      
    add al, head_dir_y
    mov head_y, al
    
    cmp head_x, 00h                     ; If head leave left border
    jl leave_left_border
    
    cmp head_y, 00h                     ; If head leave up border
    jl leave_up_border
      
    cmp head_x, G_WIDTH                 ; If head leave right border
    jge leave_right_border
         
    cmp head_y, G_HEIGHT                ; If head leave bottom border
    jge leave_bottom_border
    
    jmp move_snake_endp                 ; Else 
    
leave_left_border:
    mov head_x, G_WIDTH-1
    jmp move_snake_endp

leave_up_border:
    mov head_y, G_HEIGHT-1
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
    mov bl, G_WIDTH
    div bl                              ; AX/BL -> integer in AL, rest in AH
    mov food_x, ah        

    mov ax, dx                          ; Count food_y
    mov bl, G_HEIGHT
    div bl        
    mov food_y, ah
    
    ret
ENDP    

exit:                                   ; Exit 
    mov ah, 4Ch
    int 21h 
    
END main