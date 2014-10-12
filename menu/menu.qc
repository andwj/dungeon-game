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



//---------------------- CALLBACKS -------------------------------------

void m_init()
{
	print("m_init....\n");

	UpdateScreenSize();

	print("menu width  : "); print(ftos(vid_width));  print("\n");
	print("menu height : "); print(ftos(vid_height)); print("\n");

	menu_state = MENU_OFF;
}


void m_shutdown()
{
	print("m_shutdown....\n");
}


void Menu_Show()
{
	menu_state = MENU_Main;

	setkeydest(KEY_MENU);
}


void Menu_Hide()
{
	menu_state = MENU_OFF;

	setkeydest(KEY_GAME);
}


void m_toggle(float mode)
{
	print("m_toggle = "); print(ftos(mode)); print("\n");

	if (mode)
		Menu_Show();
	else
		Menu_Hide();
}


void m_keyup(float key, float ascii)
{
	print("m_keyup\n");
}


void m_keydown(float key, float ascii)
{
	print("m_keydown = "); print(ftos(key)); print("\n");

	if (menu_state && key == K_ESCAPE)
		Menu_Hide();

	if (menu_state == MENU_Main && key >= K_MOUSE1 && key <= K_MOUSE3)
	{
		if (over_button == "quit")
			cmd("\nquit\n");

		if (over_button == "test")
			cmd("\nmap test.obj\n");
	}
}


//------------------------------------------------------------------------


void draw_cursor()
{
	drawpic(mouse_pos, "gfx/prydoncursor001", SIZE_NORMAL, '1 1 1', 1.0, DRAWFLAG_NORMAL);
}


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


void m_draw()
{
	if (menu_state == MENU_OFF)
		return;

	UpdateScreenSize();

	mouse_pos = getmousepos();

	vector back_size;

	back_size_x = vid_width / 1.6;
	back_size_y = vid_height;
	back_size_z = 0;

	drawpic('0 0 0', "gfx/title", back_size, '1 1 1', 1.0, DRAWFLAG_NORMAL);

	if (menu_state == MENU_Main)
		Menu_DrawMain();

	draw_cursor();
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
