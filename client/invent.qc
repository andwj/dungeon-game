
//
//  Inventory handling  (Client-Side)
//


// the inventory we show is stored using entities
.string invent_pic;   // empty if no entity there
.string invent_desc;  // description

.float invent_x;	// box coord (also serves as ID number)
.float invent_y;	//

.float invent_flags;


// list of inventory objects
entity inventory_head;


void UI_CreateInventory()
{
	float ix, iy;

	for (ix = 0 ; ix < 4 ; ++ix)
	for (iy = 0 ; iy < 4 ; ++iy)
	{
		entity box = spawn();

		box.invent_x = ix;
		box.invent_y = iy;

box.invent_pic = "items/gold_key_icon";

		// link it in
		box.chain = inventory_head;
		inventory_head = box;
	}
}


entity UI_GetInventorySlot(float ix, float iy)
{
	entity e;

	for (e = inventory_head ; e ; e = e.chain)
		if (e.invent_x == ix && e.invent_y == iy)
			return e;
	
	error("Inventory slot not found!\n");
	return inventory_head;
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
