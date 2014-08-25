
;
; TEST STUFF
;

;
; VGM PLAYER
;
rVGM_PTR equ $FF0000 ; .l
rVGM_TICK equ $FF0004 ; .l
rVGM_LPPTR equ $FF0008 ; .l
rVGM_LPSAMPS equ $FF000C ; .l
rVGM_BASEPTR equ $FF0080 ; .l

;
; USEFUL STUFF
;
rTICK_CTR equ $FF0010 ; .w
rJOYVALS0 equ $FF0012 ; .b
	; * UNUSED equ $FF0013 ; .b
rCAM_X equ $FF0014 ; .w
rCAM_Y equ $FF0016 ; .w
rCAM_OLDX equ $FF0018 ; .w
rCAM_OLDY equ $FF001A ; .w
rCAM_CX equ $FF0088 ; .w
rCAM_CY equ $FF008A ; .w

; find a sane halfway-in-the-border area to update the playfield
; treating this as "top left corner", so to speak
CAM_UPDX equ (40+(64-40)/2)/2
CAM_UPDY equ (28+(64-28)/2)/2

;
; LEVEL STUFF
;
rLVL_TILES equ $FF001C ; .l
rLVL_START equ $FF2000 ; .b[$1000] 64x64, same as Sonic 1 Master System (!) but 16x16 chunks instead of 32x32 @_@
rLVL_LOADFN equ $FF0090 ; .l

;
; GRAPHICS INFO
;
spr_y equ $00 ; .w
spr_size equ $02 ; .b
spr_link equ $03 ; .b
spr_tile equ $04 ; .w, with the usual flags
spr_x equ $06 ; .w

spr_sizeof equ $08
spr_sizeof_shift equ 3

rSPR_START equ $FF0800
rSPR_COUNT equ $FF0030 ; .w
SPR_MAX equ 80 ; well, yeah.

;
; ENTITY STRUCT
;
ent_y equ $00 ; .w
	; $02-$05: USE spr_ REFERENCES
ent_x equ $06 ; .w
ent_fn_tick equ $08 ; .w
ent_fn_hit equ $0C ; .w
ent_vx equ $10 ; .b
ent_vy equ $11 ; .b
ent_flags equ $12 ; .w
ent_prev equ $14 ; .l
ent_fn_deinit equ $18 ; .l
ent_next equ $1C ; .l
ent_ox equ $20 ; .w
ent_oy equ $22 ; .w
ent_bx1 equ $24 ; .b
ent_by1 equ $25 ; .b
ent_bx2 equ $26 ; .b
ent_by2 equ $27 ; .b
ent_data equ $28 ; .b[24]

EF_PLAYER   equ $0001
EF_BULLET   equ $0002
EF_HITTABLE equ $0004
EF_JUMP     equ $0008
EF_LETHAL   equ $0010

EF_ALLOC    equ $8000

EFB_PLAYER   equ 0
EFB_BULLET   equ 1
EFB_HITTABLE equ 2
EFB_JUMP     equ 3
EFB_LETHAL   equ 4

EFB_ALLOC   equ 15

; assload of extra data just so we can get stuff going :)
ent_sizeof equ $40
ent_sizeof_shift equ 6

; tile flags
TF_SOLID    equ $0001
TF_PLATFORM equ $0002
TF_SWAPXY   equ $0004
TF_INVX     equ $0008
TF_INVY     equ $0010
TF_SLOPE1   equ $0020
TF_SLOPE2   equ $0040
TF_EXIT     equ $0080

TFB_SOLID    equ 0
TFB_PLATFORM equ 1
TFB_SWAPXY   equ 2
TFB_INVX     equ 3
TFB_INVY     equ 4
TFB_SLOPE1   equ 5
TFB_SLOPE2   equ 6
TFB_EXIT     equ 7

rENT_START equ $FF1000
rENT_USED equ $FF0040 ; .l
rENT_FREE equ $FF0044 ; .l
rENT_COUNT equ $FF0048 ; .w
rENT_MAX equ 512
