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


// description for object currently under the cursor
string obj_description;  // [zoned]
float  highlight_flags;

// picture for object being dragged
string obj_drag_pic;     // [zoned]


void CMD_highlight()
{
	highlight_flags = stof(argv(1));

	obj_description = zoned_string(obj_description, argv(2));
}


void UI_DrawDescription()
{
	vector scale = '14 14 0';
	vector pos   = mouse_pos + '0 70 0';
	vector color = '2 2 2';

	float width = stringwidth(obj_description, FALSE /* colorcodes */, scale);

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

	drawstring(pos, obj_description, scale, color, 1.0 /* alpha */, DRAWFLAG_NORMAL);
}


void UI_DrawStats()
{
	vector bg_size = draw_getimagesize("gfx/stat_box");

	vector pos = '0 0 0';

	pos_x = scr_width  - bg_size_x;
	pos_y = scr_height - bg_size_y;

	drawpic(pos, "gfx/stat_box", SIZE_NORMAL, '1 1 1', 1.0, 0);
}



void UI_Draw()
{
	UI_DrawStats();

	UI_DrawInventory();

	if (obj_description != "")
		UI_DrawDescription();
}


void UI_RenderWorld()
{
	clearscene();

	setproperty(VF_DRAWWORLD, 1);

	addentities(MASK_ENGINE | MASK_ENGINEVIEWMODELS | MASK_NORMAL);

	renderscene();
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
