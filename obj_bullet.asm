
obj_bul01_init:
	move.w #$0500,spr_size(a0) ; spr size:link
	move.w #$0104,spr_tile(a0) ; spr tile
	
	move.b #0, ent_bx1(a0)
	move.b #0, ent_by1(a0)
	move.b #31, ent_bx2(a0)
	move.b #31, ent_by2(a0)
	
	move.l #obj_bul01_deinit, ent_fn_deinit(a0)
	move.l #obj_bul01_tick, ent_fn_tick(a0)
	move.l #obj_bul01_hit, ent_fn_hit(a0)
	
	move.w #EF_ALLOC|EF_LETHAL|EF_PLAYER, ent_flags(a0)
	
	move.b #20, ent_data+0(a0) ; .b lifetime
	
	; make two entities
	movea.l a0,a1
	move.l a0,-(a7)
		movea.l #obj_bul01a_init,a3
		jsr entity_init
		move.l a1, ent_data+4(a0)
		move.b #$10, ent_vy(a0)
		
		movea.l #obj_bul01a_init,a3
		jsr entity_init
		move.l a1, ent_data+4(a0)
		move.b #-$10, ent_vy(a0)
	
	movea.l (a7)+,a0
	rts

obj_bul01a_init:
	move.w #$0500,spr_size(a0) ; spr size:link
	move.w #$0104,spr_tile(a0) ; spr tile
	
	move.b #0, ent_bx1(a0)
	move.b #0, ent_by1(a0)
	move.b #31, ent_bx2(a0)
	move.b #31, ent_by2(a0)
	
	move.l #obj_bul01a_deinit, ent_fn_deinit(a0)
	move.l #obj_bul01a_tick, ent_fn_tick(a0)
	move.l #obj_bul01_hit, ent_fn_hit(a0)
	
	move.w #EF_ALLOC|EF_LETHAL|EF_PLAYER, ent_flags(a0)
	
	move.b #20, ent_data+0(a0) ; .b lifetime
	;clr.l ent_data+4(a0) ; .l parent
	
	rts

obj_bul01a_deinit:
	rts

obj_bul01_deinit:
	rts

obj_bul01a_tick:
	; steal vx from main
	movea.l ent_data+4(a0), a1
	move.b ent_vx(a1), ent_vx(a0)
	; * FALL THROUGH*
obj_bul01_tick:
	; check if lifetime is over
	subi.b #1,ent_data+0(a0)
	bne.b obj_bul01_tick_nodie
		; kill bullet
		jmp entity_deinit ; TAIL CALL!
obj_bul01_tick_nodie:
	
	; apply collision
	move.w ent_x(a0),d1
	move.w ent_y(a0),d2
	addi.w #16,d1
	addi.w #12,d2
	jsr phy_apply_hit
	move.w ent_x(a0),d1
	move.w ent_y(a0),d2
	addi.w #16,d1
	addi.w #20,d2
	jsr phy_apply_hit
	
	; apply physics
	jsr phy_update_oldpos
	jsr phy_apply_motion
	
	; apply collision (again)
	move.w ent_x(a0),d1
	move.w ent_y(a0),d2
	addi.w #16,d1
	addi.w #12,d2
	jsr phy_apply_hit
	move.w ent_x(a0),d1
	move.w ent_y(a0),d2
	addi.w #16,d1
	addi.w #20,d2
	jsr phy_apply_hit
	
	; apply physics (again)
	jsr phy_update_oldpos
	jsr phy_apply_motion
	
	; return
	rts

obj_bul01_hit:
	
	rts
