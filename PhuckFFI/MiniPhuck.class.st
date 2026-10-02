"
Lightweight engine a la TurboPhausto to be used with Coypu for programming music on-the-fly
"
Class {
	#name : 'MiniPhuck',
	#superclass : 'Object',
	#category : 'PhuckFFI-Core',
	#package : 'PhuckFFI',
	#tag : 'Core'
}

{ #category : 'code generation' }
MiniPhuck class >> justTubeBell [

^ '0 => global float bellGate;
0.5 => global float bellNote;


/* Play a sine wave at 440Hz for 1 week */
TubeBell bell => dac;
// 1.0 => bell.noteOn;


while (samp => now)
    {
        Std.mtof(bellNote ) => bell.freq;
        bellGate => bell.noteOn;
       
}'
]

{ #category : 'code generation' }
MiniPhuck class >> stkInstCode [

	^ '// define globals
0 => global float bellGate;      0.5 => global float bellNote;
0 => global float brassGate;     0.5 => global float brassNote;
0 => global float blowGate;      0.5 => global float blowNote;
0 => global float clarinetGate;  0.5 => global float clarinetNote;
0 => global float moogGate;      0.5 => global float moogNote;
0 => global float shakerGate;     0.5 => global float shakerNote;
0 => global float barGate;       0.5 => global float barNote;

// mixer, so seven voices don''t clip
Gain master => dac;
0.3 => master.gain;

// define instruments
TubeBell bell => master;
Brass brass => master;
BlowBotl blow => master;
Clarinet clarinet => master;
Moog moog => master;
Shakers shaker => master;
ModalBar bar => master;

 
fun void voice(StkInstrument inst, float note, float gate)
{
    Std.mtof(note) => inst.freq;
    gate => inst.noteOn;
}

while (samp => now)
{
    voice(bell,     bellNote,     bellGate);
    voice(brass,    brassNote,    brassGate);
    voice(blow,     blowNote,     blowGate);
    voice(clarinet, clarinetNote, clarinetGate);
    voice(moog,     moogNote,     moogGate);
    voice(shaker,    shakerNote,    shakerGate);
    voice(bar,      barNote,      barGate);
}'
]

{ #category : 'code generation' }
MiniPhuck class >> zdSamplerCode [

	| turbo code |
	turbo := (FileLocator imageDirectory / 'TurboSamples') asFileReference asChuckPath.
	code := 'class ZdSampler extends Chugraph
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

"TURBO_ROOT" => string turbo;

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

60 => bleepNote;
60 => blipNote;
60 => bongoNote;
60 => chNote;
60 => clapNote;
60 => claveNote;
60 => congaNote;
60 => cowbellNote;
60 => crashNote;
60 => fx2Note;
60 => kickNote;
60 => ohNote;
60 => ravekickNote;
60 => rideNote;
60 => rimNote;
60 => shakerNote;
60 => snareNote;
60 => speakspellNote;
60 => tambNote;
60 => timbNote;
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
'.
	^ code copyReplaceAll: 'TURBO_ROOT' with: turbo
]
