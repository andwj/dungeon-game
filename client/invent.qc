
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
	float x, y;

	for (x = 0 ; x < 4 ; ++x)
	for (y = 0 ; y < 4 ; ++y)
	{
		entity box = spawn();

		box.invent_x = x;
		box.invent_y = y;

		// link it in
		box.chain = inventory_head;
		inventory_head = box;
	}
}


void UI_DrawInventory()
{
	vector bg_size = draw_getimagesize("gfx/invent_box");

	vector pos = '0 0 0';

	pos_x = scr_width        - bg_size_x;
	pos_y = scr_height - 200 - bg_size_y;

	drawpic(pos, "gfx/invent_box", '0 0 0', '1 1 1', 1.0, 0);

	// TEST for drawing an item...
	pos = pos + '15 70 0';

	drawpic(pos, "items/gold_key_icon", '64 64 0', '1 1 1', 1.0, 0);
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
