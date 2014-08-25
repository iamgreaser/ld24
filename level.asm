lvl_load:
	movea.l a0,a1
	
	; blank out entities
	move.w #(ent_sizeof*rENT_MAX)/4-1,d0
	movea.l #rENT_START, a0
	clr.l d1
lp_lvl_load_clearents:
	move.l d1, (a0)+
	dbra d0, lp_lvl_load_clearents
	
	; clear USED pointer
	move.l #0, rENT_USED
	
	; prep entities
	clr.w d0
	move.b (a1)+,d0
	addq.l #1,a1
	movea.l #rENT_START,a0
lp_lvl_load_entities:
		; load X/Y
		clr.w d1
		clr.w d2
		move.b (a1)+,d1
		move.b (a1)+,d2
		lsl.w #5,d1
		lsl.w #5,d2
		move.w d1,ent_x(a0)
		move.w d2,ent_y(a0)
		
		; load init pointer and run
		movea.l (a1)+,a3
		movem.l a0/a1/d0,-(a7)
		jsr (a3)
		movem.l (a7)+,a0/a1/d0
		
		; set "next" pointer
		movea.l rENT_USED,a2
		move.l a2,d6
		tst.l d6
		beq.b lvl_load_entities_prevnull
			move.l a0,ent_prev(a2)
lvl_load_entities_prevnull:
		move.l rENT_USED,ent_next(a0)
		move.l a0,rENT_USED
		
		; advance
		moveq.l #ent_sizeof,d1
		adda.l d1, a0
		dbra d0,lp_lvl_load_entities
	
	; set FREE pointer
	move.l a0, rENT_FREE
	
	; skip TGA header and whatnot
	clr.l d0
	move.b 5(a1),d0
	move.b d0,d1
	add.b d1,d1
	add.b d1,d0
	lea $12(a1,d0), a1
	
	; ok, in this part we need to decode the RLE.
	; it's easier than encoding it, trust me :)
	move.w #(64*64)-1,d0
	movea.l #rLVL_START,a0
	move.b #0,d1 ; RLELEN
lp_lvl_load_tiles:
	cmpi.b #$00,d1
	beq.b lp_lvl_load_tiles_reload
	cmpi.b #$80,d1
	beq.b lp_lvl_load_tiles_reload
	bcs.b lp_lvl_load_tiles_literal
		; RLE: copy last tile
		; someone will kill me for doing it THIS way XD
		move.b -1(a0),(a0)+
		bra.b lpc_lvl_load_tiles
lp_lvl_load_tiles_reload:
		; load new tile
		move.b (a1)+,d1
		move.b (a1)+,(a0)+
		bra.b lps_lvl_load_tiles
lp_lvl_load_tiles_literal:
		; LITERAL: copy tile
		move.b (a1)+,(a0)+
lpc_lvl_load_tiles:
	subq #1,d1
lps_lvl_load_tiles:
	dbra d0, lp_lvl_load_tiles
	
	; set the camera
	movea.l #rENT_START,a0
	jsr obj_player_upcam
	
	; draw level
	jsr lvl_draw
	
	; draw background
	jsr lvl_drawbg
	
	rts

	align 4
lvl_drawbg_tab_rnd:
	dc.b $00,$00,$00,$06,$00,$00,$00,$00
	dc.b $00,$00,$00,$00,$04,$00,$00,$00
	dc.b $00,$05,$00,$00,$00,$00,$00,$00
	dc.b $00,$00,$00,$00,$00,$00,$00,$00
	align 4
lvl_drawbg:
	; set VDP pointer
	move.w $C00004,d0
	move.l #$40000003,$C00004
	
	; get pointers
	move.l #$43175983,d0
	movea.l rLVL_TILES,a1
	movea.l #lvl_drawbg_tab_rnd,a2
	
	; allocate tiles on stack
	move.l #32*32,d7
	movea.l a7,a0
	suba.l d7,a7
	move.l a0,-(a7)
	move.l a7,a0
	addq.l #4,a0
	movea.l a0,a3
	subq.l #1,d7
lp_lvl_drawbg_lfsr:
		lsr.l #1,d0
		bcc.b lp_lvl_drawbg_lfsr_noxor
			eor.l #$BA492759,d0 ; yeah, keyboard-random ftw
lp_lvl_drawbg_lfsr_noxor:
		move.b d0,d1
		andi.w #$001F,d1
		move.b (a2,d1),d1
		move.b d1,(a3)+
		dbra d7,lp_lvl_drawbg_lfsr
	
	; now loop
	move.w #32-1,d7
lp_lvl_drawbg_my:
		; (Y&1)==0
		move.w #32-1,d6
lp_lvl_drawbg_mx1:
			clr.l d0
			move.b (a0)+,d0
			lsl.w #4,d0
			move.w 0(a1,d0),$C00000
			move.w 2(a1,d0),$C00000
			dbra d6,lp_lvl_drawbg_mx1
		suba.l #32,a0
		
		; (Y&1)==1
		move.w #32-1,d6
lp_lvl_drawbg_mx2:
			clr.w d0
			move.b (a0)+,d0
			lsl.w #4,d0
			move.w 4(a1,d0),$C00000
			move.w 6(a1,d0),$C00000
			dbra d6,lp_lvl_drawbg_mx2
		
		dbra d7,lp_lvl_drawbg_my
	
	; return
	movea.l (a7)+,a0
	movea.l a0,a7
	rts

lvl_draw:
	; set VDP pointer
	move.w $C00004,d0
	move.l #$60000003,$C00004
	
	; set "old" cam pos
	move.w #0, rCAM_X
	move.w #0, rCAM_Y
	move.w #0, rCAM_CX
	move.w #0, rCAM_CY
	move.w #-(CAM_UPDX*32), rCAM_OLDX
	move.w #-(CAM_UPDY*32), rCAM_OLDY
	
	; get pointers
	movea.l #rLVL_START,a0
	movea.l rLVL_TILES,a1
	clr.l d0
	
	; now loop
	move.w #32-1,d7
lp_lvl_draw_my:
		; (Y&1)==0
		move.w #32-1,d6
lp_lvl_draw_mx1:
			clr.w d0
			move.b (a0)+,d0
			lsl.w #4,d0
			move.w 0(a1,d0),$C00000
			move.w 2(a1,d0),$C00000
			dbra d6,lp_lvl_draw_mx1
		suba.l #32,a0
		
		; (Y&1)==1
		move.w #32-1,d6
lp_lvl_draw_mx2:
			clr.w d0
			move.b (a0)+,d0
			lsl.w #4,d0
			move.w 4(a1,d0),$C00000
			move.w 6(a1,d0),$C00000
			dbra d6,lp_lvl_draw_mx2
		adda.l #64-32,a0
		
		dbra d7,lp_lvl_draw_my
	
	; scroll Y into place
	move.w rCAM_Y,d0
	sub.w rCAM_OLDY,d0
	asr.w #5,d0
	dbra d0,lp_lvl_draw_fixy
	bra.b lpx_lvl_draw_fixy
lp_lvl_draw_fixy:
		move.w d0,-(a7)
		jsr lvl_scroll_yp
		move.w (a7)+,d0
		dbra d0,lp_lvl_draw_fixy
lpx_lvl_draw_fixy:
	
	; scroll X into place
	move.w rCAM_X,d0
	sub.w rCAM_OLDX,d0
	asr.w #5,d0
	dbra d0,lp_lvl_draw_fixx
	bra.b lpx_lvl_draw_fixx
lp_lvl_draw_fixx:
		move.w d0,-(a7)
		jsr lvl_scroll_xp
		move.w (a7)+,d0
		dbra d0,lp_lvl_draw_fixx
lpx_lvl_draw_fixx:
	
	; the "old" X and Y should be equal to the current X/Y by now!
	
	; return
	rts

lvl_scroll_yp:
	move.w rCAM_OLDX, d1
	move.w rCAM_OLDY, d2
	asr.w #5,d1
	asr.w #5,d2
	addi.w #CAM_UPDX-32, d1
	addi.w #CAM_UPDY, d2
	
	jsr lvl_scroll_y_main
	
	addi.w #32, rCAM_OLDY
	rts

lvl_scroll_yn:
	subi.w #32, rCAM_OLDY
	
	move.w rCAM_OLDX, d1
	move.w rCAM_OLDY, d2
	asr.w #5,d1
	asr.w #5,d2
	addi.w #CAM_UPDX-32, d1
	addi.w #CAM_UPDY-32, d2
	
	jsr lvl_scroll_y_main
	rts
	
lvl_scroll_y_ret1:
	rts
	
lvl_scroll_y_main:
	; clamp and/or return
	btst #15,d1
	beq.b lvl_scroll_y_nocxn
		clr.w d1
lvl_scroll_y_nocxn:
	move.w d2,d0
	andi.w #$FFC0,d0
	bne.b lvl_scroll_y_ret1
	andi.w #$003F,d1
	andi.w #$003F,d2
	
	; get address
	clr.l d0
	move.w d2,d0
	lsl.w #6,d0
	
	add.w d1,d0 ; NOTE, DO NOT MASK THE TOP BITS OUT!
	andi.w #$FFE0,d0 ; low 5 bits of X must be clear
	movea.l #rLVL_START+32,a2 ; yeah, we kinda need the offset.
	adda.l d0,a2
	
	; get tile data pointer
	movea.l rLVL_TILES,a1
	
	; calc VDP address
	move.w d2,d0
	andi.w #$001F,d0 ; only need low 5 bits of Y
	rol.w #7+1,d0
	ori.w #$6000,d0
	swap d0
	move.w #$0003,d0
	move.l d0,$C00004
	
	; this should save my tired fingers
	jsr lvl_scroll_y_line
	addq.l #4,a1
	jsr lvl_scroll_y_line
	
	rts

lvl_scroll_y_line:
	
	; set d3 (X1),d4 (X2) correctly
	move.w #31,d4
	move.w d1,d3
	andi.w #$001F,d3
	
	; spew it out
lp_lvl_scroll_y_step1a:
		; check if doing prev line
		dbra d3,j_lvl_scroll_y_skipwrap
			suba.l #32,a2
j_lvl_scroll_y_skipwrap:
		
		; get tile data
		clr.l d5
		move.b (a2)+,d5
		lsl.w #4,d5
		move.w 0(a1,d5),$C00000
		move.w 2(a1,d5),$C00000
		
		; loop
		dbra d4,lp_lvl_scroll_y_step1a
	
	rts

lvl_scroll_xp:
	move.w rCAM_OLDX, d1
	move.w rCAM_OLDY, d2
	asr.w #5,d1
	asr.w #5,d2
	addi.w #CAM_UPDX, d1
	addi.w #CAM_UPDY-32, d2
	
	jsr lvl_scroll_x_main
	
	addi.w #32, rCAM_OLDX
	rts

lvl_scroll_xn:
	move.w rCAM_OLDX, d1
	move.w rCAM_OLDY, d2
	asr.w #5,d1
	asr.w #5,d2
	addi.w #CAM_UPDX-32, d1
	addi.w #CAM_UPDY-32, d2
	
	subi.w #32, rCAM_OLDX
	
	jsr lvl_scroll_x_main
	rts

lvl_scroll_x_ret1:
	rts
	
lvl_scroll_x_main:
	; clamp and/or return
	btst #15,d2
	beq.b lvl_scroll_x_nocyn
		clr.w d2
lvl_scroll_x_nocyn:
	move.w d1,d0
	andi.w #$FFC0,d0
	bne.b lvl_scroll_x_ret1
	andi.w #$003F,d1
	andi.w #$003F,d2
	
	; get RAM address
	clr.l d0
	move.w d2,d0
	lsl.w #6,d0
	add.w d1,d0
	movea.l #rLVL_START,a2
	adda.l d0,a2
	
	; get tile data pointer
	movea.l rLVL_TILES,a1
	
	; get VDP address
	move.w d1,d3
	move.w d2,d4
	andi.w #$001F,d3
	andi.w #$001F,d4
	move.w d4,d7
	lsl.w #6,d7
	add.w d3,d7
	add.w d7,d7
	add.w d7,d7
	ori.w #$6000,d7
	swap d7
	move.w #$0003,d7
	
	; now do each cell
	move.w #31,d0
lp_lvl_scroll_x:
		; get tile
		clr.w d5
		move.b (a2), d5
		adda.l #64, a2
		lsl.w #4,d5
		
		; now dump the gfx to VRAM
		move.l d7,$C00004
		move.w 0(a1,d5), $C00000
		move.w 2(a1,d5), $C00000
		addi.l #$00800000,d7
		move.l d7,$C00004
		move.w 4(a1,d5), $C00000
		move.w 6(a1,d5), $C00000
		addi.l #$00800000,d7
		andi.l #$7FFFFFFF,d7 ; wrap
		ori.l  #$60000000,d7 ; also wrap
		
		; loop
		dbra d0, lp_lvl_scroll_x
	
	; That was more straightforward than the Y scroll, right?
	; (No, of course I wasn't going to change the increment register.)
	rts
