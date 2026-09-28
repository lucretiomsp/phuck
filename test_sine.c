/* test_sine.c : SinOsc in ChucK, frequency driven from C through a global.
 *
 *   ./test_sine           offline: renders blocks with phuck_run and measures the pitch
 *   ./test_sine --audio   realtime: plays through the default device, steps the freq
 *
 * Build: cc test_sine.c -o test_sine -L. -lphuck -Wl,-rpath,. -lm
 */
#include "phuck.h"
#include <math.h>
#include <stdio.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#define sleep(s)   Sleep((s) * 1000)
#define usleep(us) Sleep((us) / 1000)
#else
#include <unistd.h>
#endif

#define SR     48000
#define CHANS  2
#define BLOCK  256

static const char * CODE =
    "global float freq;\n"
    "440 => freq;\n"
    "SinOsc s => dac;\n"
    "0.3 => s.gain;\n"
    "while( true ) { freq => s.freq; 1::samp => now; }\n";

/* estimate pitch by counting upward zero crossings on the left channel */
static double measure_hz(phuck_t * ck, int blocks)
{
    float in[1], out[BLOCK * CHANS];
    float prev = 0.0f;
    long crossings = 0;
    for (int b = 0; b < blocks; b++) {
        phuck_run(ck, in, out, BLOCK);
        for (int i = 0; i < BLOCK; i++) {
            float x = out[i * CHANS];
            if (prev <= 0.0f && x > 0.0f) crossings++;
            prev = x;
        }
    }
    return crossings * (double)SR / (blocks * BLOCK);
}

static void render(phuck_t * ck, int blocks)   /* let a setter land / settle */
{
    float in[1], out[BLOCK * CHANS];
    for (int b = 0; b < blocks; b++) phuck_run(ck, in, out, BLOCK);
}

static phuck_t * make_vm(void)
{
    phuck_t * ck = phuck_new();
    phuck_set_param_int(ck, "SAMPLE_RATE", SR);
    phuck_set_param_int(ck, "INPUT_CHANNELS", 0);
    phuck_set_param_int(ck, "OUTPUT_CHANNELS", CHANS);
    phuck_set_param_int(ck, "VM_HALT", 0);
    if (!phuck_init(ck) || !phuck_start(ck)) { fprintf(stderr, "init failed\n"); return NULL; }
    if (phuck_compile_code(ck, CODE, "") == 0) { fprintf(stderr, "compile failed\n"); return NULL; }
    return ck;
}

static int offline(void)
{
    const double targets[] = { 440.0, 220.0, 880.0, 330.0 };
    phuck_t * ck = make_vm();
    if (!ck) return 1;
    int fails = 0;

    for (int t = 0; t < 4; t++) {
        phuck_set_float(ck, "freq", targets[t]);
        render(ck, 4);                              /* setter is applied at the next block */
        double hz = measure_hz(ck, SR / BLOCK);     /* ~1 s window */
        int ok = fabs(hz - targets[t]) < 2.0;
        printf("set %6.1f Hz  measured %6.1f Hz  %s\n", targets[t], hz, ok ? "OK" : "FAIL");
        fails += !ok;
    }

    /* read the global back through the async getter */
    phuck_req_t * r = phuck_request_float(ck, "freq");
    render(ck, 1);
    int ok = r && phuck_req_ready(r) && phuck_req_float(r) == 330.0;
    printf("get freq -> %.1f  %s\n", r ? phuck_req_float(r) : -1.0, ok ? "OK" : "FAIL");
    fails += !ok;
    phuck_req_free(r);

    phuck_free(ck);
    printf("%s\n", fails ? "FAILED" : "ALL PASSED");
    return fails != 0;
}

static int realtime(void)
{
    const double steps[] = { 220.0, 330.0, 440.0, 550.0, 660.0, 440.0 };
    phuck_t * ck = make_vm();
    if (!ck) return 1;
    if (!phuck_audio_start(ck, BLOCK)) { fprintf(stderr, "no audio device\n"); phuck_free(ck); return 1; }

    for (int i = 0; i < 6; i++) {
        printf("freq %.0f Hz\n", steps[i]);
        fflush(stdout);
        phuck_set_float(ck, "freq", steps[i]);
        sleep(1);
    }
    /* glide down, 20 updates per second */
    for (int i = 0; i <= 40; i++) {
        phuck_set_float(ck, "freq", 880.0 * pow(0.5, i / 20.0));
        usleep(50000);
    }

    phuck_audio_stop(ck);
    phuck_free(ck);
    return 0;
}

int main(int argc, char ** argv)
{
    printf("ChucK %s\n", phuck_version());
    if (argc > 1 && strcmp(argv[1], "--audio") == 0) return realtime();
    return offline();
}
