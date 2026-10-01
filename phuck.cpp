// phuck.cpp : extern "C" shim over libchuck for Pharo uFFI.
// Modelled on src/host/chuck_main.cpp (ChucK + ChuckAudio + audio_cb -> run())
// and src/host-web/chuck_emscripten.cpp (extern "C" globals API).

#include "phuck.h"
#include "chuck.h"
#include "chuck_globals.h"
#include "chuck_vm.h"
#include "chuck_audio.h"   // src/host/chuck_audio.h (RtAudio wrapper used by the chuck CLI)

#include <algorithm>
#include <atomic>
#include <map>
#include <mutex>
#include <string>
#include <vector>
#include <cstring>

struct phuck
{
    ChucK * chuck = nullptr;
    std::mutex outLock;
    std::string out;                                  // captured chout + cherr
    std::mutex evLock;
    std::map<std::string, std::atomic<int64_t> *> events;
    bool audioOn = false;
};

struct phuck_req
{
    std::atomic<int> ready { 0 };
    int64_t i = 0;
    double f = 0.0;
};

// ChucK's chout/cherr callbacks carry no user data, so route them through a
// registry. One VM is the normal case; last created instance receives output.
static std::atomic<phuck_t *> g_console { nullptr };
static void on_text( const char * s )
{
    phuck_t * ck = g_console.load();
    if( !ck || !s ) return;
    std::lock_guard<std::mutex> g( ck->outLock );
    if( ck->out.size() < (1u << 20) ) ck->out += s;  // cap at 1 MB if Pharo never drains
}

// ChuckAudio is a static singleton (one realtime stream per process).
// Track which VM owns it, so a forgotten VM can never lock the device.
static phuck_t * g_audio_owner = nullptr;

extern "C" {

// ---- lifecycle --------------------------------------------------------------
const char * phuck_version(void) { return ChucK::version(); }
int phuck_sample_size(void) { return (int)sizeof(SAMPLE); }

phuck_t * phuck_new(void)
{
    phuck_t * ck = new phuck;
    ck->chuck = new ChucK();
    g_console.store( ck );
    return ck;
}

void phuck_free( phuck_t * ck )
{
    if( !ck ) return;
    phuck_audio_stop( ck );                        // no-op unless ck owns the device
    if( g_console.load() == ck ) g_console.store( nullptr );
    delete ck->chuck;
    for( auto & kv : ck->events ) delete kv.second;
    delete ck;
}

int phuck_set_param_int( phuck_t * ck, const char * k, int64_t v ) { return ck->chuck->setParam( k, (t_CKINT)v ); }
int phuck_set_param_float( phuck_t * ck, const char * k, double v ) { return ck->chuck->setParamFloat( k, v ); }
int phuck_set_param_string( phuck_t * ck, const char * k, const char * v ) { return ck->chuck->setParam( k, std::string( v ) ); }
int64_t phuck_get_param_int( phuck_t * ck, const char * k ) { return ck->chuck->getParamInt( k ); }

int phuck_init( phuck_t * ck )
{
    if( !ck->chuck->init() ) return 0;
    // console callbacks must be set after init()
    ck->chuck->setChoutCallback( on_text );
    ck->chuck->setCherrCallback( on_text );
    return 1;
}

int phuck_start( phuck_t * ck ) { return ck->chuck->start(); }

// ---- code -------------------------------------------------------------------
int64_t phuck_compile_code( phuck_t * ck, const char * code, const char * args )
{
    std::vector<t_CKUINT> ids;
    if( !ck->chuck->compileCode( code, args ? args : "", 1, FALSE, &ids ) || ids.empty() ) return 0;
    return (int64_t)ids[0];
}

int64_t phuck_compile_file( phuck_t * ck, const char * path, const char * args )
{
    std::vector<t_CKUINT> ids;
    if( !ck->chuck->compileFile( path, args ? args : "", 1, FALSE, &ids ) || ids.empty() ) return 0;
    return (int64_t)ids[0];
}

int phuck_remove_shred( phuck_t * ck, int64_t id )
{
    // same as host-web: queue a VM message, applied on the audio thread
    Chuck_Msg * msg = new Chuck_Msg;
    msg->type = CK_MSG_REMOVE;
    msg->param = (t_CKUINT)id;
    msg->reply_queue = FALSE;
    return ck->chuck->globals()->execute_chuck_msg_with_globals( msg );
}

void phuck_remove_all( phuck_t * ck ) { ck->chuck->removeAllShreds(); }
double phuck_now( phuck_t * ck ) { return (double)ck->chuck->now(); }

// ---- offline audio: Pharo (or a test) drives the VM -------------------------
void phuck_run( phuck_t * ck, const float * in, float * out, int64_t frames )
{
    // assumes default build (SAMPLE == float); check phuck_sample_size() from Pharo
    ck->chuck->run( (const SAMPLE *)in, (SAMPLE *)out, (t_CKINT)frames );
}

// ---- realtime audio: same pattern as chuck_main.cpp audio_cb ----------------
static void audio_cb( SAMPLE * in, SAMPLE * out, t_CKUINT n, t_CKUINT, t_CKUINT, void * data )
{
    ((ChucK *)data)->run( in, out, n );
}

int phuck_audio_start( phuck_t * ck, int bufferFrames )
{
    if( !ck ) return 0;
    if( g_audio_owner == ck ) return 1;
    if( g_audio_owner ) phuck_audio_stop( g_audio_owner );   // take over from a forgotten VM
    ChucK * c = ck->chuck;
    if( !ChuckAudio::initialize( 0, 0,                         // default dac/adc
                                 c->getParamInt( CHUCK_PARAM_OUTPUT_CHANNELS ),
                                 c->getParamInt( CHUCK_PARAM_INPUT_CHANNELS ),
                                 c->getParamInt( CHUCK_PARAM_SAMPLE_RATE ),
                                 bufferFrames > 0 ? bufferFrames : 256, 8,
                                 audio_cb, (void *)c, FALSE, NULL ) )
        return 0;
    if( !ChuckAudio::start() ) { ChuckAudio::shutdown(); return 0; }   // never leave it half-open
    ck->audioOn = true;
    g_audio_owner = ck;
    return 1;
}

void phuck_audio_stop( phuck_t * ck )
{
    if( !ck || g_audio_owner != ck ) return;
    ChuckAudio::shutdown();      // stopStream + closeStream, resets ChuckAudio::m_init
    ck->audioOn = false;
    g_audio_owner = nullptr;
}

// ---- globals: set -----------------------------------------------------------
int phuck_set_int( phuck_t * ck, const char * n, int64_t v ) { return ck->chuck->globals()->setGlobalInt( n, (t_CKINT)v ); }
int phuck_set_float( phuck_t * ck, const char * n, double v ) { return ck->chuck->globals()->setGlobalFloat( n, v ); }
int phuck_set_string( phuck_t * ck, const char * n, const char * v ) { return ck->chuck->globals()->setGlobalString( n, v ); }
int phuck_set_float_array( phuck_t * ck, const char * n, const double * v, int64_t len )
{
    return ck->chuck->globals()->setGlobalFloatArray( n, (t_CKFLOAT *)v, (t_CKUINT)len );
}
int phuck_signal_event( phuck_t * ck, const char * n ) { return ck->chuck->globals()->signalGlobalEvent( n ); }
int phuck_broadcast_event( phuck_t * ck, const char * n ) { return ck->chuck->globals()->broadcastGlobalEvent( n ); }

// ---- globals: get (async). The request pointer itself is the callbackID. ----
static void got_int( t_CKINT id, t_CKINT v ) { auto r = (phuck_req_t *)id; r->i = v; r->ready = 1; }
static void got_float( t_CKINT id, t_CKFLOAT v ) { auto r = (phuck_req_t *)id; r->f = v; r->ready = 1; }

phuck_req_t * phuck_request_int( phuck_t * ck, const char * n )
{
    auto r = new phuck_req;
    if( !ck->chuck->globals()->getGlobalInt( n, (t_CKINT)r, got_int ) ) { delete r; return nullptr; }
    return r;
}
phuck_req_t * phuck_request_float( phuck_t * ck, const char * n )
{
    auto r = new phuck_req;
    if( !ck->chuck->globals()->getGlobalFloat( n, (t_CKINT)r, got_float ) ) { delete r; return nullptr; }
    return r;
}
int phuck_req_ready( phuck_req_t * r ) { return r ? r->ready.load() : 0; }
int64_t phuck_req_int( phuck_req_t * r ) { return r->i; }
double phuck_req_float( phuck_req_t * r ) { return r->f; }
void phuck_req_free( phuck_req_t * r ) { delete r; }   // only after ready, or the VM writes freed memory

// ---- events ChucK -> Pharo --------------------------------------------------
static void on_event( t_CKINT id ) { ((std::atomic<int64_t> *)id)->fetch_add( 1 ); }

int phuck_listen_event( phuck_t * ck, const char * n )
{
    std::lock_guard<std::mutex> g( ck->evLock );
    auto & slot = ck->events[n];
    if( slot ) return 1;
    slot = new std::atomic<int64_t>( 0 );
    return ck->chuck->globals()->listenForGlobalEvent( n, (t_CKINT)slot, on_event, TRUE );
}

int64_t phuck_event_count( phuck_t * ck, const char * n )
{
    std::lock_guard<std::mutex> g( ck->evLock );
    auto it = ck->events.find( n );
    return it == ck->events.end() ? -1 : it->second->load();
}

// ---- console ----------------------------------------------------------------
int64_t phuck_read_output( phuck_t * ck, char * buf, int64_t cap )
{
    std::lock_guard<std::mutex> g( ck->outLock );
    if( cap <= 0 ) return (int64_t)ck->out.size();
    size_t n = std::min( (size_t)(cap - 1), ck->out.size() );
    memcpy( buf, ck->out.data(), n );
    buf[n] = 0;
    ck->out.erase( 0, n );
    return (int64_t)n;
}

} // extern "C"
