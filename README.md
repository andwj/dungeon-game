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
            (this is the "-game" folder for the Darkplaces engine)
            (Note: name is temporary)
   
misc/     : miscellaneous stuff, e.g. packing scripts


##Structure underneath oga/ :

textures/   : contains the textures  (TGA format preferred)
              [ TODO : see if sub-directories are usable ]

gfx/        : contains user interface images

sound/      : contains sound effects  (WAV format)

music/      : contains music  (OGG/Vorbis format)

progs/      : contains models

progs.dat    : game code (compiled QC)
csprogs.dat  : client/ui code (compiled QC)
menu.dat     : menu code (compiled QC)

default.cfg  : default configuration (incl. key bindings)

