
	include "obj_player.asm"
	include "obj_bullet.asm"

obj_test_init:
	; stupid test, looks like a player
	move.w #$0500,spr_size(a0) ; spr size:link
	move.w #$0100,spr_tile(a0) ; spr tile
	
	move.l #obj_test_deinit, ent_fn_deinit(a0)
	move.l #obj_test_tick, ent_fn_tick(a0)
	move.l #obj_test_hit, ent_fn_hit(a0)
	
	rts

obj_test_deinit:
	rts

obj_test_tick:
	rts

obj_test_hit:
	rts
