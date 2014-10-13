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


void INV_Recreate(entity pl);


void INV_Create(entity pl)
{
	float ix, iy;

	for (ix = 0 ; ix < INV_BOX_WIDTH  ; ++ix)
	for (iy = 0 ; iy < INV_BOX_HEIGHT ; ++iy)
	{
		entity slot = spawn();

		slot.invent_id = iy * INV_BOX_WIDTH + ix;

		// link it in
		slot.chain = pl.inventory;
		pl.inventory = slot;
	}
}


entity INV_LookupSlot(entity pl, float id)
{
	entity e;

	for (e = pl.inventory ; e ; e = e.chain)
		if (e.invent_id == id)
			return e;

	error("Inventory slot not found!\n");
	return nil;  // NOT REACHED
}


entity INV_FindFreeSlot(entity pl)
{
	entity e;

	for (e = pl.inventory ; e ; e = e.chain)
		if (e.count == 0)
			return e;
	
	return nil;
}


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
	pl.i_armor		= parm7;
	pl.i_misc		= parm8;

	INV_Recreate(pl);

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


float INV_CheckHasItem(entity pl, entity e)
{
	if (pl.i_keys & e.i_keys) return TRUE;
	if (pl.i_weapons & e.i_weapons) return TRUE;
	if (pl.i_armor & e.i_armor) return TRUE;
	if (pl.i_misc & e.i_misc) return TRUE;

	return FALSE;
}


void INV_UpdateSummary(entity pl)
{
	pl.i_keys		= 0;
	pl.i_weapons	= 0;
	pl.i_armor		= 0;
	pl.i_misc		= 0;

	entity slot;

	for (slot = pl.inventory ; slot ; slot = slot.chain)
	{
		if (slot.count > 0)
		{
			pl.i_keys		= pl.i_keys		| slot.i_keys;
			pl.i_weapons	= pl.i_weapons	| slot.i_weapons;
			pl.i_armor		= pl.i_armor	| slot.i_armor;
			pl.i_misc		= pl.i_misc		| slot.i_misc;
		}
	}
}


void INV_GiveItem(entity pl, entity e)
{
	entity slot = INV_FindFreeSlot(pl);

	if (! slot)
		error("INV_GiveItem : inventory is full!");

	slot.count = 1;

	slot.description = e.description;
	slot.icon_pic = e.icon_pic;

	slot.i_keys		= e.i_keys;
	slot.i_weapons	= e.i_weapons;
	slot.i_armor	= e.i_armor;
	slot.i_misc		= e.i_misc;

	INV_UpdateSummary(pl);

	// update client too
	stuffcmd(pl, sprintf("\nui_invent %d 1 \"%s\"\n", slot.invent_id, slot.icon_pic));
}


void INV_RemoveItem(entity pl, entity slot)
{
	slot.count = 0;

	INV_UpdateSummary(pl);

	// update client too
	stuffcmd(pl, sprintf("\nui_invent %d 0 \"%s\"\n", slot.invent_id));
}


//------------------------------------------------------------------------

void INV_RecreateKey(entity pl, float i_keys)
{
	// FIXME : INV_RecreateKey
}


void INV_Recreate(entity pl)
{
	// recreate the inventory from the decoded spawnparms

	INV_Create(pl);

	float i;

	for (i = 1 ; i <= 1048576 ; i = i * 2)
		if (pl.i_keys & i)
			INV_RecreateKey(pl, i);

	// FIXME : i_weapons, i_armor, i_misc
}


void INV_SendAllToClient(entity pl)
{
	// send whole inventory to client, including empty slots
	// (for beginning of a fresh level, or after loading a savegame)

	entity slot;

	for (slot = pl.inventory ; slot ; slot = slot.chain)
	{
		if (slot.count > 0)
			stuffcmd(pl, sprintf("\nui_invent %d 0 \"\"\n", slot.invent_id));
		else
			stuffcmd(pl, sprintf("\nui_invent %d 1 \"%s\"\n", slot.invent_id, slot.icon_pic));
	}
}


//------------------------------------------------------------------------
//		HIGHLIGHTING and DRAGGING OBJECTS
//------------------------------------------------------------------------

entity highlighted_ent;  // FIXME PLAYER FIELD


void INV_CheckHighlightObject(entity pl)
{
	if (! pl.cursor_active)
		return;

	entity trace_ent = pl.cursor_trace_ent;

	if (trace_ent && ! (trace_ent.effects & EF_SELECTABLE))
		trace_ent = nil;

	if (trace_ent == highlighted_ent)
		return;

	highlighted_ent = trace_ent;

	// send description to client CSQC (empty if NO ent)

	if (highlighted_ent)
		stuffcmd(pl, sprintf("\nui_highlight 1 \"%s\"\n", highlighted_ent.description));
	else
		stuffcmd(pl, "\nui_highlight 0 \"\"\n");
}


void INV_ObjectInteraction(entity pl)
{
	INV_CheckHighlightObject(pl);
}

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
