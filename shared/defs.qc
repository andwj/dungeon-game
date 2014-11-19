//========================================================================
//
//  Copyright (C) 2014  Andrew Apted
//
//  This code is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published
//  by the Free Software Foundation; either version 2 of the License,
//  or (at your option) any later version.
//
//========================================================================


/*
 * This file contains definitinos which are shared between two or all
 * three of the VM programs (MENU, CLIENT, GAME).
 */


// for aesthetics
typedef float	bool;


// store result of tokenize() here
float argc;


// inventory box size
#define INV_BOX_WIDTH	2
#define INV_BOX_HEIGHT	5

#define INV_WIELD_BOX	9


// mode values for ui_highlight, ui_drag, ui_can_drop
#define DRAG_NONE		0
#define DRAG_INVENT		1
#define DRAG_WORLD		2
#define DRAG_USE		3
#define DRAG_GIVE		4


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
