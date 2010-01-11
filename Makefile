TARGET=engine
VPATH=src:src
ECHO = echo
CFG = debug
REV = SubWCRev.exe .
MACHINE = -march=pentium2 

Group2_SRC = $(notdir ${wildcard src/util/*.c}) 
Group2_DEP = $(patsubst %.c, deps/Group2_$(CFG)_%.d, ${Group2_SRC})
Group2_OBJ = $(patsubst %.c, objs.$(CFG)/Group2_%.o, ${Group2_SRC})

Group0_SRC = $(notdir ${wildcard src/snd/*.c}) 
Group0_DEP = $(patsubst %.c, deps/Group0_$(CFG)_%.d, ${Group0_SRC})
Group0_OBJ = $(patsubst %.c, objs.$(CFG)/Group0_%.o, ${Group0_SRC}) 

Group1_SRC = $(notdir ${wildcard src/gfx/*.c}) 
Group1_DEP = $(patsubst %.c, deps/Group1_$(CFG)_%.d, ${Group1_SRC})
Group1_OBJ = $(patsubst %.c, objs.$(CFG)/Group1_%.o, ${Group1_SRC}) 

Group3_SRC = $(notdir ${wildcard src/gui/*.c}) 
Group3_DEP = $(patsubst %.c, deps/Group3_$(CFG)_%.d, ${Group3_SRC})
Group3_OBJ = $(patsubst %.c, objs.$(CFG)/Group3_%.o, ${Group3_SRC}) $(Group2_OBJ) $(Group1_OBJ)
	
CC = gcc -shared -std=gnu99 --no-strict-aliasing
CDEP = gcc -E -std=gnu99

ifndef CFLAGS
CFLAGS = $(MACHINE) -ftree-vectorize
endif


# What include flags to pass to the compiler
ifdef COMSPEC
	SDLFLAGS = -I /mingw/include/sdl -mthreads 
else
	REV = cp -f
	SDLFLAGS = `sdl-config --cflags` -U_FORTIFY_SOURCE
endif

INCLUDEFLAGS= -I ../Common -I src $(SDLFLAGS) -I src/gfx -I src/snd -I src/util -I src/gui $(EXTFLAGS)

# Separate compile options per configuration
ifeq ($(CFG),debug)
	CFLAGS += -O3 -g -Wall ${INCLUDEFLAGS} -DDEBUG -fno-inline 
else
	ifeq ($(CFG),profile)
		CFLAGS += -O3 -pg -Wall ${INCLUDEFLAGS}
	else
		ifeq ($(CFG),release)
			CFLAGS += -O3 -Wall ${INCLUDEFLAGS} -s
		else
			@$(ECHO) "Invalid configuration "$(CFG)" specified."
			@$(ECHO) "You must specify a configuration when "
			@$(ECHO) "running make, e.g. make CFG=debug"
			@$(ECHO) "Possible choices for configuration are "
			@$(ECHO) "'release', 'profile' and 'debug'"
			@exit 1
		endif
	endif
endif

# A common link flag for all configurations
LDFLAGS = 

.PHONY: tools all build

build: Makefile
ifdef COMSPEC
	$(REV) ./src/version.in ./src/version.h
else
	@echo '#ifndef KLYSTRON_VERSION_H' > ./src/version.h
	@echo '#define KLYSTRON_VERSION_H' >> ./src/version.h
	@echo -n '#define KLYSTRON_REVISION "' >> ./src/version.h
	@svnversion -n . >> ./src/version.h
	@echo '"' >> ./src/version.h
	@echo '#define KLYSTRON_VERSION_STRING "klystron " KLYSTRON_REVISION' >> ./src/version.h
	@echo '#endif' >> ./src/version.h
endif
	make all CFG=$(CFG)

all: bin.$(CFG)/lib${TARGET}_snd.a bin.$(CFG)/lib${TARGET}_gfx.a bin.$(CFG)/lib${TARGET}_util.a bin.$(CFG)/lib${TARGET}_gui.a tools

tools: tools/bin/makebundle.exe

inform:
	@echo "Configuration "$(CFG)
	@echo "------------------------"
	
bin.$(CFG)/lib${TARGET}_snd.a: ${Group0_OBJ} | inform
	@$(ECHO) "Linking "$(TARGET)"..."
	@mkdir -p bin.$(CFG)
	@ar rcs $@ $^
	
bin.$(CFG)/lib${TARGET}_gfx.a: ${Group1_OBJ} | inform
	@$(ECHO) "Linking "$(TARGET)"..."
	@mkdir -p bin.$(CFG)
	@ar rcs $@ $^
	
bin.$(CFG)/lib${TARGET}_util.a: ${Group2_OBJ} | inform
	@$(ECHO) "Linking "$(TARGET)"..."
	@mkdir -p bin.$(CFG)
	@ar rcs $@ $^
	
bin.$(CFG)/lib${TARGET}_gui.a: ${Group3_OBJ} | inform
	@$(ECHO) "Linking "$(TARGET)"..."
	@mkdir -p bin.$(CFG)
	@ar rcs $@ $^
	
objs.$(CFG)/Group0_%.o: snd/%.c 
	@$(ECHO) "Compiling "$(notdir $<)"..."
	@mkdir -p objs.$(CFG)
	@$(CC) $(CFLAGS) -c $(CFLAGS) -o $@ $<

objs.$(CFG)/Group1_%.o: gfx/%.c 
	@$(ECHO) "Compiling "$(notdir $<)"..."
	@mkdir -p objs.$(CFG)
	@$(CC) $(CFLAGS) -c $(CFLAGS) -o $@ $<

objs.$(CFG)/Group2_%.o: util/%.c
	@$(ECHO) "Compiling "$(notdir $<)"..."
	@mkdir -p objs.$(CFG)
	@$(CC) $(CFLAGS) -c $(CFLAGS) -o $@ $<

objs.$(CFG)/Group3_%.o: gui/%.c
	@$(ECHO) "Compiling "$(notdir $<)"..."
	@mkdir -p objs.$(CFG)
	@$(CC) $(CFLAGS) -c $(CFLAGS) -o $@ $<

deps/Group0_$(CFG)_%.d: snd/%.c 
	@mkdir -p deps
	@$(ECHO) "Generating dependencies for $<"
	@set -e ; $(CDEP) -MM $(INCLUDEFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,objs.$(CFG)\/Group0_\1.o $@ : ,g' \
		< $@.$$$$ > $@; \
	rm -f $@.$$$$

deps/Group1_$(CFG)_%.d: gfx/%.c 
	@mkdir -p deps
	@$(ECHO) "Generating dependencies for $<"
	@set -e ; $(CDEP) -MM $(INCLUDEFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,objs.$(CFG)\/Group1_\1.o $@ : ,g' \
		< $@.$$$$ > $@; \
	rm -f $@.$$$$

deps/Group2_$(CFG)_%.d: util/%.c
	@mkdir -p deps
	@$(ECHO) "Generating dependencies for $<"
	@set -e ; $(CDEP) -MM $(INCLUDEFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,objs.$(CFG)\/Group2_\1.o $@ : ,g' \
		< $@.$$$$ > $@; \
	rm -f $@.$$$$

deps/Group3_$(CFG)_%.d: gui/%.c
	@mkdir -p deps
	@$(ECHO) "Generating dependencies for $<"
	@set -e ; $(CDEP) -MM $(INCLUDEFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,objs.$(CFG)\/Group3_\1.o $@ : ,g' \
		< $@.$$$$ > $@; \
	rm -f $@.$$$$
	
clean:
	@rm -rf deps objs.release objs.debug objs.profile bin.release bin.debug bin.profile

# Unless "make clean" is called, include the dependency files
# which are auto-generated. Don't fail if they are missing
# (-include), since they will be missing in the first 
# invocation!
ifneq ($(MAKECMDGOALS),clean)
-include ${Group0_DEP}
-include ${Group1_DEP}
-include ${Group2_DEP}
-include ${Group3_DEP}
endif

tools/bin/makebundle.exe: tools/makebundle/*.c
	make -C tools/makebundle 
