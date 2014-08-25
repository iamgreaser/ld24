
vgm_stop:
	; uh yeah.
	move.l #0, rVGM_PTR
	rts

vgm_load:
	; check if A0 == base pointer
	move.l a0,d0
	cmp.l rVGM_BASEPTR,d0
	beq.b vgm_load_ret1
	
	; stash stuff to run the VGM stream.
	clr.l rVGM_TICK
	move.l a0,rVGM_PTR
	move.l a0,rVGM_BASEPTR
	addi.l #$40,rVGM_PTR
	move.l a0,rVGM_LPPTR
	addi.l #$40,rVGM_LPPTR
	
	; calculate loop samples
	move.l #-1,d0
	move.l $20(a0),d1
	rol.w #8,d1
	swap d1
	rol.w #8,d1
	tst.l d1
	beq.b vgm_no_loop
		move.l $18(a0),d0
		rol.w #8,d0
		swap d0
		rol.w #8,d0
		sub.l d1,d0
vgm_no_loop:
	subq #1,d0
	move.l d0,rVGM_LPSAMPS
	
	; return
vgm_load_ret1:
	rts

fm_wait:
	move.b $A04000,d0
	btst #7,d0
	bne.b fm_wait
	rts
;
; VGM PLAYROUTINE
;
vgm_play:
	; get pointer
	movea.l rVGM_PTR,a0
	
	; check if 0, if so return
	move.l a0,d0
	tst.l d0
	bne.b j_vgm_play_not0
		rts
j_vgm_play_not0:
	
	; check loop sample count
	btst #31,rVGM_LPSAMPS
	bne.b vgm_play_hasstheloop
	subi.l #735,rVGM_LPSAMPS
	btst #31,rVGM_LPSAMPS
	beq.b vgm_play_hasstheloop
	
	; set the restart pointer
	move.l a0,rVGM_LPPTR
	
vgm_play_hasstheloop:

	; check tick count
	subi.l #735,rVGM_TICK
vgm_play_lp_outer:
	btst #31,rVGM_TICK
	beq vgm_play_lpx_main
	
	; now read stuff!
vgm_play_lp_main:
		move.b (a0)+,d0
		
		; PSG
		cmpi.b #$50,d0
		bne.b vgm_play_not_psg
			move.b (a0)+,$C00011
			bra.b vgm_play_lp_main
vgm_play_not_psg:
		
		; YM2612/OPN2 port 0
		cmpi.b #$52,d0
		bne.b vgm_play_not_fm0
			jsr fm_wait
			move.b (a0)+,$A04000
			jsr fm_wait
			move.b (a0)+,$A04001
			bra.b vgm_play_lp_main
vgm_play_not_fm0:
		
		; YM2612/OPN2 port 1
		cmpi.b #$53,d0
		bne.b vgm_play_not_fm1
			jsr fm_wait
			move.b (a0)+,$A04002
			jsr fm_wait
			move.b (a0)+,$A04003
			bra.b vgm_play_lp_main
vgm_play_not_fm1:
		
		; the crapload of delays
		
		; $62 - 735
		clr.l d1
		move.w #735,d1
		cmpi.b #$62,d0
		beq.b vgm_play_delay

		; $63 - 882
		move.w #882,d1
		cmpi.b #$63,d0
		beq.b vgm_play_delay		
		
		; $7x - x+1 samples
		clr.l d1
		move.b d0,d1
		move.b d0,d2
		andi.b #$F0,d2
		andi.b #$0F,d1
		cmpi.b #$70,d2
		beq.b vgm_play_delay
		
		; $61 xx xx - xx samples
		cmpi.b #$61,d0
		bne.b vgm_play_nodelay
			clr.l d1
			clr.l d2
			move.b (a0)+,d1
			move.b (a0)+,d2
			lsl.w #8,d2
			or.w d2,d1
vgm_play_delay:
			add.l d1,rVGM_TICK
			bra vgm_play_lp_outer
vgm_play_nodelay:
		
		; end of stream
		cmpi.b #$66,d0
		bne.b vgm_play_not_end
			movea.l rVGM_LPPTR,a0
			bra.w vgm_play_lp_main
vgm_play_not_end:
		
		; TODO!
		
		jmp vgm_play_lp_main
vgm_play_lpx_main:
	
	; stash pointer and return
	move.l a0,rVGM_PTR
	rts

