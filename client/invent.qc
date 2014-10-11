
//
//  Inventory handling  (Client-Side)
//


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

