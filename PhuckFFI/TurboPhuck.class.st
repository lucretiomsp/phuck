"
I am TurboPhuck, I am a Performance connected to a ChuckVM and a shred full of cool instruments
"
Class {
	#name : 'TurboPhuck',
	#superclass : 'Object',
	#instVars : [
		'tpPerf'
	],
	#classInstVars : [
		'tpPerf',
		'tpVm'
	],
	#category : 'PhuckFFI-Core',
	#package : 'PhuckFFI',
	#tag : 'Core'
}

{ #category : 'defaults' }
TurboPhuck class >> code [

	| turbo |
	turbo := (FileLocator imageDirectory / 'TurboSamples') asFileReference asChuckPath.
	^ '// ===================== MASTER =====================

Gain master => Dyno lim => dac;
0.8 => master.gain;
lim.limit();

// ===================== CLASSES =====================

class AcidCubic extends Chugen
{
    fun float tick(float in)
    {
        Math.max(-1.0, Math.min(1.0, in)) => float x;
        return x - (x * x * x) / 3.0;
    }
}

class Kick99Clip extends Chugen
{
    fun float tick(float in)
    {
        Math.max(-1.0, Math.min(1.0, in)) => float x;
        return 1.5 * (x - (x * x * x) / 3.0);
    }
}

class ZdSampler extends Chugraph
{
    SndBuf buf => ADSR env => Gain out => outlet;

    60 => int rootNote;
    1  => int retrigOnNote;
    string dirPath;
    string files[0];
    0  => int curIndex;
    60 => int curNote;
    0  => int curGate;

    env.set(1::ms, 380::ms, 1.0, 120::ms);
    0.4 => buf.gain;
    1.0 => buf.rate;
    buf.samples() => buf.pos;

    fun ZdSampler() { }
    fun ZdSampler(string folder) { load(folder); }

    fun int load(string folder)
    {
        folder => dirPath;
        if (dirPath.length() > 0 && dirPath.charAt(dirPath.length() - 1) != 47)
            "/" +=> dirPath;
        FileIO dir;
        if (!dir.open(folder, FileIO.READ) || !dir.isDir())
        {
            cherr <= "[ZdSampler] cannot open folder: " <= folder <= IO.nl();
            string none[0] @=> files;
            return 0;
        }
        sortAlpha(filterAudio(dir.dirList())) @=> files;
        dir.close();
        if (files.size() == 0)
        {
            cherr <= "[ZdSampler] no audio files in: " <= folder <= IO.nl();
            return 0;
        }
        loadIndex(0);
        return files.size();
    }

    fun void gate(int g)
    {
        (g != 0) => int on;
        if (on == curGate) return;
        on => curGate;
        if (on) trigger();
        else    env.keyOff();
    }

    fun void note(int n)
    {
        if (n == curNote) return;
        n => curNote;
        updateRate();
        if (curGate && retrigOnNote) trigger();
    }

    fun void index(int i)
    {
        if (files.size() == 0) return;
        wrap(i) => int w;
        if (w == curIndex) return;
        loadIndex(w);
    }

    fun void update(int n, int g, int i)
    {
        index(i);
        note(n);
        gate(g);
    }

    fun void setADSR(dur a, dur d, float s, dur r) { env.set(a, d, s, r); }
    fun void setRootNote(int n)       { n => rootNote; updateRate(); }
    fun void setRetrigOnNote(int on)  { on => retrigOnNote; }
    fun void setLevel(float g)        { g => buf.gain; }
    fun int    numSamples()  { return files.size(); }
    fun string sampleName()  { return files.size() ? files[curIndex] : ""; }

    fun void list()
    {
        chout <= "[ZdSampler] " <= dirPath <= " (" <= files.size()
              <= " samples)" <= IO.nl();
        for (0 => int i; i < files.size(); i++)
            chout <= (i == curIndex ? " > " : "   ") <= i <= ": " <= files[i] <= IO.nl();
    }

    fun void trigger()
    {
        if (files.size() == 0) return;
        updateRate();
        0 => buf.pos;
        env.keyOn();
    }

    fun void updateRate()
    {
        Math.pow(2.0, (curNote - rootNote) / 12.0) => buf.rate;
    }

    fun int wrap(int i)
    {
        return ((i % files.size()) + files.size()) % files.size();
    }

    fun void loadIndex(int i)
    {
        i => curIndex;
        dirPath + files[curIndex] => buf.read;
        if (curGate) 0 => buf.pos;
        else buf.samples() => buf.pos;
    }

    fun static string[] filterAudio(string names[])
    {
        ["wav", "aif", "aiff", "flac", "ogg", "raw", "snd"] @=> string exts[];
        string keep[0];
        for (0 => int i; i < names.size(); i++)
        {
            names[i] => string name;
            if (name.length() == 0 || name.charAt(0) == 46) continue;
            name.rfind(".") => int dot;
            if (dot < 0) continue;
            name.substring(dot + 1).lower() => string ext;
            for (0 => int j; j < exts.size(); j++)
            {
                if (ext == exts[j]) { keep << name; break; }
            }
        }
        return keep;
    }

    fun static string[] sortAlpha(string input[])
    {
        string output[input.size()];
        for (0 => int i; i < input.size(); i++)
        {
            input[i] => string item;
            i - 1 => int j;
            while (j >= 0 && output[j].lower() > item.lower())
            {
                output[j] => output[j + 1];
                j--;
            }
            item => output[j + 1];
        }
        return output;
    }
}

class Hoover extends Chugraph
{
    SawOsc s1 => Gain mix => ADSR ampEnv => Gain out => outlet;
    SawOsc s2 => mix;
    SawOsc s3 => mix;
    TriOsc t1 => mix;
    0.3 => s2.gain;  0.3 => s3.gain;  0.3 => t1.gain;
    ampEnv.set(1::ms, 200::ms, 0.5, 350::ms);

    // pitch envelope as FM input, no polling
    Step one => ADSR pitchEnv;
    pitchEnv => Gain fm1 => s1;
    pitchEnv => Gain fm2 => s2;
    pitchEnv => Gain fm3 => s3;
    pitchEnv => Gain fm4 => t1;
    2 => s1.sync;  2 => s2.sync;  2 => s3.sync;  2 => t1.sync;
    126.0 => fm1.gain;  126.0 => fm2.gain;  252.0 => fm3.gain;  63.0 => fm4.gain;
    1.0 => one.next;
    pitchEnv.set(1::ms, 1::second, 0.0, 600::ms);

    0 => float lastGate;

    fun void trigger(float note, float gate, float level)
    {
        Std.mtof(note) => float f;
        f         => s1.freq;
        f + 3     => s2.freq;
        f * 2 + 3 => s3.freq;
        f * 0.5   => t1.freq;
        level => out.gain;
        if (gate == lastGate) return;
        if (gate > 0) { ampEnv.keyOn();  pitchEnv.keyOn(); }
        else          { ampEnv.keyOff(); pitchEnv.keyOff(); }
        gate => lastGate;
    }
}

class Acid extends Chugraph
{
    SawOsc saw => Gain osc => ADSR ampEnv => LPF filt => Gain comp => AcidCubic dist => Gain out => outlet;
    SqrOsc sqr => osc;
    Step one => ADSR filterEnv => blackhole;

    ampEnv.set(1::ms, 200::ms, 0.0, 200::ms);
    1.0 => one.next;
    0 => float lastGate;
    0 => int gen;
    0.3 => float cutoff;
    0.64 => float envMod;

    fun void trigger(float note, float gate, float level, float cut, float res,
                     float mod, float decay, float tuning, float waveform)
    {
        Std.mtof(note) + tuning => float f;
        f => saw.freq;
        f => sqr.freq;
        if (waveform > 0.5) { 0.0 => saw.gain; 0.25 => sqr.gain; }
        else                { 0.25 => saw.gain; 0.0 => sqr.gain; }
        cut => cutoff;
        mod => envMod;
        res => filt.Q;
        1.0 / (0.5 + cut) => comp.gain;
        level => out.gain;
        setCutoff();

        if (gate == lastGate) return;
        if (gate > 0)
        {
            filterEnv.set(1::ms, decay::second, 0.0, decay::second);
            ampEnv.keyOn();
            filterEnv.keyOn();
            gen++;
            spork ~ sweep(gen, decay::second + 5::ms);
        }
        else ampEnv.keyOff();
        gate => lastGate;
    }

    fun void setCutoff()
    {
        Math.min(1.0, filterEnv.last() * (1.0 - cutoff) * envMod + cutoff) => float n;
        Math.min(18000.0, 2.0 * Math.pow(10.0, 3.0 * n + 1.0)) => filt.freq;
    }

    // runs only while the filter envelope moves, stops on retrigger
    fun void sweep(int id, dur length)
    {
        now + length => time end;
        while (id == gen && now < end)
        {
            setCutoff();
            1::ms => now;
        }
        if (id == gen) setCutoff();
    }
}

class Reese extends Chugraph
{
    SinOsc o1 => Gain mix => ADSR env => Gain out => outlet;
    SinOsc o2 => mix;
    0.3 => o1.gain;  0.3 => o2.gain;
    0 => float lastGate;

    fun void trigger(float note, float gate, float level, float detune,
                     float a, float d, float s, float r)
    {
        Std.mtof(note) => float f;
        f => o1.freq;
        f + detune => o2.freq;
        level => out.gain;
        if (gate == lastGate) return;
        if (gate > 0)
        {
            env.set(a::second, d::second, s, r::second);
            env.keyOn();
        }
        else env.keyOff();
        gate => lastGate;
    }
}

class Kick99 extends Chugraph
{
    // pitch env: Impulse into OnePole = exponential decay, FM into body
    Impulse pImp => OnePole pEnv => Gain pAmt => SinOsc body;
    2 => body.sync;

    // amp env: Impulse into OnePole, multiplied with body
    body => Gain vca => Kick99Clip clip => Gain out => outlet;
    Impulse aImp => OnePole aEnv => vca;
    3 => vca.op;

    Noise noise => HPF clickHp => ADSR clickEnv => Gain clickAmp => out;
    3000 => clickHp.freq;
    clickEnv.set(0.5::ms, 6::ms, 0.0, 1::ms);

    1.0 => pEnv.b0;  1.0 => aEnv.b0;
    0.0 => pEnv.a1;  0.0 => aEnv.a1;
    second / samp => float sr;
    0 => float lastGate;

    fun void trigger(float note, float gate, float level, float decay,
                     float pitchAmt, float pitchDecay, float click)
    {
        Std.mtof(note) => body.freq;
        pitchAmt => pAmt.gain;
        click    => clickAmp.gain;
        level    => out.gain;
        if (gate == lastGate) return;
        gate => lastGate;
        if (gate <= 0) return;

        // a1 = 0 for one sample resets both envelopes to the impulse value
        0.0 => pEnv.a1;  0.0 => aEnv.a1;
        0.0 => body.phase;
        1.0 => pImp.next;
        1.5 => aImp.next;
        clickEnv.keyOn();
        1::samp => now;
        -Math.exp(-1.0 / (pitchDecay * sr)) => pEnv.a1;
        -Math.exp(-1.0 / (decay * sr))      => aEnv.a1;
    }
}

// ===================== STK =====================

0 => global float bellGate;      60 => global float bellNote;      global Event bellTrig;
0 => global float brassGate;     60 => global float brassNote;     global Event brassTrig;
0 => global float blowGate;      60 => global float blowNote;      global Event blowTrig;
0 => global float clarinetGate;  60 => global float clarinetNote;  global Event clarinetTrig;
0 => global float moogGate;      60 => global float moogNote;      global Event moogTrig;
0 => global float stkShakerGate; 60 => global float stkShakerNote; global Event stkShakerTrig;
0 => global float barGate;       60 => global float barNote;       global Event barTrig;
0 => global float flutGate;      60 => global float flutNote;      global Event flutTrig;
0 => global float rhodeyGate;    60 => global float rhodeyNote;    global Event rhodeyTrig;
0 => global float mandolinGate;  60 => global float mandolinNote;  global Event mandolinTrig;
0 => global float beeThreeGate;  60 => global float beeThreeNote;  global Event beeThreeTrig;
0 => global float sitarGate;     60 => global float sitarNote;     global Event sitarTrig;

Gain stkMaster => master;
0.3 => stkMaster.gain;

TubeBell bell      => Gain bellAmp      => stkMaster;
Brass brass        => Gain brassAmp     => stkMaster;
BlowBotl blow      => Gain blowAmp      => stkMaster;
Clarinet clarinet  => Gain clarinetAmp  => stkMaster;
Moog moog          => Gain moogAmp      => stkMaster;
Shakers stkShaker  => Gain stkShakerAmp => stkMaster;
ModalBar bar       => Gain barAmp       => stkMaster;
PercFlut flut      => Gain flutAmp      => stkMaster;
Rhodey rhodey      => Gain rhodeyAmp    => stkMaster;
Mandolin mandolin  => Gain mandolinAmp  => stkMaster;
BeeThree b3        => Gain b3Amp        => stkMaster;
Sitar sitar        => Gain sitarAmp     => stkMaster;

[bellAmp, brassAmp, blowAmp, clarinetAmp, moogAmp, stkShakerAmp,
 barAmp, flutAmp, rhodeyAmp, mandolinAmp, b3Amp, sitarAmp] @=> Gain stkAmps[];
for (0 => int i; i < stkAmps.size(); i++) 0.5 => stkAmps[i].gain;

// sets pitch, gates only on change, returns the new gate state
fun float stkSet(StkInstrument inst, float note, float gate, float last)
{
    Std.mtof(note) => inst.freq;
    if (gate != last)
    {
        if (gate > 0) gate => inst.noteOn;
        else 1 => inst.noteOff;
    }
    return gate;
}

fun void bellVoice(StkInstrument i)      { 0.0 => float l; while (true) { bellTrig => now;      stkSet(i, bellNote, bellGate, l) => l; } }
fun void brassVoice(StkInstrument i)     { 0.0 => float l; while (true) { brassTrig => now;     stkSet(i, brassNote, brassGate, l) => l; } }
fun void blowVoice(StkInstrument i)      { 0.0 => float l; while (true) { blowTrig => now;      stkSet(i, blowNote, blowGate, l) => l; } }
fun void clarinetVoice(StkInstrument i)  { 0.0 => float l; while (true) { clarinetTrig => now;  stkSet(i, clarinetNote, clarinetGate, l) => l; } }
fun void moogVoice(StkInstrument i)      { 0.0 => float l; while (true) { moogTrig => now;      stkSet(i, moogNote, moogGate, l) => l; } }
fun void stkShakerVoice(StkInstrument i) { 0.0 => float l; while (true) { stkShakerTrig => now; stkSet(i, stkShakerNote, stkShakerGate, l) => l; } }
fun void barVoice(StkInstrument i)       { 0.0 => float l; while (true) { barTrig => now;       stkSet(i, barNote, barGate, l) => l; } }
fun void flutVoice(StkInstrument i)      { 0.0 => float l; while (true) { flutTrig => now;      stkSet(i, flutNote, flutGate, l) => l; } }
fun void rhodeyVoice(StkInstrument i)    { 0.0 => float l; while (true) { rhodeyTrig => now;    stkSet(i, rhodeyNote, rhodeyGate, l) => l; } }
fun void mandolinVoice(StkInstrument i)  { 0.0 => float l; while (true) { mandolinTrig => now;  stkSet(i, mandolinNote, mandolinGate, l) => l; } }
fun void beeThreeVoice(StkInstrument i)  { 0.0 => float l; while (true) { beeThreeTrig => now;  stkSet(i, beeThreeNote, beeThreeGate, l) => l; } }
fun void sitarVoice(StkInstrument i)     { 0.0 => float l; while (true) { sitarTrig => now;     stkSet(i, sitarNote, sitarGate, l) => l; } }

spork ~ bellVoice(bell);
spork ~ brassVoice(brass);
spork ~ blowVoice(blow);
spork ~ clarinetVoice(clarinet);
spork ~ moogVoice(moog);
spork ~ stkShakerVoice(stkShaker);
spork ~ barVoice(bar);
spork ~ flutVoice(flut);
spork ~ rhodeyVoice(rhodey);
spork ~ mandolinVoice(mandolin);
spork ~ beeThreeVoice(b3);
spork ~ sitarVoice(sitar);

// ===================== ZDSAMPLER =====================

60 => global int bleepNote;      global int bleepGate;      global int bleepIndex;      global Event bleepTrig;
60 => global int blipNote;       global int blipGate;       global int blipIndex;       global Event blipTrig;
60 => global int bongoNote;      global int bongoGate;      global int bongoIndex;      global Event bongoTrig;
60 => global int chNote;         global int chGate;         global int chIndex;         global Event chTrig;
60 => global int clapNote;       global int clapGate;       global int clapIndex;       global Event clapTrig;
60 => global int claveNote;      global int claveGate;      global int claveIndex;      global Event claveTrig;
60 => global int congaNote;      global int congaGate;      global int congaIndex;      global Event congaTrig;
60 => global int cowbellNote;    global int cowbellGate;    global int cowbellIndex;    global Event cowbellTrig;
60 => global int crashNote;      global int crashGate;      global int crashIndex;      global Event crashTrig;
60 => global int fx2Note;        global int fx2Gate;        global int fx2Index;        global Event fx2Trig;
60 => global int kickNote;       global int kickGate;       global int kickIndex;       global Event kickTrig;
60 => global int ohNote;         global int ohGate;         global int ohIndex;         global Event ohTrig;
60 => global int ravekickNote;   global int ravekickGate;   global int ravekickIndex;   global Event ravekickTrig;
60 => global int rideNote;       global int rideGate;       global int rideIndex;       global Event rideTrig;
60 => global int rimNote;        global int rimGate;        global int rimIndex;        global Event rimTrig;
60 => global int shakerNote;     global int shakerGate;     global int shakerIndex;     global Event shakerTrig;
60 => global int snareNote;      global int snareGate;      global int snareIndex;      global Event snareTrig;
60 => global int speakspellNote; global int speakspellGate; global int speakspellIndex; global Event speakspellTrig;
60 => global int tambNote;       global int tambGate;       global int tambIndex;       global Event tambTrig;
60 => global int timbNote;       global int timbGate;       global int timbIndex;       global Event timbTrig;
60 => global int tomNote;        global int tomGate;        global int tomIndex;        global Event tomTrig;

"TURBO_ROOT" => string turbo;
ZdSampler bleep(turbo + "/bleep")           => master;
ZdSampler blip(turbo + "/blip")             => master;
ZdSampler bongo(turbo + "/bongo")           => master;
ZdSampler ch(turbo + "/ch")                 => master;
ZdSampler clap(turbo + "/clap")             => master;
ZdSampler clave(turbo + "/clave")           => master;
ZdSampler conga(turbo + "/conga")           => master;
ZdSampler cowbell(turbo + "/cowbell")       => master;
ZdSampler crash(turbo + "/crash")           => master;
ZdSampler fx2(turbo + "/fx2")               => master;
ZdSampler kick(turbo + "/kick")             => master;
ZdSampler oh(turbo + "/oh")                 => master;
ZdSampler ravekick(turbo + "/ravekick")     => master;
ZdSampler ride(turbo + "/ride")             => master;
ZdSampler rim(turbo + "/rim")               => master;
ZdSampler shaker(turbo + "/shaker")         => master;
ZdSampler snare(turbo + "/snare")           => master;
ZdSampler speakspell(turbo + "/speakspell") => master;
ZdSampler tamb(turbo + "/tamb")             => master;
ZdSampler timb(turbo + "/timb")             => master;
ZdSampler tom(turbo + "/tom")               => master;

fun void bleepVoice(ZdSampler s)      { while (true) { bleepTrig => now;      s.update(bleepNote, bleepGate, bleepIndex); } }
fun void blipVoice(ZdSampler s)       { while (true) { blipTrig => now;       s.update(blipNote, blipGate, blipIndex); } }
fun void bongoVoice(ZdSampler s)      { while (true) { bongoTrig => now;      s.update(bongoNote, bongoGate, bongoIndex); } }
fun void chVoice(ZdSampler s)         { while (true) { chTrig => now;         s.update(chNote, chGate, chIndex); } }
fun void clapVoice(ZdSampler s)       { while (true) { clapTrig => now;       s.update(clapNote, clapGate, clapIndex); } }
fun void claveVoice(ZdSampler s)      { while (true) { claveTrig => now;      s.update(claveNote, claveGate, claveIndex); } }
fun void congaVoice(ZdSampler s)      { while (true) { congaTrig => now;      s.update(congaNote, congaGate, congaIndex); } }
fun void cowbellVoice(ZdSampler s)    { while (true) { cowbellTrig => now;    s.update(cowbellNote, cowbellGate, cowbellIndex); } }
fun void crashVoice(ZdSampler s)      { while (true) { crashTrig => now;      s.update(crashNote, crashGate, crashIndex); } }
fun void fx2Voice(ZdSampler s)        { while (true) { fx2Trig => now;        s.update(fx2Note, fx2Gate, fx2Index); } }
fun void kickVoice(ZdSampler s)       { while (true) { kickTrig => now;       s.update(kickNote, kickGate, kickIndex); } }
fun void ohVoice(ZdSampler s)         { while (true) { ohTrig => now;         s.update(ohNote, ohGate, ohIndex); } }
fun void ravekickVoice(ZdSampler s)   { while (true) { ravekickTrig => now;   s.update(ravekickNote, ravekickGate, ravekickIndex); } }
fun void rideVoice(ZdSampler s)       { while (true) { rideTrig => now;       s.update(rideNote, rideGate, rideIndex); } }
fun void rimVoice(ZdSampler s)        { while (true) { rimTrig => now;        s.update(rimNote, rimGate, rimIndex); } }
fun void shakerVoice(ZdSampler s)     { while (true) { shakerTrig => now;     s.update(shakerNote, shakerGate, shakerIndex); } }
fun void snareVoice(ZdSampler s)      { while (true) { snareTrig => now;      s.update(snareNote, snareGate, snareIndex); } }
fun void speakspellVoice(ZdSampler s) { while (true) { speakspellTrig => now; s.update(speakspellNote, speakspellGate, speakspellIndex); } }
fun void tambVoice(ZdSampler s)       { while (true) { tambTrig => now;       s.update(tambNote, tambGate, tambIndex); } }
fun void timbVoice(ZdSampler s)       { while (true) { timbTrig => now;       s.update(timbNote, timbGate, timbIndex); } }
fun void tomVoice(ZdSampler s)        { while (true) { tomTrig => now;        s.update(tomNote, tomGate, tomIndex); } }

spork ~ bleepVoice(bleep);
spork ~ blipVoice(blip);
spork ~ bongoVoice(bongo);
spork ~ chVoice(ch);
spork ~ clapVoice(clap);
spork ~ claveVoice(clave);
spork ~ congaVoice(conga);
spork ~ cowbellVoice(cowbell);
spork ~ crashVoice(crash);
spork ~ fx2Voice(fx2);
spork ~ kickVoice(kick);
spork ~ ohVoice(oh);
spork ~ ravekickVoice(ravekick);
spork ~ rideVoice(ride);
spork ~ rimVoice(rim);
spork ~ shakerVoice(shaker);
spork ~ snareVoice(snare);
spork ~ speakspellVoice(speakspell);
spork ~ tambVoice(tamb);
spork ~ timbVoice(timb);
spork ~ tomVoice(tom);

// ===================== SYNTHS =====================

60  => global float hooverNote;
0   => global float hooverGate;
0.3 => global float hooverLevel;
global Event hooverTrig;

48    => global float acidNote;
0     => global float acidGate;
0.6   => global float acidLevel;
0.3   => global float acidCutoff;
4.5   => global float acidResonance;
0.64  => global float acidEnvMod;
0.282 => global float acidDecay;
0     => global float acidTuning;
0     => global float acidWaveform;
global Event acidTrig;

48   => global float reeseNote;
0    => global float reeseGate;
0.5  => global float reeseLevel;
2    => global float reeseDetune;
0.01 => global float reeseAttack;
0.2  => global float reeseDecay;
0.5  => global float reeseSustain;
0.1  => global float reeseRelease;
global Event reeseTrig;

33   => global float kick99Note;
0    => global float kick99Gate;
0.8  => global float kick99Level;
0.4  => global float kick99Decay;
150  => global float kick99PitchAmt;
0.03 => global float kick99PitchDecay;
0.3  => global float kick99Click;
global Event kick99Trig;

Hoover hoover => master;
Acid   acid   => master;
Reese  reese  => master;
Kick99 kick99 => master;

fun void hooverVoice(Hoover v)
{
    while (true)
    {
        hooverTrig => now;
        v.trigger(hooverNote, hooverGate, hooverLevel);
    }
}

fun void acidVoice(Acid v)
{
    while (true)
    {
        acidTrig => now;
        v.trigger(acidNote, acidGate, acidLevel, acidCutoff, acidResonance,
                  acidEnvMod, acidDecay, acidTuning, acidWaveform);
    }
}

fun void reeseVoice(Reese v)
{
    while (true)
    {
        reeseTrig => now;
        v.trigger(reeseNote, reeseGate, reeseLevel, reeseDetune,
                  reeseAttack, reeseDecay, reeseSustain, reeseRelease);
    }
}

fun void kick99Voice(Kick99 v)
{
    while (true)
    {
        kick99Trig => now;
        v.trigger(kick99Note, kick99Gate, kick99Level, kick99Decay,
                  kick99PitchAmt, kick99PitchDecay, kick99Click);
    }
}

spork ~ hooverVoice(hoover);
spork ~ acidVoice(acid);
spork ~ reeseVoice(reese);
spork ~ kick99Voice(kick99);

// ===================== RUN =====================
// all work happens in the voice shreds, keep the parent alive
while (true) 1::day => now;
' copyReplaceAll: 'TURBO_ROOT' with: turbo
]

{ #category : 'running' }
TurboPhuck class >> start [

	| perf |
	PhuckVM uniqueInstance releaseVM.
	tpVm := PhuckVM uniqueInstance.
	tpVm isRunning ifFalse: [ tpVm start ].
	tpVm run: self code.
	perf := Performance uniqueInstance.
	tpPerf := perf forPhuck: tpVm.
	tpPerf performanceType: PerfType new
]

{ #category : 'accessing' }
TurboPhuck class >> tpPerf [ 


^ tpPerf 
]

{ #category : 'accessing' }
TurboPhuck class >> tpVm [

	^ tpVm
]

{ #category : 'initialization' }
TurboPhuck >> initialize [

	super initialize.
	self class tpPerf resetAllSequencers.
	self class tpPerf maxStepNumber: SmallInteger maxVal.
	self class tpPerf removeAll
]

{ #category : 'playing' }
TurboPhuck >> loop: anInteger [

	self class tpPerf loop: anInteger
]

{ #category : 'playing' }
TurboPhuck >> mute: aSymbol [

	self class tpPerf mute: aSymbol
]

{ #category : 'playing' }
TurboPhuck >> muteAll [

	self class tpPerf muteAll
]

{ #category : 'running' }
TurboPhuck >> play [

	self class tpPerf play
]

{ #category : 'playing' }
TurboPhuck >> playFor: aNumberOfBars [

	self class tpPerf playFor: aNumberOfBars
]

{ #category : 'playing' }
TurboPhuck >> playNote: aMidiNN prefix: aString dur: aDuration [
	"Send a gate dur: aDuration in seconds to the parameter named aString, Gate and a MidiNN converted to Hertz to  the parameter named aString , Note"

	self class playNote: aMidiNN prefix: aString dur: aDuration
	"Send a gate dur: aDuration in seconds to the parameter named aString, Gate and a MidiNN converted to Hertz to  the parameter named aString , Note"
]

{ #category : 'playing' }
TurboPhuck >> rhythm: aRhythm [

	self class tpPerf rhythm: aRhythm
]

{ #category : 'playing' }
TurboPhuck >> solo: aSymbol [

	self class tpPerf solo: aSymbol
]

{ #category : 'running' }
TurboPhuck >> stop [

	self class tpPerf stop
]

{ #category : 'playing' }
TurboPhuck >> traceAllParams [

	self class tpVm traceAllParams
]

{ #category : 'playing' }
TurboPhuck >> trig: aString [
	"send a 10 ms trigger to a Faust parameter, designed to trig envelopes and percussions-like sounds"

	self class tpDsp trig: aString
]

{ #category : 'playing' }
TurboPhuck >> unloop [

	self class tpPerf unloop
]

{ #category : 'playing' }
TurboPhuck >> unmute: aSymbol [

	self class tpPerf unmute: aSymbol
]

{ #category : 'playing' }
TurboPhuck >> unsolo: aSymbol [

	self class tpPerf unsolo: aSymbol
]
