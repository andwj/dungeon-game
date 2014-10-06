//------------------------------
// MENU : Main Script
//------------------------------


void m_init()
{
  print("m_init....\n");
}


void m_shutdown()
{
  print("m_shutdown....\n");
}


void m_keyup(float key, float ascii)
{
  print("m_keyup\n");
}


void m_keydown(float key, float ascii)
{
  print("m_keydown =\n");
  print(ftos(key));
}


void m_draw()
{
}


void m_toggle(float mode)
{
  print("m_toggle =\n");
  print(ftos(mode));
}

