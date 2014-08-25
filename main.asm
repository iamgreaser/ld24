	org $00000000
rom_start:
	dc.l $00FFFFFC   ; boot ISP
	dc.l code_start  ; boot PC
	dc.l isr_lock    ; access fault
	dc.l isr_lock    ; address error
	dc.l isr_lock    ; illegal instruction
	dc.l isr_lock    ; integer div by zero
	dc.l isr_lock    ; CHK/CHK2
	dc.l isr_lock    ; FTRAPcc, TRAPcc, TRAPV
	
	dc.l isr_lock    ; privilege vio
	dc.l isr_lock    ; trace
	dc.l isr_lock    ; line A emulator
	dc.l isr_lock    ; line F emulator
	dc.l isr_lock    ; [unassigned]
	dc.l isr_lock    ; coproc proto vio
	dc.l isr_lock    ; format error
	dc.l isr_lock    ; uninitialised interrupt
	
	dc.l isr_lock    ; [unassigned]
	dc.l isr_lock    ; [unassigned]
	dc.l isr_lock    ; [unassigned]
	dc.l isr_lock    ; [unassigned]
	dc.l isr_lock    ; [unassigned]
	dc.l isr_lock    ; [unassigned]
	dc.l isr_lock    ; [unassigned]
	dc.l isr_lock    ; [unassigned]
	
	dc.l isr_nop     ; spurious interrupt
	dc.l isr_nop     ; interrupt 1
	dc.l isr_vblank  ; interrupt 2
	dc.l isr_nop     ; interrupt 3
	dc.l isr_vblank  ; interrupt 4
	dc.l isr_nop     ; interrupt 5
	dc.l isr_vblank  ; interrupt 6
	dc.l isr_nop     ; interrupt 7
	
	dc.l isr_lock    ; trap #0
	dc.l isr_lock    ; trap #1
	dc.l isr_lock    ; trap #2
	dc.l isr_lock    ; trap #3
	dc.l isr_lock    ; trap #4
	dc.l isr_lock    ; trap #5
	dc.l isr_lock    ; trap #6
	dc.l isr_lock    ; trap #7

	dc.l isr_lock    ; trap #8
	dc.l isr_lock    ; trap #9
	dc.l isr_lock    ; trap #10
	dc.l isr_lock    ; trap #11
	dc.l isr_lock    ; trap #12
	dc.l isr_lock    ; trap #13
	dc.l isr_lock    ; trap #14
	dc.l isr_lock    ; trap #15
	
	dc.l isr_lock    ; FPU crap
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	
	dc.l isr_lock    ; MMU crap
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	dc.l isr_lock    ; reserved
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	dc.l isr_lock    ;
	
	; mega drive header
	dc.b "SEGA MEGA DRIVE "
	dc.b "(C)-GM- 2012.JUL"
	; TODO: put proper names here!
	; first is japan, second is everywhere else
	dc.b "LD24 BEESU KOUDO --GM                           "
	dc.b "LD24 BASE CODE --GM                             "
	dc.b "GM XXXXXXXX-00"
	dc.w $0000 ; checksum! something might fix this for me.
	dc.b "J               " ; I/O supported, in this case a joypad?
	dc.l rom_start ; start of ROM
	dc.l rom_end   ; end   of ROM
	dc.l $00FF0000 ; start of RAM
	dc.l $00FFFFFF ; end   of RAM
	dc.l "    " ; backup RAM info  (NO RAM)
	dc.l "    " ; backup RAM start (NO RAM)
	dc.l "    " ; backup RAM end   (NO RAM)
	dc.b "            " ; modem support (NO MODEM)
	dc.b "                                        " ; notes
	dc.b "JUE             " ; regions

isr_lock:
	jmp isr_lock

isr_nop:
	rte
	
	include "defs.asm"

;
; VBLANK
;
isr_vblank:
	; stash all the things
	movem.l a0-a6/d0-d7,-(a7)
	
	; read joypad, part 1
	move.b $A10003,rJOYVALS0
	move.b #$00,$A10003
	
	; update vgm
	jsr vgm_play
	
	; read joypad, part 2
	move.b $A10003,d1
	move.b #$40,$A10003
	
	; merge joypad values
	add.b d1,d1
	add.b d1,d1
	andi.b #$C0,d1
	move.b rJOYVALS0,d0
	andi.b #$3F,d0
	or.b d1,d0
	move.b d0,rJOYVALS0
	
	
	; increment tick counter
	addq.w #1,rTICK_CTR
	
	; restore all the things
	movem.l (a7)+,a0-a6/d0-d7
	
	rte

;
; START
;

code_start:
	; okey dokey, let's rock this joint.
	; first up, TMSS. thanks, wikibooks.
	move.b  $A10001,d0
	andi.b  #$0F,d0
	beq.b   version_0
	move.l  #'SEGA',$A14000
version_0:
	
	; load regular SP.
	movea.l #$FFFEFC,a7
	
	; clear RAM.
	movea.l #$FF0000,a0
	move.w #$4000-1,d1
	clr.l d0
lp_clearram:
	move.l d0,(a0)+
	dbra d1,lp_clearram
	
	; clear registers
	movea.l #$FF0000,a0
	movem.l (a0),d0-d7/a1-a6
	suba.l a0,a0
	
	; BUSREQ + unRESET Z80.
	move.w #$0100,$A11100 ; BUSREQ = bit 8 set
	move.w #$0100,$A11200 ; RESET = bit 8 clear
	
	; now let's do some stuff.
	; once we're done, the Z80 should give us the OPN2 to screw with.
	jsr vdp_reset
	
	; load images
	movea.l #tga_font01,a0
	move.l #$40000001,d0
	move.l #$C0000000,d1
	jsr img_load_tga
	movea.l #tga_plr01,a0
	move.l #$60000000,d0
	move.l #$C0200000,d1
	jsr img_load_tga
	
	; prep the I/O region
	move.b #$7F,$A10003
	move.b #$7F,$A10005
	move.b #$7F,$A10007
	move.b #$40,$A10009
	move.b #$00,$A1000B
	move.b #$00,$A1000D
	move.b #$FF,rJOYVALS0
	
	; stop VGM
	jsr vgm_stop
	
	; set level
	move.l #lv01_reset, rLVL_LOADFN
	
	; enable vblank interrupt
	move.w sr,d0
	andi.w #$F0FF,d0
	ori.w #$0000,d0
	move.w d0,sr
	
	; go to game
	jmp game_main
	
	; include our other files
	include "entity.asm"
	include "game.asm"
	include "img.asm"
	include "level.asm"
	include "objects.asm"
	include "physics.asm"
	include "sound.asm"
	include "vdp.asm"
	
	align 4
tga_font01:
	incbin "font01.tga"
	align 4
tga_plr01:
	incbin "conv_plr01.tga"
	align 4
vgm_mus01:
	incbin "ld24m1.vgm"
	align 4
	
rom_end:

