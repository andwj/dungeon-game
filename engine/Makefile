#
# Simple makefile, by Andrew Apted
#
# NOTE: this is NOT the makefile stuff which Darkplaces normally comes with.
#

PROGRAM=darkplaces-sdl

FEATURES = -DCONFIG_MENU -DCONFIG_CD -DCONFIG_VIDEO_CAPTURE

## -DDP_MAKE_TARGET=linux
## -DDP_SOUND_API=ALSA

CC=gcc

CFLAGS=-Wall -Wold-style-definition -Wstrict-prototypes -Wsign-compare \
        -DLINK_TO_ZLIB -DLINK_TO_LIBJPEG  -D_FILE_OFFSET_BITS=64 \
        -D__KERNEL_STRICT_NAMES -DCONFIG_MENU -DCONFIG_CD -DCONFIG_VIDEO_CAPTURE

OPTIMISE=-g3 -fno-math-errno -ffinite-math-only -fno-rounding-math -fno-signaling-nans -fno-trapping-math

MORE_FLAGS=-DBUILDTYPE=debug

LIBS = -lm -lexpat  -lz -ljpeg -lrt -ldl $(SDL_LIBS) -lX11

SDL_CFLAGS := `sdl-config --cflags`
SDL_LIBS   := `sdl-config --libs`

OBJS :=
	sys_sdl.o  \
	vid_sdl.o  \
	thread_sdl.o  \
	menu.o  \
	mvm_cmds.o  \
	snd_main.o  \
	snd_mem.o  \
	snd_mix.o  \
	snd_ogg.o  \
	snd_wav.o  \
	snd_sdl.o  \
	cd_shared.o  \
	cd_sdl.o  \
	cap_avi.o  \
	cap_ogg.o  \
	bih.o  \
	crypto.o  \
	cl_collision.o  \
	cl_demo.o  \
	cl_dyntexture.o  \
	cl_input.o  \
	cl_main.o  \
	cl_parse.o  \
	cl_particles.o  \
	cl_screen.o  \
	cl_video.o  \
	clvm_cmds.o  \
	cmd.o  \
	collision.o  \
	common.o  \
	console.o  \
	csprogs.o  \
	curves.o  \
	cvar.o  \
	dpsoftrast.o  \
	dpvsimpledecode.o  \
	filematch.o  \
	fractalnoise.o  \
	fs.o  \
	ft2.o  \
	utf8lib.o  \
	gl_backend.o  \
	gl_draw.o  \
	gl_rmain.o  \
	gl_rsurf.o  \
	gl_textures.o  \
	hmac.o  \
	host.o  \
	host_cmd.o  \
	image.o  \
	image_png.o  \
	jpeg.o  \
	keys.o  \
	lhnet.o  \
	libcurl.o  \
	mathlib.o  \
	matrixlib.o  \
	mdfour.o  \
	meshqueue.o  \
	mod_skeletal_animatevertices_sse.o  \
	mod_skeletal_animatevertices_generic.o  \
	model_alias.o  \
	model_brush.o  \
	model_shared.o  \
	model_sprite.o  \
	model_tmx.o  \
	netconn.o  \
	palette.o  \
	polygon.o  \
	portals.o  \
	protocol.o  \
	prvm_cmds.o  \
	prvm_edict.o  \
	prvm_exec.o  \
	r_explosion.o  \
	r_lerpanim.o  \
	r_lightning.o  \
	r_modules.o  \
	r_shadow.o  \
	r_sky.o  \
	r_sprites.o  \
	sbar.o  \
	sv_demo.o  \
	sv_main.o  \
	sv_move.o  \
	sv_phys.o  \
	sv_user.o  \
	svbsp.o  \
	svvm_cmds.o  \
	sys_shared.o  \
	vid_shared.o  \
	view.o  \
	wad.o  \
	world.o  \
	zone.o

#--- editor settings ------------
# vi:ts=8:sw=8:noexpandtab
