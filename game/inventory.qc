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
		slot.owner = pl;

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


bool INV_CheckHasItem(entity pl, entity e)
{
	entity slot;

	for (slot = pl.inventory ; slot ; slot = slot.chain)
		if (slot.enemy == e)
			return true;

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


void INV_HideItem(entity e)
{
	e.deadflag = DEAD_DEAD;

	e.effects = EF_NODRAW;
}


void INV_UnhideItem(entity e)
{
	e.deadflag = 0;

	e.effects = 0;
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
	slot.enemy = e;

	// mark owner of item [used during dragging to world]
	e.owner = slot;

	INV_HideItem(e);

	// update client too
	stuffcmd(pl, sprintf("\nui_invent %d 1 \"%s\"\n", slot.invent_id, slot.icon_pic));
}


void INV_RemoveItem(entity pl, entity slot)
{
	slot.count = 0;
	slot.enemy = nil;

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


//
// Check whether mouse pointer is pointing at a place where we can drop
// an object.  Returns 'true' if can drop there, and 'trace_endpos' will
// contain the new origin for the object.
//
// We start with 'cursor_trace_end' position, if valid, and try several
// points of it coming back towards the camera.  We also try increasing Z
// coordinate, to account for places too close to the floor.
//
// For those coordinates we tracebox downwards, doing logic similar to
// the 'droptofloor' builtin.  But we do not allow touching any existing
// entities.
//
bool Drop_Trace_test_spot(vector pos, entity obj)
{
	tracebox(pos, '-12 -12 -2', '12 12 64', pos - '0 0 128', MOVE_NORMAL, obj /* pass_ent */);

	// no solid surface to sit on
	if (trace_fraction >= 1.0)
		return false;
	
	if (trace_startsolid || trace_allsolid)
		return false;

	return true;
}


bool Drop_Trace(entity pl, entity obj)
{
	// validate the current cursor trace
	if (! pl.cursor_active)
		return false;
	
	vector delta = pl.cursor_trace_endpos - pl.cursor_trace_start;
	float dist = vlen(delta);

	// too far away ?
	if (dist > 800)
		return false;

	// too close to camera?
	if (dist < 96)
		return false;


	delta = normalize(delta);

	float back;

	for (back = 16 ; back <= 64 ; back = back + 16)
	{
		vector pos = pl.cursor_trace_endpos - delta * back;

		if (Drop_Trace_test_spot(pos, obj)) return true;
		if (Drop_Trace_test_spot(pos + '0 0 50', obj)) return true;
	}

	return false;
}


void INV_ShowDropSpot(entity pl)
{
	entity obj = pl.drop_indicator;

	obj.effects = EF_NODRAW;
	
	// don't show it when picking up
	if (! pl.drag_obj.owner)
		return;

	// don't show it when about to "use" an item (e.g. drop KEY on a LOCK)
	if (pl.highlight_obj)
		return;

	if (Drop_Trace(pl, obj))
	{
		obj.effects = 0;  // make visible

		setorigin(obj, trace_endpos);
	}
}


void INV_ClearDrag(entity pl)
{
	pl.drag_obj = nil;

	stuffcmd(pl, "\nui_drag 0\n");
}


void INV_BeginDrag(entity pl, entity e)
{
	pl.drag_obj = e;

	e.effects = EF_NODRAW;

	// tell client
	stuffcmd(pl, sprintf("\nui_drag 1 \"%s\"\n", e.icon_pic));
}


void INV_CheckHighlightObject(entity pl)
{
	entity trace_ent = pl.cursor_trace_ent;

	if (trace_ent && ! trace_ent.description)
		trace_ent = nil;

	if (trace_ent && trace_ent.deadflag)
		trace_ent = nil;

	// no description while dragging...
	if (pl.drag_obj)
	{
		// check for dragging a KEY to a LOCK (for example)
		if (pl.drag_obj.owner &&
			trace_ent && trace_ent.lock_item == pl.drag_obj.classname)
		{
			/* allow it to be highlighted */
		}
		else
			trace_ent = nil;
	}

	if (trace_ent == pl.highlight_obj)
		return;

	if (pl.highlight_obj)
		pl.highlight_obj.colormod = '1 1 1';

	pl.highlight_obj = trace_ent;

	if (pl.highlight_obj)
		pl.highlight_obj.colormod = '2 2 2';

	// send description to client CSQC (empty if NO ent)

	if (pl.highlight_obj)
		stuffcmd(pl, sprintf("\nui_highlight 1 0 \"%s\"\n", pl.highlight_obj.description));
	else
		stuffcmd(pl, "\nui_highlight 0 0 \"\"\n");
}


void INV_CheckBeginDrag(entity pl)
{
	// FIXME: check have free slot...  and not have it already...

	if (! pl.button0)
		return;

	// paranoia check (should not happen)
	if (! pl.drop_indicator)
		return;

	if (pl.highlight_obj &&
		pl.highlight_obj == pl.cursor_trace_ent &&
		pl.highlight_obj.icon_pic &&
		! pl.highlight_obj.deadflag)
	{
		INV_BeginDrag(pl, pl.highlight_obj);
		return;
	}

	if (! pl.highlight_obj && pl.invent_id > 0)
	{
		entity slot = INV_LookupSlot(pl, pl.invent_id);

		if (slot)
		if (slot.count > 0 && slot.enemy)
		{
			entity obj = slot.enemy;

			pl.drag_obj = obj;

			// tell client
			stuffcmd(pl, sprintf("\nui_drag 2 \"%s\"\n", obj.icon_pic));
			return;
		}
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


void INV_DropToWorld(entity pl, entity obj, vector where)
{
	INV_RemoveItem(pl, obj.owner /* slot */);

	obj.owner = nil;

	INV_UnhideItem(obj);

	setorigin(obj, where);
}


void INV_ApplyObject(entity pl, entity obj, entity receiver)
{
	INV_RemoveItem(pl, obj.owner);

	obj.owner = nil;

	// we could remove() the entity now, but there is little need
	INV_HideItem(obj);

	// activate the target object
	entity old_self = self;

	activator = pl;
	self = receiver;
	SUB_UseTargets();

	self = old_self;
}


void INV_PerformDrop(entity pl)
{
	entity obj = pl.drag_obj;

	INV_ClearDrag(pl);

	if (obj.owner)
	{
		// dropping to world...

		if (pl.highlight_obj)
		{
			// want to "apply" the object (e.g. KEY on a LOCK)
			INV_ApplyObject(pl, obj, pl.highlight_obj);
		}
		else if (pl.drop_indicator.effects & EF_NODRAW)
		{
			// no valid spot -- cancel
		}
		else
		{
			INV_DropToWorld(pl, obj, pl.drop_indicator.origin);
		}
	}
	else if (pl.invent_id > 0)
	{
		INV_PickupFromWorld(pl, obj);
	}
	else
	{
		// cancel a pick-up : unhide object
		obj.effects = 0;
	}

	pl.drop_indicator.effects = EF_NODRAW;
}


void INV_ObjectInteraction(entity pl)
{
	if (! pl.cursor_active)
		return;

	if (pl.drag_obj)
	{
		if (pl.button0)
			INV_ShowDropSpot(pl);
		else
			INV_PerformDrop(pl);
	}
	else
	{
		INV_CheckBeginDrag(pl);
	}

	INV_CheckHighlightObject(pl);
}


//
// client code sends this to specify which part of inventory box the
// mouse pointer is currently over (0 for none).
//
void CMD_invent_hl(entity pl)
{
	float new_id = stof(argv(1));

	if (new_id == pl.invent_id)
		return;

	pl.invent_id = new_id;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
