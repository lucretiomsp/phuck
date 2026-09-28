/* offline smoke test: drive the VM from C exactly as Pharo would via phuck_run */
#include "phuck.h"
#include <stdio.h>

int main(void)
{
    printf("chuck %s, sample bytes %d\n", phuck_version(), phuck_sample_size());
    phuck_t * ck = phuck_new();
    phuck_set_param_int(ck, "SAMPLE_RATE", 48000);
    phuck_set_param_int(ck, "INPUT_CHANNELS", 0);
    phuck_set_param_int(ck, "OUTPUT_CHANNELS", 2);
    phuck_set_param_int(ck, "VM_HALT", 0);
    phuck_init(ck);
    phuck_start(ck);

    int64_t id = phuck_compile_code(ck,
        "global float freq; global Event tick; 220 => freq;\n"
        "SinOsc s => dac; 0.2 => s.gain;\n"
        "<<< \"hello from chuck\" >>>;\n"
        "while(true){ freq => s.freq; tick.broadcast(); 10::ms => now; }", "");
    printf("shred id %lld\n", (long long)id);
    phuck_listen_event(ck, "tick");

    float in[1], out[256 * 2];
    double peak = 0;
    for (int b = 0; b < 200; b++) {                 /* ~1 s of audio */
        if (b == 50) phuck_set_float(ck, "freq", 440.0);
        phuck_run(ck, in, out, 256);
        for (int i = 0; i < 512; i++) if (out[i] > peak) peak = out[i];
    }
    phuck_req_t * r = phuck_request_float(ck, "freq");
    phuck_run(ck, in, out, 256);                    /* request is answered in the next block */
    printf("peak %.3f, freq ready %d = %.1f, tick count %lld\n",
           peak, phuck_req_ready(r), phuck_req_float(r), (long long)phuck_event_count(ck, "tick"));
    phuck_req_free(r);

    char buf[512];
    phuck_read_output(ck, buf, sizeof buf);
    printf("console: %s", buf);
    phuck_free(ck);
    return 0;
}
