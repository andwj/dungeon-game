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

		slot.invent_id = 1 + iy * INV_BOX_WIDTH + ix;

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
	if (pl.i_keys & e.i_keys) return true;
	if (pl.i_weapons & e.i_weapons) return true;
	if (pl.i_armor & e.i_armor) return true;
	if (pl.i_misc & e.i_misc) return true;

	return false;
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


void INV_KillItem(entity e)
{
	e.deadflag = DEAD_DEAD;

	e.effects = EF_NODRAW;
}


void INV_ResurrectItem(entity e)
{
	e.deadflag = 0;

	e.effects = EF_SELECTABLE;
}


void INV_GiveItem(entity pl, entity slot, entity e)
{
	// if 'slot' is nil, it means we find one

	if (! slot)
		slot = INV_FindFreeSlot(pl);

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

	// remember the entity (for when we drop it)
	slot.drag_obj = e;

	// make object "vanish" and never seen or selectable again
	INV_KillItem(e);

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


void INV_ClearDrag(entity pl)
{
	pl.drag_obj = nil;

	stuffcmd(pl, "\nui_drag 0\n");
}


void INV_BeginDrag(entity pl, entity e)
{
	pl.drag_obj = e;
	pl.highlight_obj = nil;

	e.effects = EF_NODRAW;

	// tell client
	stuffcmd(pl, sprintf("\nui_drag 1 \"%s\"\n", e.icon_pic));
}


void INV_CheckHighlightObject(entity pl)
{
	if (pl.drag_obj)
		return;

	entity trace_ent = pl.cursor_trace_ent;

	if (trace_ent && ! (trace_ent.effects & EF_SELECTABLE))
		trace_ent = nil;

	if (trace_ent == pl.highlight_obj)
		return;

	pl.highlight_obj = trace_ent;

	// send description to client CSQC (empty if NO ent)

	if (pl.highlight_obj)
		stuffcmd(pl, sprintf("\nui_highlight 0 1 \"%s\"\n", pl.highlight_obj.description));
	else
		stuffcmd(pl, "\nui_highlight 0 0 \"\"\n");
}


void INV_CheckBeginDrag(entity pl)
{
	// FIXME: check have free slot...  and not have it already...

	if (pl.button0 &&
		pl.highlight_obj &&
		pl.highlight_obj == pl.cursor_trace_ent &&
		pl.highlight_obj.icon_pic &&
		(pl.highlight_obj.effects & EF_SELECTABLE) &&
		! pl.highlight_obj.deadflag)
	{
		INV_BeginDrag(pl, pl.highlight_obj);
	}
}


void INV_PickupFromWorld(entity pl, entity obj)
{
	entity free_slot = INV_FindFreeSlot(pl);

	// this will not normally happen [ checked before dragging ]
	if (! free_slot)
		return;

	// already have the item?
	if (INV_CheckHasItem(pl, obj))
	{
		centerprint(pl, "You already have that!\n");
		return;
	}

	entity slot = INV_LookupSlot(pl, pl.invent_id);

	// if wanted slot is not free, use the free slot
	if (slot.count > 0)
		slot = free_slot;

	INV_GiveItem(pl, slot, obj);
}


void INV_CheckDrop(entity pl)
{
	if (! pl.button0)
	{
		entity obj = pl.drag_obj;

		INV_ClearDrag(pl);

		// FIXME : if (dropping to world) ...

		if (pl.invent_id > 0)
			INV_PickupFromWorld(pl, obj);
		else
		{
			// reset object
			obj.effects = EF_SELECTABLE;
		}
	}
}


void INV_ObjectInteraction(entity pl)
{
	if (! pl.cursor_active)
		return;

	if (pl.drag_obj)
	{
		INV_CheckDrop(pl);
	}
	else
	{
		INV_CheckBeginDrag(pl);
		INV_CheckHighlightObject(pl);
	}
}


//
// client code sends this command when user drops an item in inventory box
//
void CMD_invent_hl(entity pl)
{
	float new_id = stof(argv(1));

	if (new_id == pl.invent_id)
		return;

	pl.invent_id = new_id;

	if (new_id <= 0)
		return;
	
	entity slot = INV_LookupSlot(pl, new_id);

	// TODO : highlight object in inventory ready for dragging
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
