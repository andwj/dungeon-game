#
# Simple makefile, by Andrew Apted
#
# NOTE: this is NOT the makefile stuff which Darkplaces normally comes with.
#

PROGRAM=../DungeonGame

all: $(PROGRAM)

CC=gcc

OS=UNIX

OBJ_DIR=obj_linux

FEATURES=-DCONFIG_MENU \
	 -DLINK_TO_ZLIB -DLINK_TO_LIBJPEG

WARNINGS=-Wall -Wold-style-definition -Wstrict-prototypes -Wsign-compare 

OPTIMISE=-g3 -fno-math-errno -ffinite-math-only -fno-rounding-math -fno-signaling-nans -fno-trapping-math

SDL_CFLAGS := `sdl-config --cflags`
SDL_LIBS   := `sdl-config --libs`

CFLAGS=-D$(OS) $(FEATURES) $(WARNINGS) $(OPTIMISE) $(SDL_CFLAGS)

LIBS=-lm -lexpat  -lz -ljpeg -ldl $(SDL_LIBS) -lX11

OBJS := \
	$(OBJ_DIR)/sys_sdl.o  \
	$(OBJ_DIR)/vid_sdl.o  \
	$(OBJ_DIR)/thread_sdl.o  \
	$(OBJ_DIR)/builddate.o  \
	$(OBJ_DIR)/menu.o  \
	$(OBJ_DIR)/mvm_cmds.o  \
	$(OBJ_DIR)/snd_main.o  \
	$(OBJ_DIR)/snd_mem.o  \
	$(OBJ_DIR)/snd_mix.o  \
	$(OBJ_DIR)/snd_ogg.o  \
	$(OBJ_DIR)/snd_wav.o  \
	$(OBJ_DIR)/snd_sdl.o  \
	$(OBJ_DIR)/cd_shared.o  \
	$(OBJ_DIR)/cd_sdl.o  \
	$(OBJ_DIR)/cap_avi.o  \
	$(OBJ_DIR)/cap_ogg.o  \
	$(OBJ_DIR)/bih.o  \
	$(OBJ_DIR)/crypto.o  \
	$(OBJ_DIR)/cl_collision.o  \
	$(OBJ_DIR)/cl_demo.o  \
	$(OBJ_DIR)/cl_dyntexture.o  \
	$(OBJ_DIR)/cl_input.o  \
	$(OBJ_DIR)/cl_main.o  \
	$(OBJ_DIR)/cl_parse.o  \
	$(OBJ_DIR)/cl_particles.o  \
	$(OBJ_DIR)/cl_screen.o  \
	$(OBJ_DIR)/cl_video.o  \
	$(OBJ_DIR)/clvm_cmds.o  \
	$(OBJ_DIR)/cmd.o  \
	$(OBJ_DIR)/collision.o  \
	$(OBJ_DIR)/common.o  \
	$(OBJ_DIR)/console.o  \
	$(OBJ_DIR)/csprogs.o  \
	$(OBJ_DIR)/curves.o  \
	$(OBJ_DIR)/cvar.o  \
	$(OBJ_DIR)/dpsoftrast.o  \
	$(OBJ_DIR)/dpvsimpledecode.o  \
	$(OBJ_DIR)/filematch.o  \
	$(OBJ_DIR)/fractalnoise.o  \
	$(OBJ_DIR)/fs.o  \
	$(OBJ_DIR)/ft2.o  \
	$(OBJ_DIR)/utf8lib.o  \
	$(OBJ_DIR)/gl_backend.o  \
	$(OBJ_DIR)/gl_draw.o  \
	$(OBJ_DIR)/gl_rmain.o  \
	$(OBJ_DIR)/gl_rsurf.o  \
	$(OBJ_DIR)/gl_textures.o  \
	$(OBJ_DIR)/hmac.o  \
	$(OBJ_DIR)/host.o  \
	$(OBJ_DIR)/host_cmd.o  \
	$(OBJ_DIR)/image.o  \
	$(OBJ_DIR)/image_png.o  \
	$(OBJ_DIR)/jpeg.o  \
	$(OBJ_DIR)/keys.o  \
	$(OBJ_DIR)/lhnet.o  \
	$(OBJ_DIR)/libcurl.o  \
	$(OBJ_DIR)/mathlib.o  \
	$(OBJ_DIR)/matrixlib.o  \
	$(OBJ_DIR)/mdfour.o  \
	$(OBJ_DIR)/meshqueue.o  \
	$(OBJ_DIR)/mod_skeletal_animatevertices_sse.o  \
	$(OBJ_DIR)/mod_skeletal_animatevertices_generic.o  \
	$(OBJ_DIR)/model_alias.o  \
	$(OBJ_DIR)/model_brush.o  \
	$(OBJ_DIR)/model_shared.o  \
	$(OBJ_DIR)/model_sprite.o  \
	$(OBJ_DIR)/model_tmx.o  \
	$(OBJ_DIR)/netconn.o  \
	$(OBJ_DIR)/palette.o  \
	$(OBJ_DIR)/polygon.o  \
	$(OBJ_DIR)/portals.o  \
	$(OBJ_DIR)/protocol.o  \
	$(OBJ_DIR)/prvm_cmds.o  \
	$(OBJ_DIR)/prvm_edict.o  \
	$(OBJ_DIR)/prvm_exec.o  \
	$(OBJ_DIR)/r_explosion.o  \
	$(OBJ_DIR)/r_lerpanim.o  \
	$(OBJ_DIR)/r_lightning.o  \
	$(OBJ_DIR)/r_modules.o  \
	$(OBJ_DIR)/r_shadow.o  \
	$(OBJ_DIR)/r_sky.o  \
	$(OBJ_DIR)/r_sprites.o  \
	$(OBJ_DIR)/sbar.o  \
	$(OBJ_DIR)/sv_demo.o  \
	$(OBJ_DIR)/sv_main.o  \
	$(OBJ_DIR)/sv_move.o  \
	$(OBJ_DIR)/sv_phys.o  \
	$(OBJ_DIR)/sv_user.o  \
	$(OBJ_DIR)/svbsp.o  \
	$(OBJ_DIR)/svvm_cmds.o  \
	$(OBJ_DIR)/sys_shared.o  \
	$(OBJ_DIR)/vid_shared.o  \
	$(OBJ_DIR)/view.o  \
	$(OBJ_DIR)/wad.o  \
	$(OBJ_DIR)/world.o  \
	$(OBJ_DIR)/zone.o

$(OBJ_DIR)/%.o: ./%.c
	$(CC) $(CFLAGS) -o $@ -c $<

$(PROGRAM): $(OBJS)
	$(CC) -Wl,--warn-common $^ -o $@ $(LDFLAGS) $(LIBS)

clean:
	rm -f $(PROGRAM) $(OBJ_DIR)/*.o ERRS

#--- editor settings ------------
# vi:ts=8:sw=8:noexpandtab
