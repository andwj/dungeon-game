//========================================================================
//
//  Copyright (C) 1996-1997  Id Software, Inc.
//  Copyright (C)      2014  Andrew Apted
//
//  This code is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published
//  by the Free Software Foundation; either version 2 of the License,
//  or (at your option) any later version.
//
//========================================================================


void INV_InitialSpawnParms()
{
	parm1 = 100;	/* health */
	parm2 = 50;		/* mana */
	parm3 = 0;		/* weapon (0 = bare fists) */
	parm4 = 0;		/* (not used atm) */

	parm5 = 0;		/* i_keys */
	parm6 = 0;		/* i_weapons */
	parm7 = 0;		/* i_armor */
	parm8 = 0;		/* i_misc */

	/* rest are unused */
	parm9  = parm10 = parm11 = parm12 = 0;
	parm13 = parm14 = parm15 = parm16 = 0;
}


void INV_EncodeSpawnParms()
{
	parm1 = self.health;
	parm2 = self.mana;
	parm3 = self.weapon;

	parm5 = self.i_keys;
	parm6 = self.i_weapons;
	parm7 = self.i_armor;
	parm8 = self.i_misc;
}


void INV_DecodeSpawnParms()
{
	self.health = parm1;
	self.mana   = parm2;
	self.weapon = parm3;

	self.i_keys		= parm5;
	self.i_weapons	= parm6;
	self.i_armor	= parm7;
	self.i_misc		= parm8;

	// TODO : compute self.armorvalue

	// keep engine happy
	self.items = IT_AXE;
}

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
