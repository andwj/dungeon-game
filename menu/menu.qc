//------------------------------
// MENU : Main Script
//------------------------------


void m_init()
{
  print("m_init....")
}


void m_shutdown()
{
  print("m_shutdown....")
}


void m_keyup(float key, float ascii)
{
  print("m_keyup")
}


void m_keydown(float key, float ascii)
{
  print("m_keydown =")
  print(ftos(key))
}


void m_draw()
{
}


void m_toggle(float mode)
{
  print("m_toggle =")
  print(ftos(mode))
}

