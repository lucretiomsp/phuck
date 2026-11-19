Class {
	#name : 'TurboHoover',
	#superclass : 'TurboVoice',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboHoover class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
	^ 'class Hoover extends Chugraph
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

    fun void tick(float note, float gate, float gain)
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
        gain => out.gain;
        if (gate == lastGate) return;
        if (gate > 0) { ampEnv.keyOn();  pitchEnv.keyOn(); }
        else          { ampEnv.keyOff(); pitchEnv.keyOff(); }
        gate => lastGate;
    }
}'
]

{ #category : 'chuck code' }
TurboHoover >> chuckType [
	^ 'Hoover'
]

{ #category : 'accessing' }
TurboHoover >> defaultName [
	^ 'hoover'
]

{ #category : 'chuck code' }
TurboHoover >> globals [
	^ { 'Note' -> 60. 'Gate' -> 0. 'Gain' -> 0.3 }
]
