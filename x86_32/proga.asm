section .text
global set_pixel
global load_pixel
global set_color
global copy_rect


copy_rect:	;copy_rect(imgInfo* pImg, Rect pSrc, Point pDst);
	; prologue
	push 	ebp
	mov 	ebp, esp
	; saved registers
	push 	edi
	push 	esi
	lea 	edi, [ebp+12]
	; edi+0 = left
	; edi+4 = top
	; edi+8 = right
	; edi+12 = bottom
	; edi+16 = x
	; edi+20 = y
	mov 	eax, [edi+20]	; eax = y
	cmp 	eax, [edi+4]	; cmp y, top
	jl 		case2
	je 		case3
case1:						; y > top, copying from top to bottom
	mov		ecx, [edi+4]	; ecx = y looop counter
	mov 	edx, [edi+0]	; edx = x loop counter
y1_loop:
	cmp 	ecx, [edi+12]
	jl 		end_copy
x1_loop:
	cmp 	edx, [edi+8]
	jg 		end_x1
	push 	ecx			
	push 	edx
	push 	dword [ebp+8]
	call 	load_pixel
	add 	esp, 4
	pop 	edx
	pop 	ecx
	push 	ecx
	push 	edx
	push 	eax				;ebp+12
	push 	dword [ebp+8]	;ebp+8
	call 	set_color
	add 	esp, 8
	pop 	edx
	pop 	ecx
	mov 	esi, [edi+20]
	add 	esi, ecx
	sub 	esi, [edi+4]
	push	ecx
	push	edx
	push	esi				; ebp + 16 = y + i - bottom
	mov 	esi, [edi+16]
	add 	esi, edx
	sub 	esi, [edi+0]	
	push	esi				; ebp + 12 = x + j - left 
	push	dword [ebp+8]
	call	set_pixel
	add 	esp, 12
	pop 	edx
	pop 	ecx
	inc 	edx
	jmp 	x1_loop	
end_x1:	
	dec	 	ecx
	mov 	edx, [edi+0]
	jmp 	y1_loop
	
case2:						; y < top, copying from bottom to top
	mov 	ecx, [edi+12]	; ecx = y loop counter
	mov 	edx, [edi+0]	; edx = x loop counter
y2_loop:
	cmp 	ecx, [edi+4]
	jg 		end_copy
x2_loop:
	cmp 	edx, [edi+8]
	jg 		end_x2
	push 	ecx
	push 	edx
	push 	dword [ebp+8]	
	call 	load_pixel
	add 	esp, 4
	pop 	edx
	pop 	ecx
	push 	ecx
	push 	edx
	push 	eax				;ebp+12
	push 	dword [ebp+8]	;ebp+8
	call 	set_color
	add 	esp, 8
	pop 	edx
	pop 	ecx
	mov 	esi, [edi+20]
	add 	esi, ecx
	sub 	esi, [edi+4]
	push	ecx
	push	edx
	push	esi				; ebp + 16 = y + i - bottom
	mov 	esi, [edi+16]
	add 	esi, edx
	sub 	esi, [edi+0]
	push	esi				; ebp + 12 = x + j - left 
	push	dword [ebp+8]
	call 	set_pixel
	add 	esp, 12
	pop 	edx
	pop 	ecx
	inc 	edx
	jmp 	x2_loop	
end_x2:
	inc 	ecx
	mov 	edx, [edi+0]
	jmp 	y2_loop
	
case3:						; y == top, x > left, copying from right to left
	mov 	eax, [edi+0]
	cmp 	eax, [edi+16]	; cmp left with x
	jg 		case2
	mov 	ecx, [edi+12]	; ecx = y loop counter
	mov 	edx, [edi+8]	; edx = x loop counter
y3_loop:	
	cmp 	ecx, [edi+4]
	jg 		end_copy
x3_loop:
	cmp 	edx, [edi+0]
	jl 		end_x3
	push 	ecx
	push 	edx
	push 	dword [ebp+8]	
	call 	load_pixel
	add 	esp, 4
	pop 	edx
	pop 	ecx
	push	ecx
	push	edx
	push 	eax				;ebp+12
	push 	dword [ebp+8]	;ebp+8
	call 	set_color
	add 	esp, 8
	pop 	edx
	pop 	ecx
	mov 	esi, [edi+20]
	add 	esi, ecx
	sub 	esi, [edi+4]
	push	ecx
	push	edx
	push 	esi				; ebp + 16 = y + i - bottom
	mov 	esi, [edi+16]
	add 	esi, edx
	sub 	esi, [edi+0]
	push	esi				; ebp + 12 = x + j - left 
	push	dword [ebp+8]
	call	set_pixel
	add 	esp, 12
	pop 	edx
	pop 	ecx
	dec 	edx
	jmp 	x3_loop	
end_x3:
	inc 	ecx
	mov 	edx, [edi+8]
	jmp 	y3_loop
end_copy:
	; saved registers
	pop 	esi
	pop 	edi
	; epilogue
	mov 	esp, ebp
	pop 	ebp
	ret
	
;=======================================================================

set_pixel:					;load_pixel(imgInfo* pInfo, int x, int y)
	push 	ebp           	; prologue
	mov 	ebp, esp
	lea 	ecx, [ebp + 8]	; ecx = &pInfo
	mov 	ecx, [ecx]
	mov 	eax, [ecx+0]	; eax = width
	cmp 	eax, [ebp+12]
	jle 	end_set
	mov 	edx, [ecx+4]	; edx = height
	cmp 	edx, [ebp+16]
	jle 	end_set
	add 	eax, 31			; eax = width + 31
	sar 	eax, 5			; eax = (width + 31) >> 5
	sal 	eax, 2			; eax = ((width + 31) >> 5) << 2
	mul 	DWORD [ebp+16]	; eax * y
	mov 	edx, [ebp+12]	; edx = x
	sar 	edx, 3			; edx = x>>3
	add 	eax, edx		; eax = ((width + 31) >> 5) << 2 * y + (x >> 3)
	mov 	edx, [ecx+8]	; edx = &pImg
	add 	eax, edx		; eax = pPix
	mov 	cl, byte[ebp+12]; cl = x
	and 	cl, 7			; (x&7)
	mov 	dh, 128			; dh = mask
	shr 	dh, cl			; dh = 128 >> (x&7)
	lea 	ecx, [ebp + 8]	; ecx = &pInfo
	mov 	ecx, [ecx]
	mov 	dl, [ecx+20]	; dl = col
	test	dl, dl 
	jz 		black
	mov 	ch, byte [eax]
	or 		ch, dh
	mov 	[eax], ch
	jmp 	end_set
black:
	mov 	ch, [eax]
	not 	dh
	and 	ch, dh
	mov 	[eax], ch
end_set:
	pop 	ebp            	; epilogue
	ret
	
;=======================================================================

load_pixel: 				;load_pixel(imgInfo* pInfo, int x, int y);
	push 	ebp          	; prologue
	mov 	ebp, esp
	lea 	ecx, [ebp + 8]	; ecx = &pInfo
	mov 	ecx, [ecx]
	mov 	eax, [ecx+0]	; eax = width
	cmp 	eax, [ebp+12]
	jle 	end_load
	mov 	edx, [ecx+4]	; edx = height
	cmp 	edx, [ebp+16]
	jle 	end_load
	add 	eax, 31			; eax = width + 31
	sar 	eax, 5			; eax = (width + 31) >> 5
	sal 	eax, 2			; eax = ((width + 31) >> 5) << 2
	mul 	DWORD [ebp+16]	; eax * y
	mov 	edx, [ebp+12]	; edx = x
	sar 	edx, 3			; edx = x>>3
	add 	eax, edx		; eax = ((width + 31) >> 5) << 2 * y + (x >> 3)
	mov 	edx, [ecx+8]	; edx = &pImg
	add 	eax, edx		; eax = pPix
	mov 	cl, byte[ebp+12]; cl = x
	and 	cl, 7			; (x&7)
	mov 	dh, 128			; dh = mask
	shr 	dh, cl			; dh = 128 >> (x&7)
	mov 	ch, byte [eax]
	and 	ch, dh
	movzx 	eax, byte ch
	pop 	ebp            	; epilogue
	ret
end_load:
	mov 	eax, 1
	pop 	ebp            	; epilogue
	ret
	
;=======================================================================

set_color: 					;set_color(imgInfo* pInfo, int col);
	push 	ebp          	; prologue
	mov 	ebp, esp
	lea 	ecx, [ebp + 8]	; ecx = &pInfo
	mov 	ecx, [ecx]
	mov 	edx, [ebp+12]
	mov 	[ecx+20], edx
	pop 	ebp
	ret
