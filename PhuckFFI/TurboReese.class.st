Class {
	#name : 'TurboReese',
	#superclass : 'TurboVoice',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboReese class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
	^ 'class Reese extends Chugraph
{
    SinOsc o1 => Gain mix => ADSR env => Gain out => outlet;
    SinOsc o2 => mix;
    0.3 => o1.gain;  0.3 => o2.gain;
    0 => float lastGate;

    fun void tick(float note, float gate, float gain, float detune,
                  float a, float d, float s, float r)
    {
        Std.mtof(note) => float f;
        f => o1.freq;
        f + detune => o2.freq;
        gain => out.gain;
        if (gate == lastGate) return;
        if (gate > 0)
        {
            env.set(a::second, d::second, s, r::second);
            env.keyOn();
        }
        else env.keyOff();
        gate => lastGate;
    }
}'
]

{ #category : 'parameters' }
TurboReese >> attack: aNumber [
	"default 0.01"
	self set: 'Attack' to: aNumber
]

{ #category : 'chuck code' }
TurboReese >> chuckType [
	^ 'Reese'
]

{ #category : 'parameters' }
TurboReese >> decay: aNumber [
	"default 0.2"
	self set: 'Decay' to: aNumber
]

{ #category : 'accessing' }
TurboReese >> defaultName [
	^ 'reese'
]

{ #category : 'parameters' }
TurboReese >> detune: aNumber [
	"default 2"
	self set: 'Detune' to: aNumber
]

{ #category : 'chuck code' }
TurboReese >> globals [
	^ { 'Note' -> 48. 'Gate' -> 0. 'Gain' -> 0.5. 'Detune' -> 2. 'Attack' -> 0.01. 'Decay' -> 0.2. 'Sustain' -> 0.5. 'Release' -> 0.1 }
]

{ #category : 'parameters' }
TurboReese >> release: aNumber [
	"default 0.1"
	self set: 'Release' to: aNumber
]

{ #category : 'parameters' }
TurboReese >> sustain: aNumber [
	"default 0.5"
	self set: 'Sustain' to: aNumber
]
