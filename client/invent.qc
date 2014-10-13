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


void UI_CreateInventory()
{
	float ix, iy;

	for (ix = 0 ; ix < INV_BOX_WIDTH  ; ++ix)
	for (iy = 0 ; iy < INV_BOX_HEIGHT ; ++iy)
	{
		entity box = spawn();

		box.invent_id = iy * INV_BOX_WIDTH + ix;

		box.invent_x = ix;
		box.invent_y = iy;

		// link it in
		box.chain = inventory_head;
		inventory_head = box;
	}
}


entity UI_GetInventorySlot(float id)
{
	entity e;

	for (e = inventory_head ; e ; e = e.chain)
		if (e.invent_id == id)
			return e;
	
	error("Inventory slot not found!\n");
	return inventory_head;
}


// handle the "ui_invent" command from the game (on server)
void CMD_invent()
{
	float id = stof(argv(1));

	entity slot = UI_GetInventorySlot(id);

	slot.invent_flags = stof(argv(2));

	slot.invent_pic = zoned_string(slot.invent_pic, argv(3));
}


void UI_DrawItem(vector box_pos, entity e)
{
	if (e.invent_pic == "")
		return;
	
	// TODO if (e.invent_flags & INV_DRAGGING) return;

	box_pos = box_pos + '15 70 0';
	box_pos = box_pos + e.invent_x * '76 0 0';
	box_pos = box_pos + e.invent_y * '0 64 0';

	drawpic(box_pos, e.invent_pic, '64 64 0', '1 1 1', 1.0, 0);
}


void UI_DrawInventory()
{
	vector bg_size = draw_getimagesize("gfx/invent_box");

	vector pos = '0 0 0';

	pos_x = scr_width        - bg_size_x;
	pos_y = scr_height - 200 - bg_size_y;

	drawpic(pos, "gfx/invent_box", '0 0 0', '1 1 1', 1.0, 0);

	/* draw the items */

	entity e;

	for (e = inventory_head ; e ; e = e.chain)
		UI_DrawItem(pos, e);
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
