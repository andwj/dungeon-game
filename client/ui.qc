

vector mouse_pos;


// description for object currently under the cursor
// NOTE : will be strzone'd (if not empty) so use carefully!
string obj_description;


void UI_CMD_describe(string cmd)
{
	if (obj_description != "")
	{
		strunzone(obj_description);
		obj_description = "";
	}

	// rest of the command line is the description
	string desc = substring(cmd, 12, 200);

	if (desc == "")
		return;

	obj_description = strzone(desc);
}


void UI_DrawDescription()
{
	vector scale = '10 10 0';
	vector pos   = mouse_pos + '0 20 0';
	vector color = '2 2 2';

	float width = stringwidth(obj_description, FALSE /* colorcodes */, scale);

	float clip_x1 = 0;
	float clip_x2 = 640;  //FIXME!!!  vid_conwidth

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


void UI_Draw()
{
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


//------------------------------------------------------------------------

void CSQC_Init()
{
	print("CSQC_Init....\n");

	registercommand("ui_describe");

	// turn on Prydon cursor mode
	cvar_set("cl_prydoncursor", "1");

	// ensure we get mouse move events (even with Prydon cursor enabled)
	setcursormode(1);
}


void CSQC_Shutdown()
{
	print("CSQC_Shutdown....\n");
}


float CSQC_ConsoleCommand(string cmd)
{
	tokenize(cmd);

	if (argv(0) == "ui_describe")
	{
		UI_CMD_describe(cmd);
		return 1;
	}

	print("CSQC_ConsoleCommand: ");
	print(argv(0));
	print("\n");

	return 0;
}


void CSQC_UpdateView(float vwidth, float vheight)
{
	UI_RenderWorld();
	UI_Draw();
}


#define EVENT_KeyDown    0
#define EVENT_KeyUp      1
#define EVENT_RelMouse   2
#define EVENT_AbsMouse   3


float CSQC_InputEvent(float evtype, float x, float y)
{
	if (evtype == EVENT_AbsMouse)
	{
		mouse_pos_x = x;
		mouse_pos_y = y;
	}

	return 0;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
