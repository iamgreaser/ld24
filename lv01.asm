
lv01_reset:
	movea.l #vgm_mus01,a0
	jsr vgm_load
	
	movea.l #lv01_text1, a0
	jsr game_walloftext
	
	move.l #lv01_reset_level, rLVL_LOADFN
	move.w #0,d0
	rts

lv01_endgame:
	movea.l #lv01_textend1, a0
	jsr game_walloftext
	
	bra *

lv01_text1:
	dc.b "It was a dark and stormy night.", 0
	dc.b 0
	dc.b "It appears that someone's being doing", 0
	dc.b "weird things with weird bats in a weird", 0
	dc.b "castle.", 0
	dc.b 0
	dc.b "It appears they're trying to recreate", 0
	dc.b "the Cambrian Explosion with explosives.", 0
	dc.b 0
	dc.b "And they're starting with trilobats.",0
	dc.b 1
	

lv01_textend1:
	dc.b "That's all, sorry. Ran out of time :(", 0
	dc.b 0
	dc.b "By Ben ",34,"GreaseMonkey",34," Russell", 0
	dc.b "for Ludum Dare #24 (compo entry)", 0
	dc.b 1
	
	align 2

lv01_reset_level:
	movea.l #lv01_gfx,a0
	move.l #$40000000,d0
	move.l #$C0000000,d1
	jsr img_load_tga
	
	move.l #lv01_tiles,rLVL_TILES
	movea.l #lv01_data,a0
	jsr lvl_load
	
	move.w #1,d0
	rts

	align 2
lv01_gfx:
	incbin "gfx_lv01.tga"
	
	align 2
lv01_data:
	
	; entities
	dc.b 6+9 ; count (excluding player, of course!)
	dc.b 0 ; * RESERVED * (for alignment)
	dc.b 4,48 ; x,y
	dc.l obj_player_init
	
	; EVERYTHING'S WORSE WITH BATS
	dc.b 23,44 ; x,y
	dc.l obj_lv01bat_init
	dc.b 48,40 ; x,y
	dc.l obj_lv01bat_init
	dc.b 38,22 ; x,y
	dc.l obj_lv01bat_init
	dc.b 41,22 ; x,y
	dc.l obj_lv01bat_init
	dc.b 15,14 ; x,y
	dc.l obj_lv01bat_init
	dc.b 47,14 ; x,y
	dc.l obj_lv01bat_init
	
	
	dc.b 58,6 ; x,y
	dc.l obj_lv01bat_init
	dc.b 48,8 ; x,y
	dc.l obj_lv01bat_init
	dc.b 48,10 ; x,y
	dc.l obj_lv01bat_init
	
	dc.b 60,6 ; x,y
	dc.l obj_lv01bat_init
	dc.b 50,8 ; x,y
	dc.l obj_lv01bat_init
	dc.b 50,10 ; x,y
	dc.l obj_lv01bat_init
	
	dc.b 56,6 ; x,y
	dc.l obj_lv01bat_init
	dc.b 52,8 ; x,y
	dc.l obj_lv01bat_init
	dc.b 52,10 ; x,y
	dc.l obj_lv01bat_init
	
	; foreground layer
	incbin "lv01.tga"
	align 2
	
	align 8
lv01_tiles:
	; $00 space
	dc.w $0000,$0000
	dc.w $0000,$0000
	dc.w 0
	dc.w 64,0,0
	
	; $01 * RESERVED *
	dc.w $0000,$0000
	dc.w $0000,$0000
	dc.w 0
	dc.w 64,0,0
	
	; $02 grass solid
	dc.w $0010,$0010
	dc.w $0010,$0010
	dc.w TF_SOLID
	dc.w 0,0,0
	
	; $03 metal solid
	dc.w $0040,$0040
	dc.w $0040,$0040
	dc.w TF_SOLID
	dc.w 0,0,0
	align 8
	
	; $04 cloud A
	dc.w $000A,$000B
	dc.w $001A,$001B
	dc.w 0
	dc.w 64,0,0
	
	; $05 cloud B
	dc.w $000C,$000D
	dc.w $001C,$001D
	dc.w 0
	dc.w 64,0,0
	
	; $06 cloud C
	dc.w $000E,$000F
	dc.w $001E,$001F
	dc.w 0
	dc.w 64,0,0
	
	; $07 metal ramp +2R
	dc.w $0028,$0041
	dc.w $0041,$0040
	dc.w TF_SLOPE2
	dc.w 32,0,0
	
	; $08 metal ramp +2L
	dc.w $0841,$0029
	dc.w $0040,$0841
	dc.w TF_SLOPE2|TF_INVX
	dc.w 32,0,0
	
	; $09 grass ramp +2R
	dc.w $0000,$0011
	dc.w $0011,$0010
	dc.w TF_SLOPE2
	dc.w 32,0,0
	
	; $0A grass ramp +2L
	dc.w $0811,$0000
	dc.w $0010,$0811
	dc.w TF_SLOPE2|TF_INVX
	dc.w 32,0,0
	
	; $0B grass force up
	dc.w $0010,$0010
	dc.w $0010,$0010
	dc.w 0
	dc.w -1,0,0
	
	; $0C metal force up
	dc.w $0040,$0040
	dc.w $0040,$0040
	dc.w 0
	dc.w -1,0,0
	
	; $0D inside bg
	dc.w $0028,$0029
	dc.w $0038,$0039
	dc.w 0
	dc.w 64,0,0
	
	; $0E shoutout A1
	dc.w $00E0,$00E1
	dc.w $00F0,$00F1
	dc.w 0
	dc.w 64,0,0
	
	; $0F shoutout A2
	dc.w $00E2,$00E3
	dc.w $00F2,$00F3
	dc.w 0
	dc.w 64,0,0
	
	; $10 shoutout A3
	dc.w $00E4,$00E5
	dc.w $00F4,$00F5
	dc.w 0
	dc.w 64,0,0
	
	; $11 shoutout B1
	dc.w $00E6,$00E7
	dc.w $00F6,$00F7
	dc.w 0
	dc.w 64,0,0
	
	; $12 shoutout B2
	dc.w $00E8,$00E9
	dc.w $00F8,$00F9
	dc.w 0
	dc.w 64,0,0
	
	; $13 eggsat
	dc.w $0048,$0049
	dc.w $0058,$0059
	dc.w TF_EXIT
	dc.w 64
	dc.l lv01_endgame
	
	include "obj_lv01.asm"
