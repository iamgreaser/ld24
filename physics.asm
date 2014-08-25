
phy_update_oldpos:
	move.w ent_x(a0), ent_ox(a0)
	move.w ent_y(a0), ent_oy(a0)
	rts

; D1.w,D2.w = hit point
phy_apply_hit:
	; move to a1, go through list
	movea.l a0,a1
	movea.l rENT_USED,a0
lp_phy_apply_hit:
		; check flags
		move.w ent_flags(a0),d0
		btst #EFB_HITTABLE,d0
		beq.b lpc_phy_apply_hit
		
		; check if in range
		clr.w d0
		move.w d1,d3
		move.w d2,d4
		sub.w ent_x(a0),d3
		sub.w ent_y(a0),d4
		
		move.b ent_bx1(a0),d0
		cmp.w d0,d3
		bcs.b lpc_phy_apply_hit
		move.b ent_by1(a0),d0
		cmp.w d0,d4
		bcs.b lpc_phy_apply_hit
		move.b ent_bx2(a0),d0
		cmp.w d0,d3
		bcc.b lpc_phy_apply_hit
		move.b ent_by2(a0),d0
		cmp.w d0,d4
		bcc.b lpc_phy_apply_hit
		
		; stop hitting yourself!
		move.l a0,d0
		move.l a1,d4
		cmp.l d0,d4
		beq.b lpc_phy_apply_hit
		
			; BAMZOR
			movea.l ent_fn_hit(a0),a3
			movem.l d0-d7/a0-a6,-(a7)
			jsr (a3)
			movem.l (a7)+,d0-d7/a0-a6
lpc_phy_apply_hit:
		
		movea.l ent_next(a0),a0
		move.l a0,d0
		tst d0
		bne.b lp_phy_apply_hit
	
	; move it back
	movea.l a1,a0
	rts

phy_apply_friction:
	; apply friction to X
	move.b ent_vx(a0),d1
	move.b d1,d2
	asr.b #2,d2
	addi.b #$01,d2
	asr.b #1,d2
	sub.b d2,d1
	move.b d1,ent_vx(a0)
	
	; apply friction to Y
	move.b ent_vy(a0),d1
	move.b d1,d2
	asr.b #4,d2
	addi.b #$01,d2
	asr.b #1,d2
	sub.b d2,d1
	move.b d1,ent_vy(a0)
	rts

phy_apply_motion:
	; apply velocity to X
	move.b ent_vx(a0),d1
	ext.w d1
	asr.w #3,d1
	btst #15,d1
	beq.b phy_apply_motion_notnegvx
		addq.w #1,d1
phy_apply_motion_notnegvx:
	add.w d1,ent_x(a0)
	
	; apply velocity to Y
	move.b ent_vy(a0),d1
	ext.w d1
	asr.w #3,d1
	btst #15,d1
	beq.b phy_apply_motion_notnegvy
		addq.w #1,d1
phy_apply_motion_notnegvy:
	add.w d1,ent_y(a0)
	
	rts

; d1.w, d2.w = delta from a0 pos
; d7[0] = do Y col, d7[1] = do X col
; d7[2] = set jump flag
phy_apply_collision:
	; TODO: interesting stuff, i.e. slopes
	
	; add X,Y to delta, forming an actual position
	move.w d1,d5
	move.w d2,d6
	add.w ent_x(a0),d1
	add.w ent_y(a0),d2
	andi.w #$FFE0,d1
	andi.w #$FFE0,d2
	
	; check if in range
	cmp #64*32,d1
	bcc.b phy_apply_collision_solid
	cmp #64*32,d2
	bcc.b phy_apply_collision_solid
	
	; get tile
	clr.l d0
	move.w d2,d0
	lsl.l #6,d0
	add.w d1,d0
	asr.l #5,d0
	addi.l #rLVL_START,d0
	movea.l d0,a1
	movea.l rLVL_TILES,a2
	
	; get flags
	clr.l d0
	move.b (a1),d0
	lsl.w #4,d0
	lea (a2,d0),a2
	move.w 8(a2),d0
	
	; check if tile is exit
	btst #TFB_EXIT,d0
	beq.b phy_apply_collision_notexit
		; TODO: make this only happen to the player
		; (currently it's the only thing that uses this function)
		; (but i'd like to reuse this engine for next LD)
		;
		; anyhow, clear player flag on player (signalling end),
		; and set next pointer
		move.l 12(a2), rLVL_LOADFN
		andi.w #~EF_PLAYER, ent_flags(a0)
phy_apply_collision_notexit:
	
	; check if tile is solid
	btst #TFB_SOLID,d0
	bne.b phy_apply_collision_solid
	
	; apply rampy physics if we're going in a Y direction
	btst #0,d7
	;beq.b phy_apply_collision_ret1
		jsr phy_apply_collision_special
phy_apply_collision_ret1:
	rts

phy_apply_collision_solid:
	; check tile direction
	move.w ent_ox(a0),d3
	move.w ent_oy(a0),d4
	add.w d5,d3
	add.w d6,d4
	andi.w #$FFE0,d3
	andi.w #$FFE0,d4
	
	btst #0,d7
	beq.b phy_apply_collision_solid_ys
	cmp.w d2,d4
	beq.b phy_apply_collision_solid_ys
	bgt.b phy_apply_collision_solid_yn
		; +ve
		subq.w #1,d2
		move.b ent_vy(a0),d0
		asr.b #1,d0
		move.b d0,ent_vy(a0)
		btst #2,d7
		beq.b phy_apply_collision_solid_ya
		ori.w #EF_JUMP, ent_flags(a0)
		bra.b phy_apply_collision_solid_ya
phy_apply_collision_solid_yn:
		; -ve
		addi.w #33,d2
phy_apply_collision_solid_ya:
		sub.w d6,d2
		move.w d2,ent_y(a0)
phy_apply_collision_solid_ys:
	
	btst #1,d7
	beq.b phy_apply_collision_solid_xs
	cmp.w d1,d3
	beq.b phy_apply_collision_solid_xs
	bgt.b phy_apply_collision_solid_xn
		; +ve
		subq.w #1,d1
		bra.b phy_apply_collision_solid_xa
phy_apply_collision_solid_xn:
		; -ve
		addi.w #33,d1
phy_apply_collision_solid_xa:
		sub.w d5,d1
		move.w d1,ent_x(a0)
phy_apply_collision_solid_xs:
	
	rts

; Remember this from "Cave Wanderer"?
; Same sort of crap this time, too!
; D0.w == flags.
; setting D1 == x, D2 == y.
phy_apply_collision_special:
	; prep delta stuff
	move.w ent_x(a0),d1
	move.w ent_y(a0),d2
	add.w d5,d1
	add.w d6,d2
	move.w d1,ent_x(a0)
	move.w d2,ent_y(a0)
	andi.w #$FFE0,ent_x(a0)
	andi.w #$FFE0,ent_y(a0)
	andi.w #$001F,d1
	andi.w #$001F,d2
	
	move.w 8(a2),d0
	
	; apply
	jsr physpec_invx
	
	; add delta back
	add.w d1,ent_x(a0)
	add.w d2,ent_y(a0)
	sub.w d5,ent_x(a0)
	sub.w d6,ent_y(a0)
	
	rts

physpec_swapxy:
	btst #TFB_SWAPXY,d0
	beq.b physpec_invx
	
	; apply
	exg d1,d2
	
	jsr physpec_invx
	
	; unapply
	exg d1,d2
	
	rts

physpec_invx:
	btst #TFB_INVX,d0
	beq.b physpec_invy
	
	; apply
	neg.w d1
	addi.w #31,d1
	
	jsr physpec_invy
	
	; unapply
	neg.w d1
	addi.w #31,d1
	
	rts

physpec_invy:
	btst #TFB_INVY,d0
	beq.b physpec_slope1
	
	; apply
	neg.w d2
	addi.w #31,d2
	
	jsr physpec_slope1
	
	; unapply
	neg.w d2
	addi.w #31,d2
	
	rts

physpec_slope1:
	btst #TFB_SLOPE1,d0
	beq.b physpec_slope2
	
	; apply
	move.w d1,d0
	asr.w #1,d0
	add.w d0,d2
	
	jsr physpec_slope2
	
	; unapply
	move.w d1,d0
	asr.w #1,d0
	sub.w d0,d2
	
	rts

physpec_slope2:
	btst #TFB_SLOPE2,d0
	beq.b physpec_finally_do_it
	
	; apply
	add.w d1,d2
	
	jsr physpec_finally_do_it
	
	; unapply
	sub.w d1,d2
	
	rts
	
physpec_finally_do_it:
	; clamp Y
	cmp.w 10(a2),d2
	blt.b physpec_finally_do_it_ret1
		move.w 10(a2),d2
		btst #2,d7
		beq.b physpec_finally_do_it_ret1
			ori.w #EF_JUMP, ent_flags(a0)
physpec_finally_do_it_ret1:
	; and that's it.
	rts
