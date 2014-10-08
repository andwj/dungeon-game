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


float vid_width;
float vid_height;


void GetVidWidth()
{
	vid_width  = cvar("vid_conwidth");
	vid_height = cvar("vid_conheight");
}


//---------------------- CALLBACKS -------------------------------------

void m_init()
{
	print("m_init....\n");

	GetVidWidth();

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
}


void m_draw()
{
	if (menu_state == MENU_OFF)
		return;

	vector back_size;

	back_size_x = vid_width;
	back_size_y = vid_height;
	back_size_z = 0;

	drawpic('0 0 0', "gfx/title", back_size, '1 1 1', 1.0, 0);
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
