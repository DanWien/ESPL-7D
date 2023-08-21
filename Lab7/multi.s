section .data  
    format db "%02hhx", 0 ; Format for printf
    newline db 10, 0 
	x_struct: db 5
	x_num: db 0xaa, 1,2,0x44,0x4f
	y_struct: db 6
	y_num: db 0xaa, 1,2,3,0x44,0x4f
    buffer_size equ 600   ; Input buffer size
    length db 0;
    err db "Invalid argument",10,0
    STATE: dd 0x001E 
    MASK: dd 0xffff

section .bss
    buffer resb buffer_size   ; Buffer to store the input
    

segment .text
    global main
    global print_multi
    extern printf
    global get_max_min
    global get_multi
    extern malloc
    global add_multi
    global rand_num
    global PRmulti
    extern puts
    extern fgets
    extern stdin
    extern strlen

 main:
    call handle_argv
    push ebx
    call print_multi
    push eax
    call print_multi

    call add_multi
    add esp,8
    push eax
    call print_multi
    mov eax, 1     
    xor ebx, ebx   
    int 0x80       

handle_argv:
    push ebp     
    mov ebp, esp 
    
    mov eax, [ebp+12]  ; load argc into EAX
    cmp eax,1
    je default_structs

    mov ebx, [ebp+16] ; load argv into EBX
    add ebx, 4
    mov edx, [ebx]    ; load pointer to argv[1] into ECX

    push edx       ; push pointer to current argument onto the stack (for puts)
    mov al, byte [edx] 
    cmp al, '-'       
    jne skip_check  
    mov al, byte [edx+1] 
    cmp al, 'R'       
    je random_case  
    cmp al, 'I'       
    je input_case

    call puts
    jmp invalid_arg
    
    skip_check:
        call puts      ; call puts to print current argument
        jmp invalid_arg

    default_structs:
        mov eax , x_struct
        mov ebx, y_struct
        jmp argv_done

    random_case:
        call PRmulti
        mov  ebx, eax
        call PRmulti
        jmp argv_done

    input_case:
        call get_multi
        mov  ebx, eax
        call get_multi
        jmp argv_done
        

    argv_done:
        mov esp, ebp  ; restore stack pointer
        pop ebp       ; restore base pointer
        ret

    invalid_arg:
        mov     eax, 4
        mov     ebx, 2
        mov     ecx, err
        mov     edx, 17
        int     0x80
        mov eax, 1     ; System call number for exit
        xor ebx, ebx   ; Exit code 0
        int 0x80       ; Call the kernel



; 1.A
print_multi:
    push ebp
    mov ebp, esp
    pushad
    mov ebx,[ebp+8]
    mov al, byte [ebx]
    movzx ecx, al
    mov edx, 0

    loop:
        cmp edx,ecx  
        jge end_printing
        mov esi,ecx
        sub esi,edx
        movzx eax, byte [ebx+esi] 
        pushad
        push eax
        push format
        call printf
        add esp, 8
        popad
        add edx , 1 
        jmp loop

    end_printing:
        push newline
        call printf
        add esp, 4
        popad
        mov esp, ebp
        pop ebp
        ret


;1.B
get_multi:
    push    ebp
    mov     ebp, esp
    sub     esp, 4
    pushad

    mov eax, [stdin]                    
    push eax
    push dword buffer_size
    push dword buffer
    call fgets
    add esp, 12

    mov eax, buffer
    push eax
    call strlen
    add esp, 4

    dec  eax
    mov [length],eax   
    inc eax 
    push eax
    call malloc
    add esp,4
    mov esi, eax        ; esi points to the new struct
    mov ebx,buffer
    mov edx, [length]
    shr edx, 1
    mov byte[esi], dl
    
    mov eax,[length]     
    mov ecx,0
    and eax,1
    cmp eax,0
    je get_multi_loop
    add edx, 1
    mov byte[esi], dl
    push edx
    jmp odd_case
    get_multi_loop:
        cmp edx ,0
        jle _end
        push edx
        movzx eax, byte [ebx]
        call char_to_hex
        mov ecx, eax
        shl ecx,4
        inc ebx

        odd_case:
        movzx eax, byte [ebx]
        call char_to_hex
        add eax,ecx
        mov byte[esi+edx], al
        pop edx
        dec edx
        inc ebx
        jmp get_multi_loop

    _end:
        mov     [ebp-4],esi
        popad
        mov     eax, [ebp-4]
        mov     esp, ebp
        pop     ebp
        ret
    char_to_hex:
        cmp eax, '9'
        jle digit
        cmp eax, 'F'
        jle upper
        cmp eax, 'f'
        jle lower
    digit:
        sub eax, '0'
        jmp done_char
    upper:
        sub eax, 'A'
        add eax, 10
        jmp done_char    
    lower:
        sub eax, 'a'
        add eax, 10
        jmp done_char
    done_char:
        ret


; 2.A
get_max_min:
	push    ebp                 
    mov     ebp, esp  

    movzx ecx, byte [eax] ;ecx = eax.size
    movzx edx, byte [ebx] ;ecx = ebx.size

    cmp ecx, edx
    jg finish ;cx > dx

    mov ecx, ebx
    mov ebx, eax
    mov eax, ecx

    finish:
    mov     esp, ebp
    pop     ebp
    ret  

; 2.B
add_multi:
    push esp
    mov eax,[esp+12]         ;first struct
    mov ebx,[esp+8]          ;second struct
    call get_max_min

    movzx edx,byte [eax]             
    inc edx                 ; edx = max_len+1
    push eax
    push ebx
    push edx
    call malloc
    pop edx
    mov esi,eax             ; esi points to the new struct
    mov byte[esi], dl
    pop ebx
    pop eax              
    mov edi, 0              ; iteration counter
    movzx edx, byte[ebx]    ; smaller struct length
    
    mov ecx,0     ; carry acc
    min_loop:
        push edx
        cmp edi,edx
        jge max_loop
        movzx edx, ch
        movzx ecx, byte[eax + edi +1]
        add ecx, edx
        movzx edx, byte[ebx + edi +1]
        add ecx,edx
        mov byte[esi + edi +1], cl
        pop edx
        inc edi
        jmp min_loop
    max_loop:
        movzx  edx, byte[eax]
        push edx
        cmp edi,edx
        jge last_carry
        movzx edx, ch
        movzx ecx, byte[eax + edi +1]
        add  ecx,edx
        mov byte[esi + edi +1], cl
        pop edx
        inc edi
        jmp max_loop
    last_carry:
        movzx ebx, byte[esi]
        mov byte[esi+ebx],ch
        mov ecx,[esi+ebx]
        cmp ecx,0
        je  no_carry
    finished_addmulti:
        mov eax,esi
        add esp,8
        pop esp
        ret

    no_carry:
        dec ebx
        mov byte[esi],bl
        jmp finished_addmulti
 


;3.A
rand_num:
    push ebp
    mov ebp, esp
    mov ax, [STATE]
    mov bX, [MASK]

    xor bx, ax
    jp even_case
    

    STC 
    RCR ax,1
    jmp end_PRNG

    even_case:
        shr ax,1

    end_PRNG:   
        mov [STATE] ,ax
        mov  eax, [STATE]
        mov     esp, ebp
        pop     ebp
        ret      

;3.B
PRmulti:
    push    ebp
    mov     ebp, esp
    sub     esp, 4
    pushad

rand_length:
    call    rand_num
    cmp     eax,0
    jle     rand_length
    mov     ebx,eax
    push    ebx
    call    malloc
    pop ebx
    mov esi,eax
    mov byte [esi], bl
    mov ecx, 0

rand_multi:
    call rand_num
    mov     byte [esi+ecx+1], al
    inc     ecx
    cmp     ecx,ebx
    jl      rand_multi
    mov     eax, esi
    mov     [ebp-4],eax
    popad
    mov     eax, [ebp-4]
    mov     esp, ebp
    pop     ebp
    ret