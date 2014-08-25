BINNAME = LD24-gm.bin

ASM68 = asmx -C68000
PYTHON2 = python2

# *.vgm
$(BINNAME): *.asm *.tga conv_plr01.tga
	$(ASM68) -w -e -b0 -o $(BINNAME) main.asm

conv_plr01.tga: cvtgfx.py
	$(PYTHON2) cvtgfx.py gfx_plr01.tga conv_plr01.tga 2 2
