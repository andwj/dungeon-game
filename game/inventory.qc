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


void INV_Recount(entity pl);


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


void INV_EncodeSpawnParms(entity pl)
{
	parm1 = pl.health;
	parm2 = pl.mana;
	parm3 = pl.weapon;

	parm5 = pl.i_keys;
	parm6 = pl.i_weapons;
	parm7 = pl.i_armor;
	parm8 = pl.i_misc;
}


void INV_DecodeSpawnParms(entity pl)
{
	pl.health = parm1;
	pl.mana   = parm2;
	pl.weapon = parm3;

	pl.i_keys		= parm5;
	pl.i_weapons	= parm6;
	pl.i_armor	= parm7;
	pl.i_misc		= parm8;

	INV_Recount(pl);

	// TODO : compute pl.armorvalue

	// keep engine happy
	pl.items = IT_AXE;
}


float INV_CountBits(float bits)
{
	float i;
	float count = 0;

	for (i = 1 ; i <= 1048576 ; i = i * 2)
	{
		if (bits & i)
			count = count + 1;
	}

	return count;
}


void INV_Recount(entity pl)
{
	pl.inv_count = INV_CountBits(pl.i_keys) +
				   INV_CountBits(pl.i_weapons) +
				   INV_CountBits(pl.i_armor) +
				   INV_CountBits(pl.i_misc);
}


float INV_CheckHasItem(entity pl, entity e)
{
	if (pl.i_keys & e.i_keys) return TRUE;
	if (pl.i_weapons & e.i_weapons) return TRUE;
	if (pl.i_armor & e.i_armor) return TRUE;
	if (pl.i_misc & e.i_misc) return TRUE;

	return FALSE;
}


void INV_GiveItem(entity pl, entity e)
{
	pl.i_keys		= pl.i_keys		| e.i_keys;
	pl.i_weapons	= pl.i_weapons	| e.i_weapons;
	pl.i_armor		= pl.i_armor	| e.i_armor;
	pl.i_misc		= pl.i_misc		| e.i_misc;

	pl.inv_count = pl.inv_count + 1;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
