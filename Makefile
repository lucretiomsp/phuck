# Builds libphuck (.so / .dylib) = phuck.cpp + ChucK core objects + ChuckAudio/RtAudio.
# Usage:  make CHUCK=/path/to/chuck/src  [linux | mac]
# Step 1 builds ChucK core with -fPIC via its own makefile, step 2 links the shim.

CHUCK ?= ../chuck/src
CORE   = $(CHUCK)/core
HOST   = $(CHUCK)/host
INC    = -I$(CORE) -I$(CORE)/lo -I$(HOST) -I$(HOST)/RtAudio

UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
  TARGET  = mac
  DEFS    = -D__MACOSX_CORE__ -D__PLATFORM_APPLE__
  LIB     = libphuck.dylib
  LDEXTRA = -dynamiclib -install_name @rpath/libphuck.dylib \
            -framework CoreAudio -framework CoreMIDI -framework CoreFoundation \
            -framework IOKit -framework Carbon -framework AppKit -framework Foundation \
            -F/System/Library/PrivateFrameworks -weak_framework MultitouchSupport -lm
  CORE_CFLAGS = -fPIC
  CORE_ARGS   =
else
  # Linux: 'vanilla' core + bundled util_sndfile.c (like macOS), so no libsndfile
  # at build or run time. libstdc++/libgcc linked statically; only libasound,
  # libc, libm stay dynamic (present on every desktop Linux).
  TARGET  = vanilla
  DEFS    = -D__LINUX_ALSA__ -D__PLATFORM_LINUX__
  LIB     = libphuck.so
  LDEXTRA = -shared -static-libstdc++ -static-libgcc -lasound -lpthread -ldl -lm
  CORE_CFLAGS = -fPIC -D__LINUX_ALSA__ -fno-strict-aliasing
  CORE_ARGS   = SF_CSRCS=util_sndfile.c
endif

CXXFLAGS = -O2 -fPIC $(DEFS) $(INC)

all: $(LIB)

core:
	cd $(CORE) && CFLAGS="$(CORE_CFLAGS)" $(MAKE) $(TARGET) $(CORE_ARGS)

phuck.o: phuck.cpp phuck.h
	$(CXX) $(CXXFLAGS) -fvisibility=hidden -c phuck.cpp -o $@
chuck_audio.o: $(HOST)/chuck_audio.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@
RtAudio.o: $(HOST)/RtAudio/RtAudio.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(LIB): core phuck.o chuck_audio.o RtAudio.o
	$(CXX) -o $@ phuck.o chuck_audio.o RtAudio.o $(CORE)/*.o $(CORE)/lo/*.o $(LDEXTRA)

test: $(LIB) test.c
	$(CC) test.c -o test -L. -lphuck -Wl,-rpath,. && ./test

test_sine: $(LIB) test_sine.c
	$(CC) test_sine.c -o test_sine -L. -lphuck -Wl,-rpath,. -lm && ./test_sine

clean:
	rm -f *.o $(LIB) test test_sine
