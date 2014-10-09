

void CSQC_Init()
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


void CSQC_UpdateView(float vwidth, float vheight)
{
	clearscene();

	setproperty(VF_DRAWWORLD, 1);

	addentities(MASK_ENGINE | MASK_ENGINEVIEWMODELS | MASK_NORMAL);

	renderscene();
}


float CSQC_InputEvent(float evtype, float x, float y)
{
	// TODO

	return 0;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
