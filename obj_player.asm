
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;   PLAYER OBJECT
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;
; INIT
;
obj_player_init:
	; set up player entity properly
	move.w #$0500,spr_size(a0) ; spr size:link
	move.w #$0100,spr_tile(a0) ; spr tile
	
	move.b #2, ent_bx1(a0)
	move.b #2, ent_by1(a0)
	move.b #30, ent_bx2(a0)
	move.b #30, ent_by2(a0)
	
	move.l #obj_player_deinit, ent_fn_deinit(a0)
	move.l #obj_player_tick, ent_fn_tick(a0)
	move.l #obj_player_hit, ent_fn_hit(a0)
	
	move.w #EF_ALLOC|EF_PLAYER|EF_HITTABLE, ent_flags(a0)
	
	move.b #$00,ent_data+0(a0) ; .b tickdown death time
	move.b #$00,ent_data+1(a0) ; .l tickdown bullet time
	
	; now set the camera
	jsr obj_player_upcam
	
	rts
	
obj_player_upcam:
	; set coordinates
	move.w ent_x(a0), d1
	move.w ent_y(a0), d2
	
	; sub + clamp negatives
	subi.w #320-16,d1
	btst #15,d1
	beq.b obj_player_upcam_noclampxn
		clr.w d1
obj_player_upcam_noclampxn:
	subi.w #224-16,d2
	btst #15,d2
	beq.b obj_player_upcam_noclampyn
		clr.w d2
obj_player_upcam_noclampyn:

	; clamp positives
	cmpi.w #64*32-320*2,d1
	bcs.b obj_player_upcam_noclampxp
		move.w #64*32-320*2, d1
obj_player_upcam_noclampxp:
	cmpi.w #64*32-224*2,d2
	bcs.b obj_player_upcam_noclampyp
		move.w #64*32-224*2, d2
obj_player_upcam_noclampyp:
	
	; now write!
	move.w d1, rCAM_X
	move.w d2, rCAM_Y
	
	; calc tile delta
	andi.w #$FFE0,d1
	andi.w #$FFE0,d2
	
	; scroll Y
	move.w d1,-(a7)
lp_obj_player_upcam_sy:
		cmp.w rCAM_OLDY, d2
		beq.b lpx_obj_player_upcam_sy
		bgt.b lp_obj_player_upcam_syp
			; -ve
			move.w d2,-(a7)
			jsr lvl_scroll_yn
			move.w (a7)+,d2
			bra.b lp_obj_player_upcam_sy
lp_obj_player_upcam_syp:
			; +ve
			move.w d2,-(a7)
			jsr lvl_scroll_yp
			move.w (a7)+,d2
			bra.b lp_obj_player_upcam_sy
lpx_obj_player_upcam_sy:
	move.w (a7)+,d1
	
	; scroll X
	move.w d2,-(a7)
lp_obj_player_upcam_sx:
		cmp.w rCAM_OLDX, d1
		beq.b lpx_obj_player_upcam_sx
		bgt.b lp_obj_player_upcam_sxp
			; -ve
			move.w d1,-(a7)
			jsr lvl_scroll_xn
			move.w (a7)+,d1
			bra.b lp_obj_player_upcam_sx
lp_obj_player_upcam_sxp:
			; +ve
			move.w d1,-(a7)
			jsr lvl_scroll_xp
			move.w (a7)+,d1
			bra.b lp_obj_player_upcam_sx
lpx_obj_player_upcam_sx:
	move.w (a7)+,d2
	
	; return
	rts

;
; DEINIT
;
obj_player_deinit:
	rts

;
; TICK
;
obj_player_tick:
	jsr phy_update_oldpos
	
	; check button
	move.b rJOYVALS0,d0
	
	; check if dead
	move.b ent_data+0(a0),d1
	cmpi.b #$00,d1
	beq.b obj_player_tick_notdead
		; clear buttons
		move.b #$FF,d0
		
		; dec counter
		subi.b #$01,d1
		move.b d1,ent_data+0(a0)
		bne.b obj_player_tick_notdead
		
		; die
		andi.w #~EF_PLAYER, ent_flags(a0)
obj_player_tick_notdead:
	
	; tick down bullet timer
	move.b ent_data+1(a0),d1
	cmpi.b #$00,d1
	beq.b obj_player_tick_canfire
		subi.b #1,ent_data+1(a0)
obj_player_tick_canfire:
	
	; set target X velocity
	move.b ent_vx(a0),d1
	btst #2,d0
	bne.b obj_player_tick_notleft
		subi.b #$0C,d1
		ori.w #$0800,spr_tile(a0)
obj_player_tick_notleft:
	btst #3,d0
	bne.b obj_player_tick_notright ; something just isn't right.
		addi.b #$0C,d1
		andi.w #~$0800,spr_tile(a0)
obj_player_tick_notright:
	move.b d1,ent_vx(a0)
	
	; apply gravity
	addi.b #$04,ent_vy(a0)
	
	; jump if flag set
	btst #6,d0
	bne.b obj_player_tick_notjump
	move.w ent_flags(a0),d6
	btst #EFB_JUMP, d6
	beq.b obj_player_tick_notjump
		andi.w #~EF_JUMP, ent_flags(a0)
		move.b #-120,ent_vy(a0)
obj_player_tick_notjump:
	
	; shoot if we can
	btst #5,d0
	bne.b obj_player_tick_notshot
	cmpi.b #$00,ent_data+1(a0)
	bne.b obj_player_tick_notshot
		move.b #$09,ent_data+1(a0)
		; bam
		move.w ent_x(a0),d1
		move.w ent_y(a0),d2
		
		move.l a0,-(a7)
		movea.l #obj_bul01_init,a3
		jsr entity_init
		movea.l a0,a1
		movea.l (a7)+,a0
		
		move.l a1,ent_data+4(a0)
		
		; set x speed
		move.b #$60,ent_vx(a1)
		move.w spr_tile(a0),d0
		btst #11,d0
		beq.b obj_player_tick_bnotnegx
			move.b #-$60,ent_vx(a1)
obj_player_tick_bnotnegx:
		
obj_player_tick_notshot:
	
	; apply physics
	jsr phy_apply_friction
	jsr phy_apply_motion
	
	; apply collisions
	; Y
	move.w #16,d1
	move.w #30,d2
	move.w #$0005,d7
	jsr phy_apply_collision
	move.w #16,d1
	move.w #2,d2
	move.w #$0001,d7
	jsr phy_apply_collision
	
	; X
	move.w #30,d1
	move.w #16,d2
	move.w #$0002,d7
	jsr phy_apply_collision
	move.w #2,d1
	move.w #16,d2
	move.w #$0002,d7
	jsr phy_apply_collision
	
	; corners
	move.w #2,d1
	move.w #30,d2
	move.w #$0003,d7
	jsr phy_apply_collision
	move.w #30,d1
	move.w #30,d2
	move.w #$0003,d7
	jsr phy_apply_collision
	move.w #2,d1
	move.w #2,d2
	move.w #$0003,d7
	jsr phy_apply_collision
	move.w #30,d1
	move.w #2,d2
	move.w #$0003,d7
	jsr phy_apply_collision
	
	; update camera
	jsr obj_player_upcam
	
	rts

;
; HIT
;
obj_player_hit:
	;rts ; DEBUG REMOVE ME
	move.w ent_flags(a1),d0
	btst #EFB_PLAYER,d0
	bne.b obj_player_hit_ret1
	cmpi.b #$00,ent_data+0(a0)
	bne.b obj_player_hit_ret1
		ori.w #$1000,spr_tile(a0)
		move.b #-100,ent_vy(a0)
		move.b #-100,ent_vx(a0)
		move.b #45,ent_data+0(a0)
obj_player_hit_ret1:
	rts
