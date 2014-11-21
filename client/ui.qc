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

float  active_move_impulse;


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
	vector size = drawgetimagesize(obj_drag_pic);

	vector pos = mouse_pos - size * 0.64;

	drawpic(pos, obj_drag_pic, size, COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);
}


void UI_DrawDescription()
{
	vector size  = '16 16 0';
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


vector UI_ColorForHealth(float h)
{
	vector col1 = '0.8 0 0.1';
	vector col2 = '0.65 0.65 0.1';
	vector col3 = '0.1 0.55 0.1';

	if (h > 100) return col3;
	if (h > 55)  return col2 + (col3 - col2) * ((h - 55) / 45);
	if (h > 10)  return col1 + (col2 - col1) * ((h - 10) / 45);

	return col1;
}


void UI_DrawHealth()
{
	vector pos = '0 0 0';

	pos_x = scr_width - 104;
	pos_y = 202 * scr_height / 600;


	float qty = getstati(STAT_HEALTH);
	if (qty > 100) qty = 100;

	vector bar_size = '0 30 0';
	bar_size_x = 2 + qty * (84 / 100);

	vector bar_color = UI_ColorForHealth(qty);

	drawfill(pos + '4 28 0', '88 30 0', bar_color * 0.3, ALPHA_NORMAL, DRAWFLAG_NORMAL);
	drawfill(pos + '4 28 0', bar_size,  bar_color, ALPHA_NORMAL, DRAWFLAG_NORMAL);


	drawpic(pos, "gfx/health_box", SIZE_NORMAL, COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);


	/* draw number */

	string qty_str;
	if (qty <= 0)
		qty_str = "dead";
	else
		qty_str = sprintf("%d%%", qty);

	vector text_size = '16 16 0';

	float str_w = stringwidth(qty_str, false, text_size);

	pos_x = pos_x + (96 - str_w) / 2;
	pos_y = pos_y + 35;

	drawstring(pos, qty_str, text_size, bar_color * 1.7, ALPHA_NORMAL, DRAWFLAG_NORMAL);
}



//
// ---- Move Button Stuff ----
//
#define TURN_RIGHT	5
#define TURN_LEFT	6


float UI_TestHighlightMoveButton(vector pos, vector pos2, vector siz)
{
	if (! SCR_MouseInBox(pos2, siz))
		return false;

	drawsetcliparea(pos2_x, pos2_y, siz_x, siz_y);

	drawpic(pos, "gfx/move_box_hl", SIZE_NORMAL, COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

	drawresetcliparea();

	return true;
}


void UI_DrawMoveButtons()
{
	vector pos = '0 0 0';

	pos_x = scr_width  - 104;
	pos_y = 40;

	drawpic(pos, "gfx/move_box", SIZE_NORMAL, COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);


	/* determine which button mouse is over */

	float impulse = 0;

	vector siz = '38 38 0';

	if (UI_TestHighlightMoveButton(pos, pos + '30 16 0', siz))
		impulse = DIR_NORTH;

	else if (UI_TestHighlightMoveButton(pos, pos + '30 102 0', siz))
		impulse = DIR_SOUTH;

	else if (UI_TestHighlightMoveButton(pos, pos + '0 75 0', siz))
		impulse = DIR_WEST;

	else if (UI_TestHighlightMoveButton(pos, pos + '58 76 0', siz))
		impulse = DIR_EAST;

	else if (UI_TestHighlightMoveButton(pos, pos + '0 37 0', siz))
		impulse = TURN_LEFT;

	else if (UI_TestHighlightMoveButton(pos, pos + '58 37 0', siz))
		impulse = TURN_RIGHT;


	active_move_impulse = impulse;
}


bool UI_ActivateMoveButton()
{
	if (active_move_impulse > 0)
	{
		localcmd(sprintf("\nimpulse %d\n", active_move_impulse));
		return true;
	}

	return false;
}


void UI_Draw()
{
	UI_DrawMoveButtons();

	UI_DrawHealth();

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
