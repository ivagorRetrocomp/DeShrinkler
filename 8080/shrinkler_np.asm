; Shrinkler decompressor Intel 8080 version by Ivan Gorodetsky 
; v1 - 2019-10-04
; v2 - 2020-12-31 (no parity context)
; Based on Madram/OVL Z80 version vA
; Use Shrinkler4.6NoParityContext for compression!
;
; Input:
; HL=source
; DE=destination		- it has to be even!
; call shrinkler_decrunch
;
; 311 bytes
;
; compress files with -d -9 -p options

; you may change probs to point to any 256-byte aligned free buffer (size 2.5 Kilobytes)
probs			.equ 08000h
probs_ref		.equ probs+400h
probs_length	.equ probs_ref
probs_offset	.equ probs_length+200h


getnumber:
_numberloop:
		inr l
		inr l
		call getbit
		jc _numberloop
regBC:
		lxi b,1
_bitsloop:
		dcr l
		push b
		call getbit
		pop b
		mov a,c\ ral\ mov c,a
		mov a,b\ ral\ mov b,a
		dcr l
		jnz _bitsloop
exDE:
		push h
		xchg
regDE:
		lxi d,0
		shld regDE+1
		pop h
		ret

readbit:
		xchg
		dad h
		xchg
		push h
regA:
		mvi a,0
		add a
		jnz _rbok
regIX:
		lxi h,0
		mov a,m
		inx h
		shld regIX+1
		ral
_rbok:
		sta regA+1
d2:
		lxi h,0
		mov a,l\ ral\ mov l,a
		mov a,h\ ral\ mov h,a
		shld d2+1
		pop h
		jmp getbit

getkind:
		call exDE
		lxi h,probs
getbit:
		xra a
		ora d
		jp readbit
		mov b,m
		inr h
		mov c,m
		push h
		mov h,b
		mov l,c
		xra a
		dad h\ ral
		dad h\ ral
		dad h\ ral
		dad h\ ral
		mov l,h
		mov h,a
		mov a,c\ sub l\ mov l,a
		mov a,b\ sbb h\ mov h,a
		push h
		mov a,c
		mvi c,0
		call mul24
		mov l,h
		mov h,a
		push h
		mov a,b
		call mul24
		pop b
		dad b
		mov c,h
		aci 0
		mov b,a
		lhld d2+1
		mov a,l\ sub c\ mov l,a
		mov a,h\ sbb b
		jnc zero
one:
		mov e,c
		mov d,b
		pop b
		mov a,b
		sui 0F0h
		mov b,a
		dcx b
		jmp _probret

shrinkler_decrunch:
		shld regIX+1
		call exDE
		xra a
		mov l,a
		mov h,a
		shld d2+1			;d2=0
		lxi h,10*256+probs
		mvi b,10
init:
		dcr h
iniloop:
		mov m,a
		inr l
		jnz iniloop
		sta regA+1
		xri 80h
		mov e,b
		dcr b
		jnz init
		mov d,b
literal:
		stc
getlit:
		cnc getbit
		mov a,l\ ral\ mov l,a
		jnc getlit
		call exDE
		stax d
		inx d
		call getkind
		jnc literal
		mvi h,probs_ref/256
		call getbit
		jnc readoffset
readlength:
		mvi h,probs_length/256
		call getnumber
Offset:
		lxi h,0
		dad d
		mov a,m
		stax d
		inx h
		inx d
		dcx b
		mov a,c
		ora b
		jnz $-7
		call getkind
		jnc literal
readoffset:
		mvi h,probs_offset/256
		call getnumber
		mvi a,2\ sub c\ sta Offset+1
		mvi a,0\ sbb b\ sta Offset+2
		call exDE
		jnz readlength
		ret

zero:
		mov h,a
		shld d2+1
		mov a,e\ sub c\ mov e,a
		mov a,d\ sbb b\ mov d,a
		pop b
_probret:
		pop h
		mov m,c
		dcr h
		mov m,b
		ret

mul24:
		mov h,c
		mov l,c
		call $+4
		dad h\ adc a\ jnc $+5\ dad d\ adc c
		dad h\ adc a\ jnc $+5\ dad d\ adc c
		dad h\ adc a\ jnc $+5\ dad d\ adc c
		dad h\ adc a\ rnc\ dad d\ adc c
		ret
packed:

		.end
