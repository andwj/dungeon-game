

void CSQC_Init(float apiver, string enginename, float enginever)
{
}


void CSQC_Shutdown()
{
}


float CSQC_ConsoleCommand(string cmd)
{
	// TODO

	return 0;
}


void CSQC_UpdateView(float vwidth, float vheight, float notmenu)
{
	clearscene();

	setviewprop(VF_DRAWWORLD, 1);

	addentities(MASK_ENGINE | MASK_VIEWMODEL | MASK_NORMAL);

	renderscene();
}


float CSQC_InputEvent(float evtype, float scanx, float chary, float devid)
{
	// TODO

	return 0;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
