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
0 => global float beeThreeGate;  60 => global float beeThreeNote;
0 => global float sitarGate;     60 => global float sitarNote;

// ZdSampler
60 => global int bleepNote;      global int bleepGate;      global int bleepIndex;
60 => global int blipNote;       global int blipGate;       global int blipIndex;
60 => global int bongoNote;      global int bongoGate;      global int bongoIndex;
60 => global int chNote;         global int chGate;         global int chIndex;
60 => global int clapNote;       global int clapGate;       global int clapIndex;
60 => global int claveNote;      global int claveGate;      global int claveIndex;
60 => global int congaNote;      global int congaGate;      global int congaIndex;
60 => global int cowbellNote;    global int cowbellGate;    global int cowbellIndex;
60 => global int crashNote;      global int crashGate;      global int crashIndex;
60 => global int fx2Note;        global int fx2Gate;        global int fx2Index;
60 => global int kickNote;       global int kickGate;       global int kickIndex;
60 => global int ohNote;         global int ohGate;         global int ohIndex;
60 => global int ravekickNote;   global int ravekickGate;   global int ravekickIndex;
60 => global int rideNote;       global int rideGate;       global int rideIndex;
60 => global int rimNote;        global int rimGate;        global int rimIndex;
60 => global int shakerNote;     global int shakerGate;     global int shakerIndex;
60 => global int snareNote;      global int snareGate;      global int snareIndex;
60 => global int speakspellNote; global int speakspellGate; global int speakspellIndex;
60 => global int tambNote;       global int tambGate;       global int tambIndex;
60 => global int timbNote;       global int timbGate;       global int timbIndex;
60 => global int tomNote;        global int tomGate;        global int tomIndex;

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

class Hoover extends Chugraph
{
    SawOsc s1 => Gain mix => ADSR ampEnv => Gain out => outlet;
    SawOsc s2 => mix;
    SawOsc s3 => mix;
    TriOsc t1 => mix;
    0.3 => s2.gain;  0.3 => s3.gain;  0.3 => t1.gain;
    ampEnv.set(1::ms, 200::ms, 0.5, 350::ms);

    // pitch envelope as FM input, runs at audio rate inside the UGens
    Step one => ADSR pitchEnv;
    pitchEnv => Gain fm1 => s1;
    pitchEnv => Gain fm2 => s2;
    pitchEnv => Gain fm3 => s3;
    pitchEnv => Gain fm4 => t1;
    2 => s1.sync;  2 => s2.sync;  2 => s3.sync;  2 => t1.sync;
    126.0 => fm1.gain;  126.0 => fm2.gain;  252.0 => fm3.gain;  63.0 => fm4.gain;
    1.0 => one.next;
    pitchEnv.set(1::ms, 1::second, 0.0, 600::ms);

    -1.0 => float lastNote;
    0 => float lastGate;

    fun void tick(float note, float gate, float level)
    {
        if (note != lastNote)
        {
            Std.mtof(note) => float f;
            f         => s1.freq;
            f + 3     => s2.freq;
            f * 2 + 3 => s3.freq;
            f * 0.5   => t1.freq;
            note => lastNote;
        }
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

    fun void tick(float note, float gate, float level, float cutoff, float res,
                  float envMod, float decay, float tuning, float waveform)
    {
        if (gate != lastGate)
        {
            if (gate > 0)
            {
                filterEnv.set(1::ms, decay::second, 0.0, decay::second);
                ampEnv.keyOn();
                filterEnv.keyOn();
            }
            else ampEnv.keyOff();
            gate => lastGate;
        }

        Std.mtof(note) + tuning => float f;
        f => saw.freq;
        f => sqr.freq;
        if (waveform > 0.5) { 0.0 => saw.gain; 0.25 => sqr.gain; }
        else                { 0.25 => saw.gain; 0.0 => sqr.gain; }

        Math.min(1.0, filterEnv.last() * (1.0 - cutoff) * envMod + cutoff) => float n;
        Math.min(18000.0, 2.0 * Math.pow(10.0, 3.0 * n + 1.0)) => filt.freq;
        res => filt.Q;
        1.0 / (0.5 + cutoff) => comp.gain;
        level => out.gain;
    }
}

class Reese extends Chugraph
{
    SinOsc o1 => Gain mix => ADSR env => Gain out => outlet;
    SinOsc o2 => mix;
    0.3 => o1.gain;  0.3 => o2.gain;
    0 => float lastGate;

    fun void tick(float note, float gate, float level, float detune,
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

    fun void tick(float note, float gate, float level, float decay,
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

// ===================== STK HELPER =====================

// sets pitch only when the note changes, gates only on change
fun void stkVoice(StkInstrument inst, float lastNote[], float lastGate[],
                  int i, float note, float gate)
{
    if (note != lastNote[i])
    {
        Std.mtof(note) => inst.freq;
        note => lastNote[i];
    }
    if (gate == lastGate[i]) return;
    if (gate > 0) gate => inst.noteOn;
    else 1 => inst.noteOff;
    gate => lastGate[i];
}

// ===================== GRAPH =====================

Gain master => Dyno lim => dac;
0.8 => master.gain;
lim.limit();

// STK
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

float stkLastNote[12];
float stkLastGate[12];
for (0 => int i; i < 12; i++) -1.0 => stkLastNote[i];

// ZdSampler
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

// Synths
Hoover hoover => master;
Acid   acid   => master;
Reese  reese  => master;
Kick99 kick99 => master;

// ===================== RUN (single shred, 1 ms control rate) =====================

while (1::ms => now)
{
    // STK
    stkVoice(bell,      stkLastNote, stkLastGate, 0,  bellNote,      bellGate);
    stkVoice(brass,     stkLastNote, stkLastGate, 1,  brassNote,     brassGate);
    stkVoice(blow,      stkLastNote, stkLastGate, 2,  blowNote,      blowGate);
    stkVoice(clarinet,  stkLastNote, stkLastGate, 3,  clarinetNote,  clarinetGate);
    stkVoice(moog,      stkLastNote, stkLastGate, 4,  moogNote,      moogGate);
    stkVoice(stkShaker, stkLastNote, stkLastGate, 5,  stkShakerNote, stkShakerGate);
    stkVoice(bar,       stkLastNote, stkLastGate, 6,  barNote,       barGate);
    stkVoice(flut,      stkLastNote, stkLastGate, 7,  flutNote,      flutGate);
    stkVoice(rhodey,    stkLastNote, stkLastGate, 8,  rhodeyNote,    rhodeyGate);
    stkVoice(mandolin,  stkLastNote, stkLastGate, 9,  mandolinNote,  mandolinGate);
    stkVoice(b3,        stkLastNote, stkLastGate, 10, beeThreeNote,  beeThreeGate);
    stkVoice(sitar,     stkLastNote, stkLastGate, 11, sitarNote,     sitarGate);

    // ZdSampler
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

    // Synths
    hoover.tick(hooverNote, hooverGate, hooverLevel);
    acid.tick(acidNote, acidGate, acidLevel, acidCutoff, acidResonance,
              acidEnvMod, acidDecay, acidTuning, acidWaveform);
    reese.tick(reeseNote, reeseGate, reeseLevel, reeseDetune,
               reeseAttack, reeseDecay, reeseSustain, reeseRelease);
    kick99.tick(kick99Note, kick99Gate, kick99Level, kick99Decay,
                kick99PitchAmt, kick99PitchDecay, kick99Click);
}' copyReplaceAll: 'TURBO_ROOT' with: turbo
]

{ #category : 'examples' }
TurboPhuck class >> openBusinessCard [

| code |
code := '"Start TurboPhuck, you should hear all its sound playing together".
TurboPhuck start.

"create a new instance of TurboPhuck"
tp := TurboPhuck new.

"you can see all the TurboPhuck parameters in a Transcript"
TurboPhuck traceAllParams. 

"play the Performance"
tp playFor: 128 bars. 
"it is empty now but we will add a sequencer to it in the following lines"
"Sequencers can be created by sending the asSeq message to an array of 1 and 0"
 #(1 0 0 1 0 0 0 0) asSeq to: #kick.
"or by sending the asRhythm message to a valid rhythm preceded by an hash (that''s a Pharo symbol btw)"
#rumba asRhythm to: #conga.
"CMD+i (Mac) or CTRL+I (Win/Linux) on the next line to open an Inspector on the list of available rhythm"
Rhythm list.
"but if you want to type less (losing iconicity), just send the message to: to a valid rhythm"
#plena to: #conga.
"or sending the hexBeat message to a string containing only hexadecimal characters"
''020F'' hexBeat to: #snare.
"sending the index: message to a Sequence with a string of integers as an argument changes the samples indexes(if playing a TpSampler), which by default are all 0s" 
16 quavers index: ''0 1 2 3 '' to: #blip.
"sequencers can be joined with a comma - binary operator for joining collections in Pharo"
16 quavers , 16 semiquavers to: #oh.
"we can mute sequencers"
tp mute: #(#kick #snare #blip).
"and unmute them"
tp unmute: #(#kick #snare).
"you can create randomTrigs - and then cascade a string to change the level of the sound"
16 randomTrigs to: #ch; level: ''0.8 0.4 0.3''.
"or randomTrigs with a probability"
(16 randomTrigsWithProbability: 65) to: #ch.
"different samples inside the same folder can be played"
#ch index: 7 asRisingArray .
"also you can play samples of different folders, from the same Performance track"
''clap , snare ,  cowbell*2'' asDirtSounds to: #mix ; notes: ''60 38 72 56''.
"or you can create Sequencers by sending the asDirtNotes message to a string containin MIDI note numbers"
''-/8 , 38 , 56*2 , -/4 , 41 , 66'' asDirtNotes to: #mandolin.
"or a string with noteletters and octave number , using # for sharps and b for flats"
''c4, a4, f4*3, eb4, g#2, c1/2'' asDirtNotes to: #acid.
"if octave number is missing, notes are considering from octave 4"
''c, a , f , e '' asDirtNotes to: #acid.
"or sending asDirtIndex if you want to play a different sample in the folder (if more than one available)"
"sending the notes: message to a Sequence with a string of MIDI notes as an argument changes the notes of the Sequencer, which by default are all 60 (C3)."
''1 , -/16 . 7 , -/9 , 12 , -/12, 18'' asDirtIndex notes: ''38 45 78 62  81'' to: #speakspell.
"Euclidean rhythms can be created by sending the euclidean message to an array, where the first element is the number of steps and the second is the number of pulses."

#(5 16) euclidean index: '' 1 3 5 2''; to:  #bongo.
"Trigs inside a Sequencer can be offset forward"
#(5 16) euclidean offset: 1; to: #cowbell.
"or backwards"
"levels can be changed sending a message to the corresponding Performance key"
#shiko asRhythm to: #clap ; level: ''0.3  0.1 0.4''.

"we can arpeggiate the notes of a Sequencer"
#cumbiaClave asRhythm arpeggiate: ''12-sus4 0-min''; to: #bell; level: ''0.4''.
"or we can random walk through a scale over an octave span from a root note"
64 randomTrigs notes: (32 randomWalksOn: Scale sakura octaves: 2 root: 48) to: #rhodey.

"sequencers can be soloed"
tp solo: #(#bell #cowbell).
"and unsoloed - that takes the performance back to the status between the solo"
tp unsolo: #(#bell #cowbell).

"Performance can be temporary saved"
tp temporarySave.

"bpm can be changed"
tp bpm: 96.

"saved Performance can be restored"
tp restore.

"the same rhythm can be assigned to many Sequencers"
#(#kick #ch #cowbell ) rhythm: #banda .

"we can loop a certain amount of steps"
tp loop: 5.

"unloop"
tp unloop.

"set all the Seqeuncers to the same rhythm"
tp rhythm: ''1312'' hexBeat.

"stop the performance"
tp stop.

"UZU PLAYBACK"

tp  playCyclicFor: 96 bars.

''<c6 ~ d3 a2>*64'' asMondoNotes to: #acid.

''60*4 ~ 72*2'' asMondoNotes to: #kick.
''<snare rim  blip cowbell>*8'' asMondoSounds to: #mix.
''80 70 76 [77*5]'' asMondoNotes to: #clap; 

"but traditional Coypu method can be used also in the cyclic playback, sequencer length will be trimmed to 16 steps"
16 upbeats to: #ride.
tp solo: #acid.
#downbeats asRhythm to: #kick.
#(3 16) euclidean to: #rim.
16 randomTrigs to: #blip; index: ''1 2 3 ''; notes: ''40 51''.
tp mute: #blip.

tp stop.

'.


StPlayground new contents: code ; open
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
