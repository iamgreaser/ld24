
;
; VDP RESET ROUTINE
;

vdp_reset:
	; load a buttload of VDP registers.
	move.w #((vdp_setupregs_end-vdp_setupregs)>>1)-1,d0
	movea.l #vdp_setupregs,a0
lp_vdp_reset_setupregs:
	move.w $C00004,d1
	move.w (a0)+,$C00004
	dbra d0,lp_vdp_reset_setupregs
	move.w $C00004,d0
	
	; clear VRAM
	move.l #$40000000,$C00004
	move.w #$8000-1,d0
	clr.l d1
lp_vdp_reset_clearvram:
	move.w d1,$C00000
	dbra d0,lp_vdp_reset_clearvram
	
	; clear VSRAM
	move.l #$40000010,$C00004
	move.w #$28-1,d0
lp_vdp_reset_clearvsram:
	move.w d1,$C00000
	dbra d0,lp_vdp_reset_clearvsram
	
	; clear CRAM
	move.w #64-1,d0
	move.l #$C0000000,$C00004
lp_vdp_reset_palette:
	move.w #$0000,$C00000
	dbra d0,lp_vdp_reset_palette
	
	; return
	rts

	align 1
vdp_setupregs:
	; $E000 - scroll A
	; $C000 - scroll B
	; $B000 - window
	; $AC00 - hscroll table
	; $A800 - sprites
	dc.w $8124, $8004 ; FALGS
	dc.w $8200|(($E0>>5)<<3) ; SCRALL A (5-3)
	dc.w $8300|(($B0>>4)<<2) ; SCRALL WANDOE (5-1+)
	dc.w $8400|(($C0>>5)<<0) ; SCRALL B (2-0)
	dc.w $8500|(($A8>>2)<<1) ; SPORTS (6-0+)
	dc.w $8700 ; BRODER
	dc.w $8A00 ; HORESONTLA ENTIROPT
	dc.w $8B00, $8C81 ; FALGS AGEN - these affect scroll/width mostly.
	dc.w $8D00|(($AC>>2)<<0) ; HORESONTLA SCRALL TBOLE (5-0)
	dc.w $8F02 ; ADRIS ORTO ENTCRAMOT
	dc.w $9011 ; SCRALL SOIZ
	dc.w $9100, $9200 ; WANDOE
vdp_setupregs_end:
