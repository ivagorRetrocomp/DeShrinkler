; Shrinkler decompressor Intel 8088/8086 version by Ivan Gorodetsky. Compile with FASM
; Based on Madram/OVL Z80 version
;
; v1 (2019-10-09) - 217 bytes
; v2 (2019-10-10) - 192 bytes and 30% faster
; Memory model - Tiny
;
; Input:
; SI=source
; DI=destination  -  it has to be even!
; call shrinkler_decrunch

; you may change probs to point to any 256-byte aligned free buffer (size 2.5 Kilobytes)
probs		equ 0F400h
probs_ref	equ probs+400h
probs_length	equ probs_ref
probs_offset	equ probs_length+200h


getnumber:
_numberloop:
		inc bx
		inc bx
		call getbit
		jc _numberloop
		push di
		mov di,1
_bitsloop:
		dec bx
		call getbit
		rcl di,1
		dec bl
		jnz _bitsloop
		mov cx,di
		pop di
		ret

getkind:
		test di,1
		mov bx,(probs)
		jz getbit
		mov bh,(probs+512)/256
		jmp getbit

readbit:
		shl dx,1
		shl al,1
		jnz _rbok
		lodsb
		rcl al,1
_rbok:
		rcl bp,1
getbit:
		test dx,dx
		jns readbit
		push ax
		mov ah,[bx]
		inc bh
		mov al,[bx]
		push bx
		mov bx,ax
		mov cl,4
		shr bx,cl
		neg bx
		add bx,ax
		mov cx,dx
		mul cx
		mov ax,bx
		cmp bp,dx
		jnc zero
one:
;d3=d1*d3
;bx=d1-d1/16
		sub ax,0F001h
		jmp _probret

;SI - source
;DI - destination
shrinkler_decrunch:
		cld
		mov bx,10*256+(probs)
		mov cx,10
		mov ax,0080h
init:
		dec bh
iniloop:
		mov [bx],ah
		inc bl
		jnz iniloop
		xor ah,al
		mov dx,cx
		loop init
		xor bp,bp
literal:
		stc
		jmp getlit_
getlit:
		call getbit
getlit_:
		rcl bl,1
		jnc getlit
		mov [di],bl
		inc di
		call getkind
		jnc literal
		mov bh,(probs_ref)/256
		call getbit
		jnc readoffset
readlength:
		mov bh,(probs_length)/256
		call getnumber
		mov bx,si
		mov si,[ofs]
		add si,di
		rep movsb
		mov si,bx
		call getkind
		jnc literal
readoffset:
		mov bh,(probs_offset)/256
		call getnumber
		neg cx
		inc cx
		inc cx
		mov [ofs],cx
		jnz readlength
		ret

zero:
		sub bp,dx
		sub cx,dx
		mov dx,cx
_probret:
		pop bx
		mov [bx],al
		dec bh
		mov [bx],ah
		pop ax
		ret

ofs:		dw 0
