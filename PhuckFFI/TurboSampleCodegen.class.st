"
TurboSampleCodegen comment: 'I turn the folders of TurboSamples into ChucK code: one player per subfolder, so a new folder needs no change in the template.

A folder becomes a ZdLoopPlayer when one of its files has a bpm tag, a | in the file name like amen|170.wav (the tag ZdLoopPlayer reads). Every other folder becomes a ZdSampler. Hidden folders are skipped, the rest is taken in alphabetical order.

I fill four markers of a ChucK template, each one must appear exactly once:
- //@GLOBALS: Note, Gate, Index and Level of each player, plus Reverse, Position, Slice and Length for loops
- //@GRAPH: the player declaration, loaded from turbo + the folder name
- //@UPDATES: the update call of each player, inside the control loop
- //@EVENTS: one trigEvent line per player

The template defines the rest: ZdSampler, ZdLoopPlayer, master, performanceBPM, trigEvent and turbo (the TurboSamples path, the caller replaces TURBO_ROOT after expand:).

Typical use, with samplesFolder the TurboSamples directory and template the ChucK source:

```language=Pharo
	TurboSampleCodegen new
		root: samplesFolder;
		expand: template
```

The ChucK name of a folder is its name reduced to ASCII letters and digits, starting with a letter (hi-hat gives hihat). The path keeps the real name. I raise an error for two folders with the same name, a name the template already declares (hoover, bell), a missing marker, or a folder without a usable name.

report tells what each folder becomes. Check it after adding a folder: a loop folder without any tagged file becomes a sampler, without a warning.'
"
Class {
	#name : 'TurboSampleCodegen',
	#superclass : 'Object',
	#instVars : [
		'root'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'helpers' }
TurboSampleCodegen >> checkNames: names against: aTemplate [
	"catches clashes with what the template already declares, e.g. a folder named hoover or bell"
	names do: [ :each |
		(names occurrencesOf: each) > 1
			ifTrue: [ self error: 'two folders give the name ', each ].
		(aTemplate includesSubstring: ' ', each, 'Level')
			ifTrue: [ self error: each, ' is already declared in the template' ] ]
]

{ #category : 'defaults' }
TurboSampleCodegen >> codeWithOSCSender [

	
	root := (FileLocator imageDirectory / 'TurboSamples') asFileReference.
	^ (TurboSampleCodegen new root: root; expand: '// ===================== GLOBALS =====================
// Master
0.8 => global float masterLevel;

// STK
0 => global float bellGate;      60 => global float bellNote;      0.5 => global float bellLevel;
0 => global float brassGate;     60 => global float brassNote;     0.5 => global float brassLevel;
0 => global float blowGate;      60 => global float blowNote;      0.5 => global float blowLevel;
0 => global float clarinetGate;  60 => global float clarinetNote;  0.5 => global float clarinetLevel;
0 => global float moogGate;      60 => global float moogNote;      0.5 => global float moogLevel;
0 => global float stkShakerGate; 60 => global float stkShakerNote; 0.5 => global float stkShakerLevel;
0 => global float barGate;       60 => global float barNote;       0.5 => global float barLevel;
0 => global float flutGate;      60 => global float flutNote;      0.5 => global float flutLevel;
0 => global float rhodeyGate;    60 => global float rhodeyNote;    0.5 => global float rhodeyLevel;
0 => global float mandolinGate;  60 => global float mandolinNote;  0.5 => global float mandolinLevel;
0 => global float beeThreeGate;  60 => global float beeThreeNote;  0.5 => global float beeThreeLevel;
0 => global float sitarGate;     60 => global float sitarNote;     0.5 => global float sitarLevel;

//@GLOBALS
174 => global float performanceBPM;

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

    fun void update(int n, int g, int i, float l)
    {
        setLevel(l);
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

class ZdLoopPlayer extends Chugraph
{
    SndBuf buf => ADSR env => Gain out => outlet;
    string dirPath;
    string files[0];
    float origBpms[0];
    0   => int curIndex;
    60  => int curNote;
    0   => int curGate;
    0   => int curReverse;
    0.0 => float curPosition;
    -1.0 => float curSlice;
    0.0 => float curLength;
    174 => float curBpm;
    env.set(1::ms, 380::ms, 1.0, 120::ms);
    0.4 => buf.gain;
    1.0 => buf.rate;
    buf.samples() => buf.pos;

    fun ZdLoopPlayer() { }
    fun ZdLoopPlayer(string folder) { load(folder); }

    fun int load(string folder)
    {
        folder => dirPath;
        if (dirPath.length() > 0 && dirPath.charAt(dirPath.length() - 1) != 47)
            "/" +=> dirPath;
        FileIO dir;
        if (!dir.open(folder, FileIO.READ) || !dir.isDir())
        {
            cherr <= "[ZdLoopPlayer] cannot open folder: " <= folder <= IO.nl();
            string none[0] @=> files;
            return 0;
        }
        ZdSampler.sortAlpha(ZdSampler.filterAudio(dir.dirList())) @=> files;
        dir.close();
        if (files.size() == 0)
        {
            cherr <= "[ZdLoopPlayer] no audio files in: " <= folder <= IO.nl();
            return 0;
        }
        origBpms.size(files.size());
        for (0 => int i; i < files.size(); i++)
        {
            getBpmFromFileName(files[i]) => origBpms[i];
            if (origBpms[i] <= 0)
                cherr <= "[ZdLoopPlayer] no bpm in " <= files[i] <= ", plays at native speed" <= IO.nl();
        }
        loadIndex(0);
        return files.size();
    }

    fun void update(int n, int g, int i, float b, float l, int r, float p, float sl, float len)
    {
        setLevel(l);
        bpm(b);
        reverse(r);
        bars(len);
        slice(sl);
        position(p);
        index(i);
        note(n);
        gate(g);
    }

    fun void setLevel(float g) { g => buf.gain; }

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
    }

    fun void index(int i)
    {
        if (files.size() == 0) return;
        wrap(i) => int w;
        if (w == curIndex) return;
        loadIndex(w);
    }

    // ignores bogus values (e.g. an int read as float gives 0)
    fun void bpm(float b)
    {
        if (b <= 0 || b == curBpm) return;
        b => curBpm;
        updateRate();
    }

    // 1 plays backwards; while playing, turns around at the current playhead
    fun void reverse(int r)
    {
        (r != 0) => int on;
        if (on == curReverse) return;
        on => curReverse;
        updateRate();
        if (!curGate) park();
    }

    // offset from the start point along the playback direction, 0..1 of the file
    fun void position(float p)
    {
        if (p == curPosition) return;
        p => curPosition;
        jump();
    }

    // start step in 16ths of the loop, fractions allowed, wraps; negative = whole loop;
    // reversed, the same 16th plays backwards
    fun void slice(float s)
    {
        if (s == curSlice) return;
        s => curSlice;
        jump();
    }

    // loop length in bars for the 16th grid, 0 = worked out from the file bpm
    fun void bars(float b)
    {
        if (b < 0) 0.0 => b;
        if (b == curLength) return;
        b => curLength;
        jump();
    }

    // while playing, move the playhead to the new start point
    fun void jump()
    {
        if (curGate && files.size() > 0) startFrame() => buf.pos;
    }

    fun void trigger()
    {
        if (files.size() == 0) return;
        updateRate();
        startFrame() => buf.pos;
        env.keyOn();
    }

    // bpm sync times transposition (note 60 = in sync), negative when reversed
    fun void updateRate()
    {
        if (files.size() == 0) return;
        1.0 => float ratio;
        if (origBpms[curIndex] > 0) curBpm / origBpms[curIndex] => ratio;
        ratio * Math.pow(2.0, (curNote - 60) / 12.0) => ratio;
        if (curReverse) -ratio => ratio;
        ratio => buf.rate;
    }

    // file frames in one 16th: from loopLength if set, else from the file bpm, else 1 bar
    fun float stepFrames()
    {
        buf.samples() => int n;
        if (curLength > 0) return n / (16.0 * curLength);
        if (origBpms[curIndex] > 0)
            return (15.0 / origBpms[curIndex]) * (n / (buf.length() / second));
        return n / 16.0;
    }

    // start of the 16th (its end when reversed, whole file when slicing is off),
    // moved by curPosition along the playback direction
    fun int startFrame()
    {
        buf.samples() => int n;
        0.0 => float from;
        n $ float => float to;
        if (curSlice >= 0)
        {
            stepFrames() => float step;
            Math.max(1.0, Math.round(n / step)) => float steps;
            curSlice - steps * Math.floor(curSlice / steps) => float k;
            k * step => from;
            (k + 1) * step => to;
        }
        from + curPosition * n => float p;
        if (curReverse) to - curPosition * n => p;
        return Math.max(0.0, Math.min(n - 1.0, p)) $ int;
    }

    // playhead where nothing plays in the current direction
    fun void park()
    {
        if (curReverse) 0 => buf.pos;
        else buf.samples() => buf.pos;
    }

    fun int wrap(int i)
    {
        return ((i % files.size()) + files.size()) % files.size();
    }

    fun void loadIndex(int i)
    {
        i => curIndex;
        dirPath + files[curIndex] => buf.read;
        updateRate();
        if (curGate) startFrame() => buf.pos;
        else park();
    }

    // pipe tag first (myBassLoop|128.wav), else first number in 60..250, else 0
    fun float getBpmFromFileName(string fileName)
    {
        fileName => string base;
        fileName.rfind(".") => int dot;
        if (dot > 0) fileName.substring(0, dot) => base;
        base.rfind("|") => int pipe;
        if (pipe >= 0 && pipe < base.length() - 1)
        {
            base.substring(pipe + 1).toFloat() => float b;
            if (b > 0) return b;
        }
        return guessBpm(base);
    }

    fun float guessBpm(string base)
    {
        0 => int num;
        0 => int inRun;
        for (0 => int i; i <= base.length(); i++)
        {
            -1 => int c;
            if (i < base.length()) base.charAt(i) => c;
            if (c >= 48 && c <= 57)
            {
                num * 10 + (c - 48) => num;
                1 => inRun;
            }
            else
            {
                if (inRun && num >= 60 && num <= 250) return num $ float;
                0 => num;
                0 => inRun;
            }
        }
        return 0.0;
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
fun void stkVoice(StkInstrument inst, Gain amp, float lastNote[], float lastGate[],
                  int i, float note, float gate, float level)
{
    level => amp.gain;
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

// ===================== OSC EVENTS =====================
// one message per gate change: /<name>Event trig note (trig 1 or 0, MIDI note)
OscOut oscOut;
oscOut.dest("localhost", 57120);
int lastTrig[0];

fun void trigEvent(string name, float gate, float note)
{
    (gate > 0) => int on;
    if (lastTrig[name] == on) return;
    on => lastTrig[name];
    oscOut.start("/" + name + "Event").add(on $ float).add(note).send();
}

// ===================== GRAPH =====================
Gain master => Dyno lim => dac;
masterLevel => master.gain;
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
float stkLastNote[12];
float stkLastGate[12];
for (0 => int i; i < 12; i++) -1.0 => stkLastNote[i];

"TURBO_ROOT" => string turbo;
//@GRAPH

// Synths
Hoover hoover => master;
Acid   acid   => master;
Reese  reese  => master;
Kick99 kick99 => master;

// ===================== RUN (single shred, 1 ms control rate) =====================
while (1::ms => now)
{
    // Master
    masterLevel => master.gain;

    // STK
    stkVoice(bell,      bellAmp,      stkLastNote, stkLastGate, 0,  bellNote,      bellGate,      bellLevel);
    stkVoice(brass,     brassAmp,     stkLastNote, stkLastGate, 1,  brassNote,     brassGate,     brassLevel);
    stkVoice(blow,      blowAmp,      stkLastNote, stkLastGate, 2,  blowNote,      blowGate,      blowLevel);
    stkVoice(clarinet,  clarinetAmp,  stkLastNote, stkLastGate, 3,  clarinetNote,  clarinetGate,  clarinetLevel);
    stkVoice(moog,      moogAmp,      stkLastNote, stkLastGate, 4,  moogNote,      moogGate,      moogLevel);
    stkVoice(stkShaker, stkShakerAmp, stkLastNote, stkLastGate, 5,  stkShakerNote, stkShakerGate, stkShakerLevel);
    stkVoice(bar,       barAmp,       stkLastNote, stkLastGate, 6,  barNote,       barGate,       barLevel);
    stkVoice(flut,      flutAmp,      stkLastNote, stkLastGate, 7,  flutNote,      flutGate,      flutLevel);
    stkVoice(rhodey,    rhodeyAmp,    stkLastNote, stkLastGate, 8,  rhodeyNote,    rhodeyGate,    rhodeyLevel);
    stkVoice(mandolin,  mandolinAmp,  stkLastNote, stkLastGate, 9,  mandolinNote,  mandolinGate,  mandolinLevel);
    stkVoice(b3,        b3Amp,        stkLastNote, stkLastGate, 10, beeThreeNote,  beeThreeGate,  beeThreeLevel);
    stkVoice(sitar,     sitarAmp,     stkLastNote, stkLastGate, 11, sitarNote,     sitarGate,     sitarLevel);

//@UPDATES

    // Synths
    hoover.tick(hooverNote, hooverGate, hooverLevel);
    acid.tick(acidNote, acidGate, acidLevel, acidCutoff, acidResonance,
              acidEnvMod, acidDecay, acidTuning, acidWaveform);
    reese.tick(reeseNote, reeseGate, reeseLevel, reeseDetune,
               reeseAttack, reeseDecay, reeseSustain, reeseRelease);
    kick99.tick(kick99Note, kick99Gate, kick99Level, kick99Decay,
                kick99PitchAmt, kick99PitchDecay, kick99Click);

    // OSC events: one message per gate change
    trigEvent("bell",       bellGate,       bellNote);
    trigEvent("brass",      brassGate,      brassNote);
    trigEvent("blow",       blowGate,       blowNote);
    trigEvent("clarinet",   clarinetGate,   clarinetNote);
    trigEvent("moog",       moogGate,       moogNote);
    trigEvent("stkShaker",  stkShakerGate,  stkShakerNote);
    trigEvent("bar",        barGate,        barNote);
    trigEvent("flut",       flutGate,       flutNote);
    trigEvent("rhodey",     rhodeyGate,     rhodeyNote);
    trigEvent("mandolin",   mandolinGate,   mandolinNote);
    trigEvent("beeThree",   beeThreeGate,   beeThreeNote);
    trigEvent("sitar",      sitarGate,      sitarNote);

//@EVENTS

    trigEvent("hoover",     hooverGate,     hooverNote);
    trigEvent("acid",       acidGate,       acidNote);
    trigEvent("reese",      reeseGate,      reeseNote);
    trigEvent("kick99",     kick99Gate,     kick99Note);
}')
		copyReplaceAll: 'TURBO_ROOT' with: root asChuckPath
]

{ #category : 'helpers' }
TurboSampleCodegen >> eventFor: aFolder [
	^ '    trigEvent("<1s>", <1s>Gate, <1s>Note);' expandMacrosWith: (self nameFor: aFolder)
]

{ #category : 'helpers' }
TurboSampleCodegen >> expand: aTemplate [
	| code |
	self
		checkNames: (self folders collect: [ :each | self nameFor: each ])
		against: aTemplate.
	code := aTemplate.
	#('//@GLOBALS' globalsFor: '//@GRAPH' graphFor: '//@UPDATES' updateFor: '//@EVENTS' eventFor:)
		pairsDo: [ :marker :selector |
			(code includesSubstring: marker)
				ifFalse: [ self error: 'template has no ', marker ].
			code := code copyReplaceAll: marker with: (self join: selector) ].
	^ code
]

{ #category : 'helpers' }
TurboSampleCodegen >> folders [
	"visible subfolders, alphabetical so the output is stable between runs"
	^ (root directories reject: [ :each | each basename beginsWith: '.' ])
		sorted: [ :a :b | a basename <= b basename ]
]

{ #category : 'helpers' }
TurboSampleCodegen >> globalsFor: aFolder [
	^ ((self isLoop: aFolder)
		ifTrue: [ '60 => global int <1s>Note; 0 => global int <1s>Gate; 0 => global int <1s>Index; 0.4 => global float <1s>Level; 0 => global int <1s>Reverse; 0 => global float <1s>Position; -1 => global float <1s>Slice; 0 => global float <1s>Length;' ]
		ifFalse: [ '60 => global int <1s>Note; global int <1s>Gate; global int <1s>Index; 0.4 => global float <1s>Level;' ])
			expandMacrosWith: (self nameFor: aFolder)

]

{ #category : 'helpers' }
TurboSampleCodegen >> graphFor: aFolder [
	^ '<1s> <2s>(turbo + "/<3s>") => master;'
		expandMacrosWith: (self playerClassFor: aFolder)
		with: (self nameFor: aFolder)
		with: aFolder basename
]

{ #category : 'helpers' }
TurboSampleCodegen >> isLoop: aFolder [
	"a loop folder holds at least one file with a bpm tag, like amen|170.wav"
	^ aFolder files anySatisfy: [ :each | each basename includes: $| ]
]

{ #category : 'helpers' }
TurboSampleCodegen >> join: aSelector [
	"one generated line per folder, with Pharo line endings like the template"
	^ String streamContents: [ :stream |
		self folders
			do: [ :each | stream << (self perform: aSelector with: each) ]
			separatedBy: [ stream cr ] ]

]

{ #category : 'helpers' }
TurboSampleCodegen >> nameFor: aFolder [
	"folder name as a ChucK identifier"
	| name |
	name := aFolder basename select: [ :c | c isAlphaNumeric and: [ c asInteger < 128 ] ].
	(name notEmpty and: [ name first isLetter ])
		ifFalse: [ self error: 'no ChucK name possible for folder ', aFolder basename ].
	^ name
]

{ #category : 'helpers' }
TurboSampleCodegen >> playerClassFor: aFolder [
	^ (self isLoop: aFolder) ifTrue: [ 'ZdLoopPlayer' ] ifFalse: [ 'ZdSampler' ]
]

{ #category : 'helpers' }
TurboSampleCodegen >> report [
	"what every folder becomes, worth a look after adding one"
	^ String streamContents: [ :stream |
		self folders
			do: [ :each | stream << each basename << ' : ' << (self playerClassFor: each) ]
			separatedBy: [ stream cr ] ]
]

{ #category : 'accessing' }
TurboSampleCodegen >> root: aFileReference [
	root := aFileReference
]

{ #category : 'helpers' }
TurboSampleCodegen >> updateFor: aFolder [
	^ ((self isLoop: aFolder)
		ifTrue: [ '    <1s>.update(<1s>Note, <1s>Gate, <1s>Index, performanceBPM, <1s>Level, <1s>Reverse, <1s>Position, <1s>Slice, <1s>Length);' ]
		ifFalse: [ '    <1s>.update(<1s>Note, <1s>Gate, <1s>Index, <1s>Level);' ])
			expandMacrosWith: (self nameFor: aFolder)
]
