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

//------------------------------
// MENU : Main Script
//------------------------------

float menu_state;

#define MENU_OFF    0
#define MENU_Main   1
#define MENU_Game   2
#define MENU_Options   3
#define MENU_Help   4
#define MENU_Confirm_New    5
#define MENU_Confirm_Quit   6

// button the mouse is currently over
string over_button;

float menu_initialized;


void Menu_Show()
{
	menu_state = MENU_Main;

	setkeydest(KEY_MENU);
}


void Menu_Hide()
{
	menu_state = MENU_OFF;

	if (clientstate() == CS_CONNECTED)
		setkeydest(KEY_GAME);
}


void Draw_Cursor()
{
	drawpic(mouse_pos, "gfx/prydoncursor001", SIZE_NORMAL, '1 1 1', 1.0, DRAWFLAG_NORMAL);
}


void Draw_Title()
{
	SCR_DrawBackground("gfx/title", '0 0 0');
}


//---------------------- CALLBACKS -------------------------------------

void m_init()
{
	print("m_init....\n");

	UpdateScreenSize();

	print("menu width  : "); print(ftos(vid_width));  print("\n");
	print("menu height : "); print(ftos(vid_height)); print("\n");

	menu_state = MENU_OFF;

	menu_initialized = 1;
}


void m_shutdown()
{
	print("m_shutdown....\n");
}


void m_toggle(float mode)
{
	print("m_toggle = "); print(ftos(mode)); print("\n");

	// andrewj : special logic for handling the very first call.
	//
	// That is because the engine ALWAYS executes a "menutoggle 1" command
	// during start-up.  However what we want is to just show the title
	// screen (and play the title music), and user presses a key to bring
	// up the menu.

	if (mode && menu_initialized == 1)
	{
		menu_initialized = 2;

		setkeydest(KEY_MENU);
		return;
	}

	if (mode)
		Menu_Show();
	else
		Menu_Hide();
}


/* engine callback */
void m_keyup(float key, float ascii)
{
	print("m_keyup\n");
}


/* engine callback */
void m_keydown(float key, float ascii)
{
	print("m_keydown = "); print(ftos(key)); print("\n");

	if (menu_state && key == K_ESCAPE)
	{
		Menu_Hide();
		return;
	}

	if (menu_state == MENU_Main && key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		if (over_button == "quit")
			cmd("\nquit\n");

		if (over_button == "test")
			cmd("\nmap test.obj\n");
	}

	if (menu_state == MENU_OFF && clientstate() != CS_CONNECTED)
	{
		Menu_Show();
		return;
	}
}


//------------------------------------------------------------------------


void draw_text(float x, float y, string text)
{
	vector pos = '0 0 0';
	pos_x = x;
	pos_y = y;

	vector scale = '25 35 0';
	vector color = '2 2 2';

	drawstring(pos, text, scale, color, 1.0 /* alpha */, DRAWFLAG_NORMAL);
}


void M_TextButton(string button, float x, float y, string text)
{
	vector pos = '0 0 0';
	pos_x = x;
	pos_y = y;

	vector scale = '25 35 0';
	vector color = '2 0 0';

	if (mouse_pos_x >= 0)
	{
		if ((mouse_pos_x > x - 50) && (mouse_pos_x < x + 300 &&
			(mouse_pos_y > y - 5)  && (mouse_pos_y < y + 30)))
		{
			over_button = button;

			color = '2 2 0';
		}
	}

	drawstring(pos, text, scale, color, 1.0 /* alpha */, DRAWFLAG_NORMAL);
}


void Menu_DrawMain()
{
	draw_text(320, 100, "MAIN MENU");

	over_button = "";

	M_TextButton("test", 400, 150, "Test Map");
	M_TextButton("quit", 400, 200, "Quit");
}


/* engine callback */
void m_draw()
{
	UpdateScreenSize();

	mouse_pos = getmousepos();

	// is player in game?  if not, draw the title picture
	if (clientstate() != CS_CONNECTED)
	{
		Draw_Title();
	}

	if (menu_state == MENU_OFF)
		return;

	// darken screen
	drawfill('0 0 0', scr_size, '0 0 0', 0.5, DRAWFLAG_NORMAL);

	if (menu_state == MENU_Main)
		Menu_DrawMain();

	Draw_Cursor();
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
