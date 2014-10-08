#
# Makefile for game / client / menu progs
#

all: oga/menu.dat

oga/menu.dat: menu/*.qc menu/*.qh menu/progs.src
	cd menu && fteqcc > /dev/null
	mv menu/menu.dat oga/
	mv menu/menu.lno oga/

clean:
	rm -f oga/*.dat
	rm -f menu/menu.dat menu/menu.lno
	rm -f */fteqcc.log

#--- editor settings ------------
# vi:ts=8:sw=8:noexpandtab
