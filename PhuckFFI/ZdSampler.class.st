"
I play the one-shots of a folder: index picks the file, note 60 plays it at its own pitch, a new note while the gate is on triggers it again. See ZdPlayer.
"
Class {
	#name : 'ZdSampler',
	#superclass : 'ZdPlayer',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
ZdSampler class >> chuckClass [
	"the ChucK class I run, it uses ZdFiles"
	^ '// ===================== SAMPLER =====================
// one folder of one-shots: index picks the file, note 60 plays it at its own pitch,
// a new note while the gate is on triggers again
class ZdSampler extends Chugraph
{
    SndBuf buf => ADSR env => Gain out => outlet;
    env.set(1::ms, 380::ms, 1.0, 120::ms);
    0.4 => buf.gain;

    string dir;
    string files[0];
    -1 => int lastIndex;
    -1.0 => float lastNote;
    0 => int lastGate;

    fun ZdSampler(string folder)
    {
        ZdFiles.slash(folder) => dir;
        ZdFiles.audio(folder) @=> files;
    }

    fun void tick(float note, float gate, float gain, float index)
    {
        gain => buf.gain;
        if (files.size() == 0) return;

        ZdFiles.wrap(index, files.size()) => int i;
        if (i != lastIndex)
        {
            dir + files[i] => buf.read;
            i => lastIndex;
            (lastGate ? 0 : buf.samples()) => buf.pos;   // silent until the next gate
        }
        Math.pow(2.0, (note - 60) / 12.0) => buf.rate;

        (gate > 0) => int on;
        if (note != lastNote)
        {
            note => lastNote;
            if (on && lastGate) { 0 => buf.pos; env.keyOn(); }
        }
        if (on == lastGate) return;
        if (on) { 0 => buf.pos; env.keyOn(); }
        else    env.keyOff();
        on => lastGate;
    }
}
'
]
