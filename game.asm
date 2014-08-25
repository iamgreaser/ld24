;
; FINALLY SORTING THIS CRAP OUT
;

game_main:
	; clear registers
	clr.l d0
	clr.l d1
	clr.l d2
	clr.l d3
	clr.l d4
	clr.l d5
	clr.l d6
	clr.l d7
	
	suba.l a0,a0
	suba.l a1,a1
	suba.l a2,a2
	suba.l a3,a3
	suba.l a4,a4
	suba.l a5,a5
	suba.l a6,a6
	
	; blank screen
	move.w $C00004,d0
	move.w #$8124,$C00004
	move.w $C00004,d0
	
	; clear entity list
	move.w #(ent_sizeof*rENT_MAX)/4,d0
	movea.l #rENT_START,a0
lp_game_main_clearents:
		clr.l (a0)+
		dbra d0,lp_game_main_clearents
	
	; reset level
	movea.l rLVL_LOADFN, a3
	jsr (a3)
	
	; check if we need to load the next part
	tst.w d0
	beq.b game_main
	
	; scroll X/Y
	movea.l #rENT_START,a0
	jsr obj_player_upcam
	
	move.w rCAM_X,rCAM_CX
	move.w rCAM_Y,rCAM_CY
	
	move.w $C00004,d0
	move.l #$6C000002,$C00004
	move.w rCAM_CX,d0
	asr.w #1,d0
	neg.w d0
	move.w d0,$C00000
	asr.w #1,d0
	move.w d0,$C00000
	move.l #$40000010,$C00004
	move.w rCAM_CY,d0
	asr.w #1,d0
	move.w d0,$C00000
	asr.w #1,d0
	move.w d0,$C00000
	
	; appearify screen
	move.w $C00004,d0
	move.w #$8164,$C00004
	move.w $C00004,d0
	
	; main loop
	move.w #1,rTICK_CTR
lp_game_main:
	jsr game_tick
	subq.w #1,rTICK_CTR
lp_game_main_idle:
	tst.w rTICK_CTR
	bne.b lp_game_main
	stop #$2000
	move.w rENT_START+ent_flags,d0
	btst #EFB_PLAYER,d0
	bne.b lp_game_main_idle
	
	; let's do it again!
	bra game_main
	
	; include levels
	include "lv01.asm"

game_doents:
	movea.l ent_fn_tick(a0), a3
	jsr (a3)
	movea.l ent_next(a0), a0
	move.l a0,d0
	tst d0
	bne.b game_doents
	rts

game_drawents:
	; load X,Y
	move.w ent_x(a0),d1
	move.w ent_y(a0),d2
	sub.w rCAM_CX,d1
	sub.w rCAM_CY,d2
	asr.w #1,d1
	asr.w #1,d2
	addi.w #$0080,d1
	addi.w #$0080,d2
	
	; check if in range
	cmpi.w #$0060,d1
	blt.b game_drawents_skipspr
	cmpi.w #$0060,d2
	blt.b game_drawents_skipspr
	cmpi.w #$0080+320+32,d1
	bgt.b game_drawents_skipspr
	cmpi.w #$0080+224+32,d2
	bgt.b game_drawents_skipspr
	
	; draw sprite
	; Y
	move.w d2,$C00000
	
	; flags / link
	move.w 2(a0),d0
	move.b #$00,d0
	move.l ent_next(a0),d4
	tst.l d4
	beq.b game_drawents_linknull
		move.b d7,d0
		addi.b #1,d7
		; TODO? overflow check?
game_drawents_linknull:
	move.w d0,$C00000
	
	; tile
	move.w 4(a0),$C00000
	
	; X
	move.w d1,$C00000
	
game_drawents_skipspr:
	; get next and check
	move.l ent_next(a0),d4
	movea.l d4,a0
	tst.l d4
	bne.b game_drawents
	rts

game_tick:
	; scroll thing
	move.w $C00004,d0
	move.l #$6C000002,$C00004
	move.w rCAM_CX,d0
	asr.w #1,d0
	neg.w d0
	move.w d0,$C00000
	asr.w #1,d0
	move.w d0,$C00000
	move.l #$40000010,$C00004
	move.w rCAM_CY,d0
	asr.w #1,d0
	move.w d0,$C00000
	asr.w #1,d0
	move.w d0,$C00000
	
	; draw entity sprites
	movea.l rENT_USED, a0
	move.w $C00004,d0
	move.l #$68000002,$C00004
	move.b #$0001,d7
	jsr game_drawents
	
	; update entities
	movea.l rENT_USED, a0
	jsr game_doents
	
	; cache new X,Y
	move.w rCAM_X,rCAM_CX
	move.w rCAM_Y,rCAM_CY
	
	rts

game_walloftext:
	; clear tilemaps
	move.w $C00004,d0
	move.l #$40000003,$C00004
	move.w #64*64*2-1,d0
lp_game_walloftext_cleartm:
	move.w #$0000,$C00000
	dbra d0, lp_game_walloftext_cleartm
	
	; clear sprites
	move.w $C00004,d0
	move.l #$68000002,$C00004
	clr.l $C00000
	clr.l $C00000
	
	; clear scroll
	move.w $C00004,d0
	move.l #$6C000002,$C00004
	clr.l $C00000
	move.l #$40000010,$C00004
	clr.l $C00000
	
	; write text
	move.w $C00004,d0
	move.l #$60000003,d3
	move.w #$0200,d0
lp_game_walloftext:
		move.l d3,$C00004
		addi.l #$00800000,d3
lp_game_walloftext_x:
		move.b (a0)+,d0
		cmpi.b #$00,d0
		beq.b lp_game_walloftext
		subi.b #$20,d0
		move.w d0,$C00000
		btst #7,d0
		beq.b lp_game_walloftext_x
	
	;bra *
	
	; appearify screen
	move.w $C00004,d0
	move.w #$8164,$C00004
	move.w $C00004,d0
	
	; wait for button
game_walloftext_waiton:
	stop #$2000
	move.b rJOYVALS0,d0
	andi.b #$F0,d0
	cmpi.b #$F0,d0
	beq.b game_walloftext_waiton
game_walloftext_waitoff:
	stop #$2000
	move.b rJOYVALS0,d0
	andi.b #$F0,d0
	cmpi.b #$F0,d0
	bne.b game_walloftext_waitoff
	
	rts