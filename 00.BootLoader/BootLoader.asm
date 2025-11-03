; Matrix rain in 16-bit real mode (VGA text 80x25)
; build: nasm -f bin boot.asm -o boot.bin

[org 0x7C00]
[bits 16]

jmp start

; -------------------- util: 16-bit LFSR PRNG --------------------
; ax = next random (in-place)
rand16:
    shr ax, 1
    jnc .r_ok
    xor ax, 0xB400            ; CRC16 poly – 간단/작지만 충분
.r_ok:
    ret

; row*80+col -> BX (cell index), ES already = 0xB800
; IN:  BL=row(0..24), BH=0, DL=col(0..79)
calc_cell:
    mov si, bx                ; si = row
    shl bx, 6                 ; bx = row*64
    shl si, 4                 ; si = row*16
    add bx, si                ; bx = row*80
    xor dh, dh
    add bx, dx                ; + col
    shl bx, 1                 ; *2 (문자/속성 쌍)
    ret

; 소규모 지연 (속도조절)
delay:
    mov cx, 0x4000
.dlp: loop .dlp
    ret

; -------------------- entry --------------------
start:
    cli
    xor ax, ax
    mov ds, ax                ; DS=0 (BIOS data 접근용)
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ax, 0xB800
    mov es, ax                ; ES=비디오 메모리

; 화면 초기화 (검정/녹색으로 클리어)
    xor si, si
.clr:
    mov byte [es:si],  0
    mov byte [es:si+1], 0x02  ; 어두운 녹색
    add si, 2
    cmp si, 80*25*2
    jl  .clr

; 난수 seed – BIOS tick (0x40:0x6C)
    mov ax, [0x046C]

; 드롭 상태
; BL=row(0..24), DL=col(0..79), CH=trail attr, AH=head char
new_drop:
    call rand16
    xor dx, dx
    mov cx, 80
    div cx                    ; AX/CX -> AX=quot, DX=rem
    mov dl, dl                ; DX=col

    mov bl, 0                 ; row=0
    mov ch, 0x02              ; 꼬리(어두운 녹색)
    call rand16
    ; 문자: 33..126
    mov cx, 94
    xor dx, dx
    div cx                    ; AX%94 -> DX
    mov ah, dl
    add ah, 33

; 메인 루프 – 한 드롭이 바닥까지
main_loop:
    ; 위쪽(이전 row-1) 지우거나 연해지게
    cmp bl, 0
    je  .draw_head
    mov bh, 0
    mov dl, dl                ; keep col
    mov al, bl
    dec al                    ; prev row
    mov bl, al
    call calc_cell
    mov byte [es:bx], ' '     ; 빈칸
    mov byte [es:bx+1], 0x00  ; 검정
    mov bl, al                ; restore row
.draw_head:
    ; trail(현재 위치) 먼저 찍고
    mov bh, 0
    call calc_cell
    mov byte [es:bx], ah
    mov byte [es:bx+1], ch

    ; head는 한 칸 아래 (밝은 녹색)
    cmp bl, 24
    je  .spawn_next
    mov al, bl
    inc al
    mov bl, al
    call calc_cell
    mov byte [es:bx], ah
    mov byte [es:bx+1], 0x0A  ; 밝은 녹색
    mov bl, al

    ; 다음 프레임 세팅
    call rand16               ; 가끔 문자도 바뀌도록
    test ax, 0x0007
    jnz  .keep_char
    call rand16
    mov cx, 94
    xor dx, dx
    div cx
    mov ah, dl
    add ah, 33
.keep_char:

    call delay
    jmp main_loop

.spawn_next:
    ; 바닥 찍었으면 새로운 드롭
    call delay
    jmp new_drop

; -------------------- boot sig --------------------
times 510-($-$$) db 0
dw 0xAA55
