Class {
	#name : 'TurboChordy',
	#superclass : 'TurboVoice',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboChordy class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
	^ 'class Chordy extends Chugraph
{
    // filter built like fi.resonlp: poles, zeros, then its gain ramped at audio rate.
    // LPF scales its input instead and loses the pop when the cutoff opens
    SawOsc v1 => Gain mix => TwoPole poles => TwoZero zeros => Gain vca => ADSR ampEnv => Gain out => outlet;
    SawOsc v2 => mix;
    SawOsc v3 => mix;
    Step one => ADSR filterEnv => blackhole;
    one => Envelope filterGain => vca;
    3 => vca.op;

    1.0 => one.next;
    1.0 => zeros.b0;  2.0 => zeros.b1;  1.0 => zeros.b2;
    1::ms => filterGain.duration;
    0.25 => v1.gain;  0.25 => v2.gain;  0.5 => v3.gain;

    // start on the saw jump like the Faust phasors: the fifth stays phase locked to the root
    0.75 => v1.phase;  0.75 => v2.phase;  0.75 => v3.phase;

    // second voice as a ratio to the root: minor, major, sus4, sus2
    [1.189, 1.259, 1.333, 1.125] @=> float intervals[];

    second / samp => float sr;
    0.0 => float cut;
    0 => float lastGate;

    fun void tick(float note, float gate, float gain, float mode, float cutoff,
                  float a, float d, float s, float r)
    {
        Std.mtof(note) => float f;
        f => v1.freq;
        f * intervals[(Math.max(0.0, Math.min(3.0, mode)) + 0.5) $ int] => v2.freq;
        f * 1.5 => v3.freq;

        // cutoff smoothed like si.smoo, Q 4.8, coefficients as in tf2s
        202.0 * cutoff + filterEnv.last() * 2000.0 => float target;
        cut + 0.0432 * (target - cut) => cut;
        1.0 / Math.tan(pi * Math.max(20.0, Math.min(18000.0, cut)) / sr) => float k;
        k * k => float k2;
        1.0 / (1.0 + k / 4.8 + k2) => float n;
        2.0 * (1.0 - k2) * n => poles.a1;
        (1.0 - k / 4.8 + k2) * n => poles.a2;
        n => filterGain.target;

        gain => out.gain;
        if (gate == lastGate) return;
        if (gate > 0)
        {
            0.0 => ampEnv.value;   // restart from 0 like en.adsr
            0.0 => filterEnv.value;
            ampEnv.set(a::second, d::second, s, r::second);
            filterEnv.set(a::second, d::second, 0.0, r::second);
            ampEnv.keyOn();
            filterEnv.keyOn();
        }
        else
        {
            ampEnv.keyOff();
            filterEnv.keyOff();
        }
        gate => lastGate;
    }
}'
]

{ #category : 'parameters' }
TurboChordy >> attack: aNumber [
	"default 0.01"
	self set: 'Attack' to: aNumber
]

{ #category : 'chuck code' }
TurboChordy >> chuckType [
	^ 'Chordy'
]

{ #category : 'parameters' }
TurboChordy >> cutoff: aNumber [
	"default 0.2"
	self set: 'Cutoff' to: aNumber
]

{ #category : 'parameters' }
TurboChordy >> decay: aNumber [
	"default 0.21"
	self set: 'Decay' to: aNumber
]

{ #category : 'accessing' }
TurboChordy >> defaultName [
	^ 'chordy'
]

{ #category : 'chuck code' }
TurboChordy >> globals [
	^ { 'Note' -> 60. 'Gate' -> 0. 'Gain' -> 0.45. 'Mode' -> 0. 'Cutoff' -> 0.2. 'Attack' -> 0.01. 'Decay' -> 0.21. 'Sustain' -> 0.9. 'Release' -> 0.18 }
]

{ #category : 'parameters' }
TurboChordy >> mode: aNumber [
	"default 0"
	self set: 'Mode' to: aNumber
]

{ #category : 'parameters' }
TurboChordy >> release: aNumber [
	"default 0.18"
	self set: 'Release' to: aNumber
]

{ #category : 'parameters' }
TurboChordy >> sustain: aNumber [
	"default 0.9"
	self set: 'Sustain' to: aNumber
]
