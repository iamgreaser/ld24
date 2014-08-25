
; A3 = init fn
; D1.w = X
; D2.w = Y
; return in A0
entity_init:
	movem.l d0-d7/a1-a6,-(a7)
	
	; find "free" head
	movea.l rENT_FREE, a0
	
	; clear data
	move.w #ent_sizeof-1,d0
	movea.l a0,a1
lp_entity_init_clear:
	move.b #$00,(a1)+
	dbra d0,lp_entity_init_clear
	
	; set position
	move.w d1,ent_x(a0)
	move.w d2,ent_y(a0)
	
	; link "free" and "used"
	movea.l rENT_USED, a1
	move.l a1, ent_next(a0)
	move.l a0, ent_prev(a1)
	move.l a0, rENT_USED
	
	; find next free thing
	movea.l a0, a1
lp_entity_init:
		adda.l #ent_sizeof, a1
		move.w ent_flags(a1), d0
		btst #EFB_ALLOC, d0
		bne.b lp_entity_init
	
	; set that as the free pointer
	move.l a1, rENT_FREE
	
	; run init code
	jsr (a3)
	movem.l (a7)+,d0-d7/a1-a6
	rts

; A0 = entity
entity_deinit:
	movem.l d0-d7/a1-a6,-(a7)
	
	; run deinit code
	movea.l ent_fn_deinit(a0),a3
	movem.l d0-d7/a0-a6,-(a7)
	jsr (a3)
	movem.l (a7)+,d0-d7/a0-a6
	
	; skip this entity for next if not null
	movea.l ent_next(a0),a2
	movea.l ent_prev(a0),a1
	move.l a2,d0
	tst.l d0
	beq.b entity_deinit_nonext
		move.l a1,ent_prev(a2)
entity_deinit_nonext:
	
	; skip this entity for prev if not null
	move.l a1,d0
	tst.l d0
	beq.b entity_deinit_noprev
		move.l a2,ent_next(a1)
		bra.b entity_deinit_hadnext
entity_deinit_noprev:
		; no prev? move ENT_USED.
		move.l a2,rENT_USED
entity_deinit_hadnext:
	
	; set next free pointer if appropriate
	move.l a0,d0
	cmp.l rENT_FREE, d0
	bcc.b entity_deinit_dontsetfree
		move.l a0, rENT_FREE
entity_deinit_dontsetfree:
	
	; clear alloc flag
	andi.w #~EF_ALLOC,ent_flags(a0)
	
	movem.l (a7)+,d0-d7/a1-a6
	rts
