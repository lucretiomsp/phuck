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
	^ '// ===================== GLOBALS =====================

// STK
0 => global float bellGate;      60 => global float bellNote;
0 => global float brassGate;     60 => global float brassNote;
0 => global float blowGate;      60 => global float blowNote;
0 => global float clarinetGate;  60 => global float clarinetNote;
0 => global float moogGate;      60 => global float moogNote;
0 => global float stkShakerGate; 60 => global float stkShakerNote;
0 => global float barGate;       60 => global float barNote;
0 => global float flutGate;      60 => global float flutNote;
0 => global float rhodeyGate;    60 => global float rhodeyNote;
0 => global float mandolinGate;  60 => global float mandolinNote;
0 => global float b3Gate;        60 => global float b3Note;
0 => global float sitarGate;     60 => global float sitarNote;

// ZdSampler
global int bleepNote; global int bleepGate; global int bleepIndex;
global int blipNote; global int blipGate; global int blipIndex;
global int bongoNote; global int bongoGate; global int bongoIndex;
global int chNote; global int chGate; global int chIndex;
global int clapNote; global int clapGate; global int clapIndex;
global int claveNote; global int claveGate; global int claveIndex;
global int congaNote; global int congaGate; global int congaIndex;
global int cowbellNote; global int cowbellGate; global int cowbellIndex;
global int crashNote; global int crashGate; global int crashIndex;
global int fx2Note; global int fx2Gate; global int fx2Index;
global int kickNote; global int kickGate; global int kickIndex;
global int ohNote; global int ohGate; global int ohIndex;
global int ravekickNote; global int ravekickGate; global int ravekickIndex;
global int rideNote; global int rideGate; global int rideIndex;
global int rimNote; global int rimGate; global int rimIndex;
global int shakerNote; global int shakerGate; global int shakerIndex;
global int snareNote; global int snareGate; global int snareIndex;
global int speakspellNote; global int speakspellGate; global int speakspellIndex;
global int tambNote; global int tambGate; global int tambIndex;
global int timbNote; global int timbGate; global int timbIndex;
global int tomNote; global int tomGate; global int tomIndex;

// Hoover
60  => global float hooverNote;
0   => global float hooverGate;
0.3 => global float hooverLevel;

// Acid
48    => global float acidNote;
0     => global float acidGate;
0.6   => global float acidLevel;
0.3   => global float acidCutoff;
4.5   => global float acidResonance;
0.64  => global float acidEnvMod;
0.282 => global float acidDecay;
0     => global float acidTuning;
0     => global float acidWaveform;

// Reese
48   => global float reeseNote;
0    => global float reeseGate;
0.5  => global float reeseLevel;
2    => global float reeseDetune;
0.01 => global float reeseAttack;
0.2  => global float reeseDecay;
0.5  => global float reeseSustain;
0.1  => global float reeseRelease;

// Kick99
33   => global float kick99Note;
0    => global float kick99Gate;
0.8  => global float kick99Level;
0.4  => global float kick99Decay;
150  => global float kick99PitchAmt;
0.03 => global float kick99PitchDecay;
0.3  => global float kick99Click;

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

// ===================== STK =====================

fun void stkVoice(StkInstrument inst, float last[], int i, float note, float gate)
{
    Std.mtof(note) => inst.freq;
    if (gate == last[i]) return;
    if (gate > 0) gate => inst.noteOn;
    else 1 => inst.noteOff;
    gate => last[i];
}

fun void stkLoop()
{
    Gain master => dac;
    0.3 => master.gain;

    TubeBell bell     => Gain bellAmp     => master;
    Brass brass       => Gain brassAmp    => master;
    BlowBotl blow     => Gain blowAmp     => master;
    Clarinet clarinet => Gain clarinetAmp => master;
    Moog moog         => Gain moogAmp     => master;
    Shakers shaker    => Gain shakerAmp   => master;
    ModalBar bar      => Gain barAmp      => master;
    PercFlut flut     => Gain flutAmp     => master;
    Rhodey rhodey     => Gain rhodeyAmp   => master;
    Mandolin mandolin => Gain mandolinAmp => master;
    BeeThree b3       => Gain b3Amp       => master;
    Sitar sitar       => Gain sitarAmp    => master;

    [bellAmp, brassAmp, blowAmp, clarinetAmp, moogAmp, shakerAmp,
     barAmp, flutAmp, rhodeyAmp, mandolinAmp, b3Amp, sitarAmp] @=> Gain amps[];
    for (0 => int i; i < amps.size(); i++) 0.5 => amps[i].gain;

    float lastGate[12];

    while (samp => now)
    {
        stkVoice(bell,     lastGate, 0,  bellNote,      bellGate);
        stkVoice(brass,    lastGate, 1,  brassNote,     brassGate);
        stkVoice(blow,     lastGate, 2,  blowNote,      blowGate);
        stkVoice(clarinet, lastGate, 3,  clarinetNote,  clarinetGate);
        stkVoice(moog,     lastGate, 4,  moogNote,      moogGate);
        stkVoice(shaker,   lastGate, 5,  stkShakerNote, stkShakerGate);
        stkVoice(bar,      lastGate, 6,  barNote,       barGate);
        stkVoice(flut,     lastGate, 7,  flutNote,      flutGate);
        stkVoice(rhodey,   lastGate, 8,  rhodeyNote,    rhodeyGate);
        stkVoice(mandolin, lastGate, 9,  mandolinNote,  mandolinGate);
        stkVoice(b3,       lastGate, 10, b3Note,        b3Gate);
        stkVoice(sitar,    lastGate, 11, sitarNote,     sitarGate);
    }
}

// ===================== ZDSAMPLER =====================

fun void zdLoop()
{
    "TURBO_ROOT" => string turbo;

    ZdSampler bleep(turbo + "/bleep") => dac;
    ZdSampler blip(turbo + "/blip") => dac;
    ZdSampler bongo(turbo + "/bongo") => dac;
    ZdSampler ch(turbo + "/ch") => dac;
    ZdSampler clap(turbo + "/clap") => dac;
    ZdSampler clave(turbo + "/clave") => dac;
    ZdSampler conga(turbo + "/conga") => dac;
    ZdSampler cowbell(turbo + "/cowbell") => dac;
    ZdSampler crash(turbo + "/crash") => dac;
    ZdSampler fx2(turbo + "/fx2") => dac;
    ZdSampler kick(turbo + "/kick") => dac;
    ZdSampler oh(turbo + "/oh") => dac;
    ZdSampler ravekick(turbo + "/ravekick") => dac;
    ZdSampler ride(turbo + "/ride") => dac;
    ZdSampler rim(turbo + "/rim") => dac;
    ZdSampler shaker(turbo + "/shaker") => dac;
    ZdSampler snare(turbo + "/snare") => dac;
    ZdSampler speakspell(turbo + "/speakspell") => dac;
    ZdSampler tamb(turbo + "/tamb") => dac;
    ZdSampler timb(turbo + "/timb") => dac;
    ZdSampler tom(turbo + "/tom") => dac;

    60 => bleepNote;  60 => blipNote;   60 => bongoNote;   60 => chNote;
    60 => clapNote;   60 => claveNote;  60 => congaNote;   60 => cowbellNote;
    60 => crashNote;  60 => fx2Note;    60 => kickNote;    60 => ohNote;
    60 => ravekickNote; 60 => rideNote; 60 => rimNote;     60 => shakerNote;
    60 => snareNote;  60 => speakspellNote; 60 => tambNote; 60 => timbNote;
    60 => tomNote;

    while (samp => now)
    {
        bleep.update(bleepNote, bleepGate, bleepIndex);
        blip.update(blipNote, blipGate, blipIndex);
        bongo.update(bongoNote, bongoGate, bongoIndex);
        ch.update(chNote, chGate, chIndex);
        clap.update(clapNote, clapGate, clapIndex);
        clave.update(claveNote, claveGate, claveIndex);
        conga.update(congaNote, congaGate, congaIndex);
        cowbell.update(cowbellNote, cowbellGate, cowbellIndex);
        crash.update(crashNote, crashGate, crashIndex);
        fx2.update(fx2Note, fx2Gate, fx2Index);
        kick.update(kickNote, kickGate, kickIndex);
        oh.update(ohNote, ohGate, ohIndex);
        ravekick.update(ravekickNote, ravekickGate, ravekickIndex);
        ride.update(rideNote, rideGate, rideIndex);
        rim.update(rimNote, rimGate, rimIndex);
        shaker.update(shakerNote, shakerGate, shakerIndex);
        snare.update(snareNote, snareGate, snareIndex);
        speakspell.update(speakspellNote, speakspellGate, speakspellIndex);
        tamb.update(tambNote, tambGate, tambIndex);
        timb.update(timbNote, timbGate, timbIndex);
        tom.update(tomNote, tomGate, tomIndex);
    }
}

// ===================== HOOVER =====================

fun void hooverLoop()
{
    SawOsc s1 => Gain mix;
    SawOsc s2 => mix;
    SawOsc s3 => mix;
    TriOsc t1 => mix;
    0.3 => s2.gain;  0.3 => s3.gain;  0.3 => t1.gain;

    mix => ADSR ampEnv => Gain out => dac;
    ampEnv.set(1::ms, 200::ms, 0.5, 350::ms);

    Step one => ADSR pitchEnv => blackhole;
    1.0 => one.next;
    pitchEnv.set(1::ms, 1::second, 0.0, 600::ms);
    126.0 => float pitchEnvAmt;

    0 => float lastGate;
    while (samp => now)
    {
        Std.mtof(hooverNote) + pitchEnv.last() * pitchEnvAmt => float f;
        f         => s1.freq;
        f + 3     => s2.freq;
        f * 2 + 3 => s3.freq;
        f * 0.5   => t1.freq;
        hooverLevel => out.gain;

        if (hooverGate != lastGate)
        {
            if (hooverGate > 0) { ampEnv.keyOn();  pitchEnv.keyOn(); }
            else                { ampEnv.keyOff(); pitchEnv.keyOff(); }
            hooverGate => lastGate;
        }
    }
}

// ===================== ACID =====================

fun void acidLoop()
{
    SawOsc saw => Gain osc;
    SqrOsc sqr => osc;
    osc => ADSR ampEnv => LPF filt => Gain comp => AcidCubic dist => Gain out => dac;
    ampEnv.set(1::ms, 200::ms, 0.0, 200::ms);

    Step one => ADSR filterEnv => blackhole;
    1.0 => one.next;

    0 => float lastGate;
    while (samp => now)
    {
        Std.mtof(acidNote) + acidTuning => float f;
        f => saw.freq;
        f => sqr.freq;
        if (acidWaveform > 0.5) { 0.0 => saw.gain; 0.25 => sqr.gain; }
        else                    { 0.25 => saw.gain; 0.0 => sqr.gain; }

        filterEnv.last() * (1.0 - acidCutoff) * acidEnvMod + acidCutoff => float n;
        Math.min(1.0, n) => n;
        Math.min(18000.0, 2.0 * Math.pow(10.0, 3.0 * n + 1.0)) => filt.freq;
        acidResonance => filt.Q;
        1.0 / (0.5 + acidCutoff) => comp.gain;
        acidLevel => out.gain;

        if (acidGate != lastGate)
        {
            if (acidGate > 0)
            {
                filterEnv.set(1::ms, acidDecay::second, 0.0, acidDecay::second);
                ampEnv.keyOn();
                filterEnv.keyOn();
            }
            acidGate => lastGate;
        }
    }
}

// ===================== REESE =====================

fun void reeseLoop()
{
    SinOsc o1 => Gain mix;
    SinOsc o2 => mix;
    0.3 => o1.gain;  0.3 => o2.gain;
    mix => ADSR env => Gain out => dac;

    0 => float lastGate;
    while (samp => now)
    {
        Std.mtof(reeseNote) => float f;
        f => o1.freq;
        f + reeseDetune => o2.freq;
        reeseLevel => out.gain;

        if (reeseGate != lastGate)
        {
            if (reeseGate > 0)
            {
                env.set(reeseAttack::second, reeseDecay::second, reeseSustain, reeseRelease::second);
                env.keyOn();
            }
            else env.keyOff();
            reeseGate => lastGate;
        }
    }
}

// ===================== KICK99 =====================

fun void kick99Loop()
{
    SinOsc body => Gain bodyAmp => Kick99Clip clip => Gain out => dac;
    Noise noise => HPF clickHp => ADSR clickEnv => Gain clickAmp => out;
    3000 => clickHp.freq;
    clickEnv.set(0.5::ms, 6::ms, 0.0, 1::ms);

    second / samp => float sr;
    0.0 => float pEnv;  0.0 => float aEnv;
    0.0 => float pCoef; 0.0 => float aCoef;

    0 => float lastGate;
    while (samp => now)
    {
        if (kick99Gate != lastGate)
        {
            if (kick99Gate > 0)
            {
                Math.exp(-1.0 / (kick99PitchDecay * sr)) => pCoef;
                Math.exp(-1.0 / (kick99Decay * sr))      => aCoef;
                1.0 => pEnv;  1.0 => aEnv;
                0.0 => body.phase;
                clickEnv.keyOn();
            }
            kick99Gate => lastGate;
        }

        Std.mtof(kick99Note) + kick99PitchAmt * pEnv => body.freq;
        aEnv * 1.5   => bodyAmp.gain;
        kick99Click  => clickAmp.gain;
        kick99Level  => out.gain;
        pEnv * pCoef => pEnv;
        aEnv * aCoef => aEnv;
    }
}

// ===================== RUN =====================

spork ~ stkLoop();
spork ~ zdLoop();
spork ~ hooverLoop();
spork ~ acidLoop();
spork ~ reeseLoop();
spork ~ kick99Loop();

// keep the parent alive, otherwise the sporked children die
while (true) 1::day => now;
' copyReplaceAll: 'TURBO_ROOT' with: turbo
]

{ #category : 'running' }
TurboPhuck class >> start [

	| perf |
	perf := Performance uniqueInstance.
	tpVm := PhuckVM uniqueInstance.
	tpVm releaseVM 
	tpVm run: self code.
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
