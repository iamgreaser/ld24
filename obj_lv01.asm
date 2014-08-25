
obj_lv01bat_init:
	move.w #$0400,spr_size(a0) ; spr size:link
	move.w #$002E,spr_tile(a0) ; spr tile
	
	move.b #0, ent_bx1(a0)
	move.b #0, ent_by1(a0)
	move.b #31, ent_bx2(a0)
	move.b #15, ent_by2(a0)
	
	move.l #obj_lv01bat_deinit, ent_fn_deinit(a0)
	move.l #obj_lv01bat_tick, ent_fn_tick(a0)
	move.l #obj_lv01bat_hit, ent_fn_hit(a0)
	
	move.w #EF_ALLOC|EF_LETHAL|EF_HITTABLE, ent_flags(a0)
	
	move.b #$00,ent_data+0(a0) ; STATE (0 = idle)
	move.b #$01,ent_data+1(a0) ; ANIM TICKS LEFT
	
	rts

obj_lv01bat_deinit:
	rts

obj_lv01bat_tick:
	; convinience pointer for player
	movea.l #rENT_START,a1
	
	; get delta to player
	clr.l d1
	clr.l d2
	move.w ent_x(a1),d1
	move.w ent_y(a1),d2
	sub.w ent_x(a0),d1
	sub.w ent_y(a0),d2
	move.w d1,d3
	move.w d2,d4
	
	; 2Abs(_) where _ in x,y
	add.w d1,d1
	subx.w d0,d0
	eor.w d0,d1
	add.w d2,d2
	subx.w d0,d0
	eor.w d0,d2
	
	; check state
	move.b ent_data+0(a0),d0
	cmpi.b #$00,d0
	beq obj_lv01bat_tick_idle
	
	;
	; HOMING
	;
	
	; set oldpos
	jsr phy_update_oldpos
	
	; check if in range
	; going for 12 chunks X, 10 chunks Y
	cmpi.w #32*2*12, d1
	bgt.b obj_lv01bat_tick_nofind2
	cmpi.w #32*2*10, d2
	bgt.b obj_lv01bat_tick_nofind2
	
	; seek player
	; check if |y| > |x|
	cmp.w d1,d2
	bgt.b obj_lv01bat_slanty
		; X slant
		; move towards player
		;move.b #$00,ent_vy(a0)
		move.b #$40,ent_vx(a0)
		btst #15,d3
		beq.b obj_lv01bat_slantx_pos
			neg.b ent_vx(a0)
obj_lv01bat_slantx_pos:
		bra.b obj_lv01bat_slantend
obj_lv01bat_slanty:
		; Y slant
		;move.b #$00,ent_vx(a0)
		move.b #$40,ent_vy(a0)
		btst #15,d4
		beq.b obj_lv01bat_slanty_pos
			neg.b ent_vy(a0)
obj_lv01bat_slanty_pos:
obj_lv01bat_slantend:
	
	; apply collision
	move.w ent_x(a0),d1
	move.w ent_y(a0),d2
	addi.w #16,d1
	addi.w #8,d2
	jsr phy_apply_hit
	
	; apply physics
	jsr phy_apply_friction
	jsr phy_apply_motion
	
	; flap wings if possible
	subi.b #$01, ent_data+1(a0)
	bne.b obj_lv01bat_tick_noflap ; The Ultimate Challenge.
		eori.b #$70, spr_tile+1(a0)
		move.b #$04, ent_data+1(a0)
obj_lv01bat_tick_noflap:
	rts

obj_lv01bat_tick_nofind2:
	; go idle
	move.b #$2E, spr_tile+1(a0)
	move.b #$00, ent_data+0(a0)
	move.b #$01, ent_data+1(a0)
	rts
	
obj_lv01bat_tick_idle:
	
	; check if in range
	; going for 6 chunks X, 5 chunks Y
	cmpi.w #32*2*6, d1
	bgt.b obj_lv01bat_tick_nofind
	cmpi.w #32*2*5, d2
	bgt.b obj_lv01bat_tick_nofind
		move.b #$3E, spr_tile+1(a0)
		move.b #$01, ent_data+0(a0)
		move.b #$01, ent_data+1(a0)
obj_lv01bat_tick_nofind:
	rts

obj_lv01bat_hit:
	move.w ent_flags(a1),d0
	btst #EFB_PLAYER,d0
	beq.b obj_lv01bat_hit_ret1
	btst #EFB_LETHAL,d0
	beq.b obj_lv01bat_hit_ret1
		jmp entity_deinit
obj_lv01bat_hit_ret1:
	rts
