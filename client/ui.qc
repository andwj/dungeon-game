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


/* --- HIGHLIGHT / DRAGGING STATE --- */

// description for object currently under the cursor
string obj_description;  // [zoned]
float  highlight_mode;
float  highlight_slot;

// picture for object being dragged
string obj_drag_pic;     // [zoned]
float  dragging_mode;

float  can_drop_mode;


void CMD_highlight()
{
	highlight_mode = stof(argv(1));
	highlight_slot = stof(argv(2));

	obj_description = zoned_string(obj_description, argv(3));
}


void CMD_drag()
{
	dragging_mode = stof(argv(1));

	obj_drag_pic = zoned_string(obj_drag_pic, argv(2));

	// while dragging, show the "grab" hand cursor
	if (dragging_mode)
		cvar_set("cl_prydoncursor", "2");
	else
		cvar_set("cl_prydoncursor", "1");
}


void UI_ClearDrag()
{
	obj_drag_pic = zoned_string(obj_drag_pic, "");

	if (cvar("cl_prydoncursor") > 1)
		cvar_set("cl_prydoncursor", "1");
}


void CMD_can_drop()
{
	can_drop_mode = stof(argv(1));
}


void UI_DrawDragObject()
{
	vector size = drawgetimagesize(obj_drag_pic) / 1.6;

	vector pos = mouse_pos - size * 0.64;

	drawpic(pos, obj_drag_pic, size, COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);
}


void UI_DrawDescription()
{
	vector size  = '20 20 0';
	vector pos   = mouse_pos + '0 70 0';
	vector color = '2 2 2';

	float width = stringwidth(obj_description, FALSE /* colorcodes */, size);

	float clip_x1 = 0;
	float clip_x2 = scr_width;  // LESS IF INVENTORY IS SHOWN

	// position string near the cursor, but make it depend on absolute X
	// coordinate (so it never gets chopped off by edge of screen)
	float a;
	if (mouse_pos_x < clip_x1)
		a = 0;
	else if (mouse_pos_x > clip_x2)
		a = 1;
	else
		a = (mouse_pos_x - clip_x1) / (clip_x2 - clip_x1);

	pos_x = pos_x - width * a;

	drawstring(pos, obj_description, size, color, 1.0 /* alpha */, DRAWFLAG_NORMAL);
}


void UI_DrawHealthBar(vector pos, float w, float h, vector color, vector text_color, float qty)
{
	vector size = to_vector(w * qty / 100, h, 0);

	if (size_x > 0)
		drawfill(pos, size, color, ALPHA_NORMAL, DRAWFLAG_NORMAL);

	pos_x = pos_x + w;
	pos_y = pos_y - 4;

	size_y = h * 1.2;
	size_x = size_y;

	string qty_str = sprintf("%d", max(qty, 0));

	drawstring(pos, qty_str, size, text_color, ALPHA_NORMAL, DRAWFLAG_NORMAL);
}


void UI_DrawStats()
{
	vector pos = '0 0 0';

	pos_x = scr_width - 104;
	pos_y = scr_height - 400;

	drawpic(pos, "gfx/health_box", SIZE_NORMAL, COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

/*  OLD STUFF
	vector bg_size = draw_getimagesize("gfx/stat_box");

	vector pos = '0 0 0';

	pos_x = scr_width  - bg_size_x;
	pos_y = scr_height - bg_size_y;

	drawpic(pos, "gfx/stat_box", SIZE_NORMAL, '1 1 1', 1.0, 0);

	pos = pos + '114 100 0';

	UI_DrawHealthBar(pos, 120, 14, '1.0 0.0 0.0', '2.0 0.0 0.0', getstati(STAT_HEALTH));

	pos = pos + '0 40 0';

	UI_DrawHealthBar(pos, 120, 14, '0.3 0.7 1.0', '0.0 1.0 2.0', getstati(STAT_ARMOR));
*/
}



void UI_Draw()
{
	UI_DrawMoveButtons();

	UI_DrawStats();

	UI_DrawInventory();

	if (obj_drag_pic != "")
		UI_DrawDragObject();

	if (obj_description != "")
		UI_DrawDescription();
}


//
// Check if mouse pointer is over part of the user interface (especially
// the inventory box).  When it is, disable ability to select objects.
//
bool mouse_over_gui;

void UI_CheckMouseOverGUI()
{
	bool old_val = mouse_over_gui;

	// FIXME : proper test !!
	if (mouse_pos_x > scr_width - 350)
		mouse_over_gui = TRUE;
	else
		mouse_over_gui = FALSE;

	if (mouse_over_gui != old_val)
	{
		if (mouse_over_gui)
			cvar_set("cl_prydoncursor_notrace", "1");
		else
			cvar_set("cl_prydoncursor_notrace", "0");
	}

	CheckMouseOverInventory();
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
