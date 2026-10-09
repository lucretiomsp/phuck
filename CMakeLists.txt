# libphuck: phuck.cpp + ChucK core + ChuckAudio/RtAudio, one shared library.
#   cmake -B build -DCHUCK_SRC=../chuck/src -DCMAKE_BUILD_TYPE=Release
#   cmake --build build --config Release
# Output: libphuck.so (Linux) / libphuck.dylib (macOS) / phuck.dll (Windows)

cmake_minimum_required(VERSION 3.16)

# must come before project(): project() caches its own (empty) value,
# and a later set(... CACHE ...) would silently be ignored
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.13" CACHE STRING "minimum macOS version")

project(phuck C CXX)

set(CHUCK_SRC "${CMAKE_CURRENT_SOURCE_DIR}/../chuck/src" CACHE PATH "path to chuck/src")
set(CORE "${CHUCK_SRC}/core")
set(HOST "${CHUCK_SRC}/host")

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")      # static CRT: nothing extra to ship

# same file list as chuck/src/core/makefile; chuck_yacc.c is the pre-generated
# parser shipped in the repo, so bison/flex are not needed
set(CORE_C chuck_yacc.c util_network.c util_raw.c util_xforms.c util_sndfile.c)
set(CORE_CXX
  chuck_absyn.cpp chuck_parse.cpp chuck_errmsg.cpp chuck_frame.cpp chuck_symbol.cpp
  chuck_table.cpp chuck_vm.cpp chuck_instr.cpp chuck_scan.cpp chuck_type.cpp
  chuck_emit.cpp chuck_compile.cpp chuck_dl.cpp chuck_oo.cpp chuck_lang.cpp
  chuck_ugen.cpp chuck_otf.cpp chuck_stats.cpp chuck_shell.cpp chuck_io.cpp chuck.cpp
  chuck_carrier.cpp chuck_globals.cpp midiio_rtmidi.cpp rtmidi.cpp hidio_sdl.cpp
  ugen_osc.cpp ugen_filter.cpp ugen_stk.cpp ugen_xxx.cpp ulib_ai.cpp ulib_doc.cpp
  ulib_machine.cpp ulib_math.cpp ulib_std.cpp ulib_opsc.cpp util_buffers.cpp
  util_console.cpp util_math.cpp util_platforms.cpp util_string.cpp util_thread.cpp
  util_opsc.cpp util_serial.cpp util_hid.cpp uana_xform.cpp uana_extract.cpp)
set(LO_C address.c blob.c bundle.c message.c method.c pattern_match.c send.c
  server.c timetag.c)
if(NOT WIN32)
  list(APPEND LO_C server_thread.c)                  # not built on Windows by ChucK either
endif()

list(TRANSFORM CORE_C   PREPEND "${CORE}/")
list(TRANSFORM CORE_CXX PREPEND "${CORE}/")
list(TRANSFORM LO_C     PREPEND "${CORE}/lo/")
set_source_files_properties(${LO_C} PROPERTIES COMPILE_DEFINITIONS HAVE_CONFIG_H)

add_library(phuck SHARED
  phuck.cpp
  ${CORE_C} ${CORE_CXX} ${LO_C}
  ${HOST}/chuck_audio.cpp
  ${HOST}/RtAudio/RtAudio.cpp)

target_include_directories(phuck PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR} ${CORE} ${CORE}/lo ${HOST} ${HOST}/RtAudio)
target_compile_definitions(phuck PRIVATE __USE_CHUCK_YACC__)   # use pre-generated parser header

if(APPLE)
  target_compile_definitions(phuck PRIVATE __MACOSX_CORE__)
  target_link_libraries(phuck PRIVATE
    "-framework CoreAudio" "-framework CoreMIDI" "-framework CoreFoundation"
    "-framework IOKit" "-framework Carbon" "-framework AppKit" "-framework Foundation")
  target_link_options(phuck PRIVATE
    -F/System/Library/PrivateFrameworks -weak_framework MultitouchSupport)
elseif(WIN32)
  target_compile_definitions(phuck PRIVATE
    __PLATFORM_WIN32__ __WINDOWS_DS__ WIN32 NOMINMAX _CRT_SECURE_NO_WARNINGS)
  target_link_libraries(phuck PRIVATE
    dsound winmm dinput8 dxguid ws2_32 wsock32 iphlpapi)
  set_target_properties(phuck PROPERTIES PREFIX "")    # phuck.dll, not libphuck.dll
else()
  # ALSA + PulseAudio: Pulse goes through the sound server (also PipeWire),
  # so the device isn't "busy" on desktop systems
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(PULSE REQUIRED IMPORTED_TARGET libpulse-simple libpulse)
  target_compile_definitions(phuck PRIVATE __LINUX_ALSA__ __LINUX_PULSE__ __PLATFORM_LINUX__)
  target_compile_options(phuck PRIVATE -fno-strict-aliasing)
  target_link_options(phuck PRIVATE -static-libstdc++ -static-libgcc)
  target_link_libraries(phuck PRIVATE asound PkgConfig::PULSE pthread dl m)
endif()

# optional C tests (not built by default)
option(PHUCK_TESTS "build C tests" OFF)
if(PHUCK_TESTS)
  add_executable(test_sine test_sine.c)
  target_link_libraries(test_sine PRIVATE phuck)
  if(NOT WIN32)
    target_link_libraries(test_sine PRIVATE m)
