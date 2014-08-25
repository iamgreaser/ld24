import sys, struct

# get width/height in tiles for interlacy crap
intw, inth = int(sys.argv[3]), int(sys.argv[4])

# read image data
fp = open(sys.argv[1],"rb")

idlen, hascmap, imgtype = struct.unpack("<BBB",fp.read(3))
assert hascmap == 1, "non-colourmapped images not supported"
assert imgtype in [1,9], "image type must be colourmapped"

cmbeg, cmlen, cmbpp = struct.unpack("<HHB",fp.read(5))
assert cmbeg == 0, "colourmap start wrong (%i, should be 0)" % cmbeg
assert cmlen == 16, "colourmap size wrong (%i, should be 16)" % cmlen
assert cmbpp == 24, "colourmap bpp wrong (%i, should be 24)" % cmbpp

ix,iy,iw,ih,ibpp,idesc = struct.unpack("<HHHHBB",fp.read(10))
print ix,iy,iw,ih,ibpp,idesc

assert idesc == 32, "top-left, no attribute bits, no interleaving only"
assert ibpp == 8, "BPP other than 8 not supported"

assert iw%(intw*8) == 0
assert ih%(inth*8) == 0

# skip ID
fp.read(idlen)

# read colour map
cmap = fp.read(48)

# unpack data
data = []
rlect = 0x00
val = 0x00
for i in xrange(iw*ih):
	if (rlect&0x7F) == 0x00:
		rlect = ord(fp.read(1))+1
		val = ord(fp.read(1))
	elif rlect < 0x80:
		val = ord(fp.read(1))
	
	data.append(val)
	
	rlect -= 1
	
fp.close()

#print data

# do an interleave
odata = data[:]

for gy in xrange(0,ih,inth*8):
	for gx in xrange(0,iw,intw*8):
		for cy in xrange(0,inth*8,8):
			for cx in xrange(0,intw*8,8):
				for sy in xrange(8):
					for sx in xrange(8):
						bx = gx+sx
						by = gy+sy
						odata[(bx+cx)+(by+cy)*iw] = data[(bx+cy)+(by+cx)*iw]

# recompress
rledata = []
for y in xrange(ih):
	# dump buffer
	i = y*iw
	rleq = []
	
	# check for any runs
	lastval = odata[i]
	rlecount = 1
	for j in xrange(i+1,i+iw,1):
		v = odata[j]
		
		if v == lastval:
			rlecount += 1
			if rlecount == 129:
				rleq.append((lastval,128))
				rlecount = 1
		else:
			rleq.append((lastval,rlecount))
			rlecount = 1
		
		lastval = v
	rleq.append((lastval,rlecount))
	assert sum(b for a,b in rleq) == iw
	
	# assemble stream
	l = []
	for v,r in rleq:
		if r <= 2:
			l.append(v)
			if len(l) >= 127:
				rledata.append(len(l)-1)
				rledata += l
				l = []
			if r >= 2:
				l.append(v)
			if len(l) >= 127:
				rledata.append(len(l)-1)
				rledata += l
				l = []
		else:
			if len(l) > 0:
				rledata.append(len(l)-1)
				rledata += l
				l = []
			
			rledata.append(r+0x7F)
			rledata.append(v)
	
	if len(l) > 0:
		rledata.append(len(l)-1)
		rledata += l
		l = []
	

# write tile data
fp = open(sys.argv[2],"wb")
fp.write(struct.pack("<BBB", 0,1,9))
fp.write(struct.pack("<HHB", cmbeg,cmlen,cmbpp))
fp.write(struct.pack("<HHHHBB", ix,iy,iw,ih,ibpp,idesc))
fp.write(cmap)
fp.write(''.join(chr(v) for v in rledata))
fp.write("\x00"*8)
fp.write("TRUEVISION-XFILE\x00")
fp.close()

