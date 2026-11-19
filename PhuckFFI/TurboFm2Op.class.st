Class {
	#name : 'TurboFm2Op',
	#superclass : 'TurboVoice',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboFm2Op class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
	^ 'class Fm2Op extends Chugraph
{
    SinOsc modulator => SinOsc carrier => ADSR env => Gain out => outlet;
    2 => carrier.sync;

    0 => float lastGate;

    fun void tick(float note, float gate, float gain, float modIndex, float modRatio,
                  float a, float r)
    {
        Std.mtof(note) => float f;
        f => carrier.freq;
        f * modRatio => modulator.freq;
        modIndex * 70.0 => modulator.gain;
        gain => out.gain;
        if (gate == lastGate) return;
        if (gate > 0)
        {
            0.0 => env.value;   // restart from 0 like en.adsr
            env.set(a::second, 1::ms, 1.0, r::second);
            env.keyOn();
        }
        else env.keyOff();
        gate => lastGate;
    }
}'
]

{ #category : 'parameters' }
TurboFm2Op >> attack: aNumber [
	"default 0.01"
	self set: 'Attack' to: aNumber
]

{ #category : 'chuck code' }
TurboFm2Op >> chuckType [
	^ 'Fm2Op'
]

{ #category : 'accessing' }
TurboFm2Op >> defaultName [
	^ 'fm2Op'
]

{ #category : 'chuck code' }
TurboFm2Op >> globals [
	^ { 'Note' -> 60. 'Gate' -> 0. 'Gain' -> 0.25. 'ModIndex' -> 0. 'ModRatio' -> 1. 'Attack' -> 0.01. 'Release' -> 0.1 }
]

{ #category : 'parameters' }
TurboFm2Op >> modIndex: aNumber [
	"default 0"
	self set: 'ModIndex' to: aNumber
]

{ #category : 'parameters' }
TurboFm2Op >> modRatio: aNumber [
	"default 1"
	self set: 'ModRatio' to: aNumber
]

{ #category : 'parameters' }
TurboFm2Op >> release: aNumber [
	"default 0.1"
	self set: 'Release' to: aNumber
]
