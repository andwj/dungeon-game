dungeon-game
============

This repository contains some code and a few assets for the OGA
(OpenGameArt.org) community dungeon game project.  The location
of this repository is subject to change.

##Structure of this repository:

game/     : contains server-side QC code for the game

client/   : contains client-side QC (CSQC) code, for user interface

menu/     : contains QC code for the menus

bin/      : where we place executables (esp. Darkplaces itself)

oga/      : where to place all ready-to-use assets
            (this is the "gamedir" folder for the Darkplaces engine)
            (NOTE: name is temporary)
   
dpdefs/   : definitions for Darkplaces (copied from Darkplaces source)

misc/     : miscellaneous stuff, e.g. packing scripts

Makefile  : makefile for building the QC programs (requires fteqcc)


##Structure underneath oga/ :

textures/    : contains the textures  (TGA or JPEG format)

gfx/         : contains user interface images (TGA format preferred)

sound/       : contains sound effects  (WAV format)

music/       : contains music  (OGG/Vorbis format)

progs/       : contains models

progs.dat    : game code (compiled QC)

csprogs.dat  : client/ui code (compiled QC)

menu.dat     : menu code (compiled QC)

default.cfg  : default configuration (including key bindings)

