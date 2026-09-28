/*  phuck.h : plain C API over libchuck, meant to be called from Pharo uFFI.
 *
 *  Rules of the API:
 *   - only C types cross the boundary (opaque pointer, int64, double, float*, const char*)
 *   - nothing ever calls back into Pharo: async ChucK results land in C-side
 *     slots/queues that Pharo polls. This keeps the audio thread away from the image.
 */
#ifndef PHUCK_H
#define PHUCK_H

#include <stdint.h>

#if defined(_WIN32)
  #define PHUCK_API __declspec(dllexport)
#else
  #define PHUCK_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct phuck phuck_t;            /* opaque: wraps ChucK* + shim state */
typedef struct phuck_req phuck_req_t;    /* opaque: pending async getter */

/* lifecycle */
PHUCK_API const char * phuck_version(void);
PHUCK_API phuck_t *    phuck_new(void);
PHUCK_API void         phuck_free(phuck_t * ck);

/* params: call before phuck_init (keys: "SAMPLE_RATE", "OUTPUT_CHANNELS", "VM_HALT", ...) */
PHUCK_API int     phuck_set_param_int(phuck_t * ck, const char * key, int64_t v);
PHUCK_API int     phuck_set_param_float(phuck_t * ck, const char * key, double v);
PHUCK_API int     phuck_set_param_string(phuck_t * ck, const char * key, const char * v);
PHUCK_API int64_t phuck_get_param_int(phuck_t * ck, const char * key);

PHUCK_API int     phuck_init(phuck_t * ck);
PHUCK_API int     phuck_start(phuck_t * ck);

/* code: return first new shred id, 0 on failure */
PHUCK_API int64_t phuck_compile_code(phuck_t * ck, const char * code, const char * args);
PHUCK_API int64_t phuck_compile_file(phuck_t * ck, const char * path, const char * args);
PHUCK_API int     phuck_remove_shred(phuck_t * ck, int64_t shredId);
PHUCK_API void    phuck_remove_all(phuck_t * ck);
PHUCK_API double  phuck_now(phuck_t * ck);           /* VM time in samples */
PHUCK_API int     phuck_sample_size(void);           /* 4 = float, 8 = double */

/* audio A: Pharo (or a test) drives the VM; buffers are interleaved SAMPLE */
PHUCK_API void    phuck_run(phuck_t * ck, const float * in, float * out, int64_t frames);

/* audio B: shim owns a realtime device (RtAudio) that calls ChucK::run */
PHUCK_API int     phuck_audio_start(phuck_t * ck, int bufferFrames);
PHUCK_API void    phuck_audio_stop(phuck_t * ck);

/* globals: setters are fire-and-forget (applied at next audio block) */
PHUCK_API int     phuck_set_int(phuck_t * ck, const char * name, int64_t v);
PHUCK_API int     phuck_set_float(phuck_t * ck, const char * name, double v);
PHUCK_API int     phuck_set_string(phuck_t * ck, const char * name, const char * v);
PHUCK_API int     phuck_set_float_array(phuck_t * ck, const char * name, const double * vals, int64_t n);
PHUCK_API int     phuck_signal_event(phuck_t * ck, const char * name);
PHUCK_API int     phuck_broadcast_event(phuck_t * ck, const char * name);

/* globals: getters are async in ChucK, so: request -> poll ready -> read -> free */
PHUCK_API phuck_req_t * phuck_request_int(phuck_t * ck, const char * name);
PHUCK_API phuck_req_t * phuck_request_float(phuck_t * ck, const char * name);
PHUCK_API int           phuck_req_ready(phuck_req_t * r);
PHUCK_API int64_t       phuck_req_int(phuck_req_t * r);
PHUCK_API double        phuck_req_float(phuck_req_t * r);
PHUCK_API void          phuck_req_free(phuck_req_t * r);

/* events ChucK -> Pharo: counter bumped on each broadcast, Pharo polls it */
PHUCK_API int     phuck_listen_event(phuck_t * ck, const char * name);
PHUCK_API int64_t phuck_event_count(phuck_t * ck, const char * name);

/* console: chout/cherr captured into a buffer; copies up to cap-1 bytes, returns length */
PHUCK_API int64_t phuck_read_output(phuck_t * ck, char * buf, int64_t cap);

#ifdef __cplusplus
}
#endif
#endif
