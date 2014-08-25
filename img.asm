
;
; IMAGE LOADING CRAP
;

; WARNING! THIS ASSUMES STUFF!
; - each dimension is divisible by 8
; - image is top-left RLE
; - colourmap is 16 entries, 24bpp
; - NO IMAGE ID
; - data is 8bpp

; a0 = src image
; d0 = dest VRAM
; d1 = dest CRAM
img_load_tga:
	; skip to WxH
	move.l #$0C,a1
	adda.l a1,a0
	
	; load WxH
	move.w (a0)+,d6 ; W
	ror.w #8,d6
	move.w (a0)+,d7 ; H
	ror.w #8,d7
	
	; skip to colour map
	addq.l #2,a0
	
	; load colour map
	move.w $C00004,d2
	move.l d1,$C00004
	move.w #16-1,d2
lp_img_load_tga_cmap:
		move.b (a0)+,d3
		andi.b #$F0,d3
		move.b (a0)+,d4
		andi.b #$0F,d4
		move.b (a0)+,d5
		andi.b #$0F,d5
	
		or.b d3,d4
		lsl.w #4,d4
		or.w d5,d4
	
		andi.w #$0EEE,d4
		move.w d4,$C00000
		dbra d2,lp_img_load_tga_cmap
	
	; set VRAM pointer
	move.w $C00004,d2
	move.l d0,$C00004
	
	; redo WxH to be in tiles
	; D5 will contain W in pixels
	move.l d6,d5
	lsr.l #3,d7
	lsr.l #3,d6
	
	; allocate stack space for 256x8 image data
	clr.l d2
	move.w d5,d2
	lsl.l #3,d2
	movea.l a7,a2
	suba.l d2,a7
	
	; do 8 rows at a time
	; do this 16 times
	move.w d7,d0
	subq.w #1,d0
lp_img_load_tga_rle_outer:
		; prep some registers
		movea.l a7,a1 ; dest ptr
		
		; loop
lp_img_load_tga_rle_each:
			; load and check
			clr d1
			move.b (a0)+,d1
			btst #7,d1
			beq.b lp_img_load_tga_rle_straight
			
			; top bit 1 - RLE
			; load our byte
			move.b (a0)+,d2
			
			; copy it (d1-127) times
			subi.b #128,d1
lp_img_load_tga_rle_repeat:
				move.b d2,(a1)+
				dbra d1,lp_img_load_tga_rle_repeat
			bra.b lpc_img_load_tga_rle_each
			
			; top bit 0 - copy (d1+1) bytes
lp_img_load_tga_rle_straight:
				; nifty architecture abuse :D
				move.b (a0)+,(a1)+
				dbra d1,lp_img_load_tga_rle_straight
lpc_img_load_tga_rle_each:
			; check if this row is over
			cmpa.l a2,a1
			bgt *
			bne lp_img_load_tga_rle_each
		
		; now load the data
		movea.l a7,a1 ; ptr
		move.l d5,a3
		subq.l #8,a3
		move.w d6,d1
		subq.w #1,d1
lp_img_load_tga_mkchunk:
			; set up Y loop
			movea.l a1,a4
			move.w #8-1,d3
lp_img_load_tga_mkchunk_y:
				; stitch each value in
				clr.l d2
				move.b (a4)+,d2
				rol.l #4,d2
				or.b (a4)+,d2
				rol.l #4,d2
				or.b (a4)+,d2
				rol.l #4,d2
				or.b (a4)+,d2
				rol.l #4,d2
				or.b (a4)+,d2
				rol.l #4,d2
				or.b (a4)+,d2
				rol.l #4,d2
				or.b (a4)+,d2
				rol.l #4,d2
				or.b (a4)+,d2
				
				; write to VRAM
				move.l d2,$C00000
				
				; increment a4 and loop
				adda a3,a4
				dbra d3,lp_img_load_tga_mkchunk_y
			
			; next please
			addq #8,a1
			dbra d1,lp_img_load_tga_mkchunk
		
		dbra d0,lp_img_load_tga_rle_outer
	
	; deallocate 256x8 buffer
	movea.l a2,a7
	
	rts

