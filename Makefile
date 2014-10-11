#
# Makefile for game / client / menu progs
#

# Quake-C compiler to use
# (we discard output of fteqcc since it creates a log file)
QCC=fteqcc -O0 > /dev/null

all: oga/menu.dat oga/progs.dat oga/csprogs.dat

oga/progs.dat: game/*.qc game/progs.src
	cd game && $(QCC)
	mv game/progs.dat oga/
	mv game/progs.lno oga/

oga/csprogs.dat: client/*.qc client/progs.src
	cd client && $(QCC)
	mv client/csprogs.dat oga/
	mv client/csprogs.lno oga/

oga/menu.dat: menu/*.qc menu/progs.src
	cd menu && $(QCC)
	mv menu/menu.dat oga/
	mv menu/menu.lno oga/

clean:
	rm -f */*.dat
	rm -f */*.lno
	rm -f */fteqcc.log ./fteqcc.log

#--- editor settings ------------
# vi:ts=8:sw=8:noexpandtab
