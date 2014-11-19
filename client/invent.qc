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


//
//  Inventory handling  (Client-Side)
//


// the inventory we show is stored using entities
.float invent_id;

.float invent_x;	// drawing coord
.float invent_y;	//

.string invent_pic;   // [zoned]  empty if no entity there

//??  .string invent_desc;  // description

.float invent_flags;


// list of inventory objects
entity inventory_head;

// slot ID that mouse is currently over, zero if none
float inv_mouse_slot;


void INV_Create()
{
	float ix, iy, id;

	for (ix = 0 ; ix < INV_BOX_WIDTH  ; ++ix)
	for (iy = 0 ; iy < INV_BOX_HEIGHT ; ++iy)
	{
		id = 1 + iy * INV_BOX_WIDTH + ix;

		if (id > INV_WIELD_BOX)
			return;

		entity box = spawn();

		box.invent_id = id;

		box.invent_x = ix;
		box.invent_y = iy;

		// link it in
		box.chain = inventory_head;
		inventory_head = box;
	}
}


entity INV_LookupSlot(float id)
{
	entity slot;

	for (slot = inventory_head ; slot ; slot = slot.chain)
		if (slot.invent_id == id)
			return slot;
	
	error("Inventory slot not found!\n");
	return nil;
}


// handle the "ui_invent" command from the game (on server)
void CMD_invent()
{
	float id = stof(argv(1));

	entity slot = INV_LookupSlot(id);

	slot.invent_flags = stof(argv(2));

	slot.invent_pic = zoned_string(slot.invent_pic, argv(3));
}


void UI_DrawItem(vector box_pos, entity e)
{
	if (e.invent_pic == "")
e.invent_pic = "foo";  if (false)
		return;
	
	// TODO if (e.invent_flags & INV_DRAGGING) return;

	vector color = '1 1 1';

	if (e.invent_id == inv_mouse_slot)
		color = '2 2 2';

	if (e.invent_id == INV_WIELD_BOX)
	{
		box_pos = box_pos + '12 206 0';

		drawpic(box_pos, e.invent_pic, '72 72 0', color, ALPHA_NORMAL, DRAWFLAG_NORMAL);
		return;
	}

	box_pos = box_pos + '7 31 0';
	box_pos = box_pos + e.invent_x * '43 0 0';
	box_pos = box_pos + e.invent_y * '0 43 0';

	drawpic(box_pos, e.invent_pic, '40 40 0', color, ALPHA_NORMAL, DRAWFLAG_NORMAL);
}


void UI_DrawInventory()
{
	vector bg_size = draw_getimagesize("gfx/invent_box");

	vector pos = '0 0 0';

	pos_x = scr_width  - 104;
	pos_y = scr_height - 310;

	drawpic(pos, "gfx/invent_box", SIZE_NORMAL, COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

	/* draw the items */

	entity e;

	for (e = inventory_head ; e ; e = e.chain)
		UI_DrawItem(pos, e);
}


// 
// check if mouse is over an inventory box, and return the ID number
// of the box, or zero if not over it.
//
float UI_MouseToInventory()
{
	vector bg_size = draw_getimagesize("gfx/invent_box");

	vector pos = '0 0 0';

	pos_x = scr_width        - bg_size_x;
	pos_y = scr_height - 200 - bg_size_y;

	pos = pos + '15 70 0';

	float ix = floor((mouse_pos_x - pos_x) / 76);
	float iy = floor((mouse_pos_y - pos_y) / 64);

	if (ix < 0 || ix >= INV_BOX_WIDTH)  return 0;
	if (iy < 0 || iy >= INV_BOX_HEIGHT) return 0;

	// find it
	entity slot;

	for (slot = inventory_head ; slot ; slot = slot.chain)
	{
		if (slot.invent_x == ix && slot.invent_y == iy)
			return slot.invent_id;
	}

	// uhh, WTF?
	return 0;
}


void CheckMouseOverInventory()
{
	float id = UI_MouseToInventory();

	if (inv_mouse_slot == id)
		return;

	inv_mouse_slot = id;

	// tell the server what we are looking at
	localcmd(sprintf("\ncmd invent_hl %d\n", id));
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
