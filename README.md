dungeon-game
============

This repository contains some code and a few assets for the OGA
(OpenGameArt.org) community dungeon game project.  The location
of this repository is subject to change.

##Structure of this repository:

game/     : contains server-side QC code for the game

client/   : contains client-side QC (CSQC) code, for user interface

menu/     : contains QC code for the menus

shared/   : contains common code shared by the game/client/menu

bin/      : where we place executables (esp. Darkplaces itself)

oga/      : where we place all ready-to-use assets
            (this is the "gamedir" folder for the Darkplaces engine)
            (NOTE: name is temporary)

dpdefs/   : definitions for Darkplaces (copied from Darkplaces 2013-03-04
source, with some fixes)

misc/     : miscellaneous stuff, e.g. packing scripts

Makefile  : makefile for building the QC programs (requires gmqcc)


##Structure of game data (under oga/) :

textures/    : contains the textures  (TGA or JPEG format)

gfx/         : contains user interface images (TGA format preferred)

sound/       : contains sound effects  (WAV format)

music/       : contains music  (OGG/Vorbis format)

models/      : contains models  (IQM "InterQuakeModel" format)

items/       : contains item models (OBJ or IQM format) and icon images

env/         : contains sky boxes

fonts/       : contains the fonts

progs.dat    : game program (compiled QC)

csprogs.dat  : client/ui program (compiled QC)

menu.dat     : menu program (compiled QC)

default.cfg  : default settings

bindings.cfg : default key and mouse bindings

quake.rc     : commands run during startup

