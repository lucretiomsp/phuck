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
            -framework IOKit -framework Carbon -framework AppKit -framework Foundation
else
  TARGET  = linux-alsa
  DEFS    = -D__LINUX_ALSA__ -D__CK_SNDFILE_NATIVE__ -D__PLATFORM_LINUX__
  LIB     = libphuck.so
  LDEXTRA = -shared -lasound -lsndfile -lpthread -ldl -lm
endif

CXXFLAGS = -O2 -fPIC $(DEFS) $(INC)

all: $(LIB)

core:
	cd $(CORE) && CFLAGS="-fPIC" $(MAKE) $(TARGET)

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

clean:
	rm -f *.o $(LIB) test
