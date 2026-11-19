"
I am the master bus of the rig: global Gain master => PitShift => ZdHighPass => Dyno => dac, with the globals masterGain, pitchShift, highpassFreq and performanceBPM of the old TurboPhuck code.

```language=Pharo
	TurboMaster default play.
	TurboMaster default gain: 0.6; highpassFreq: 300; bpm: 140.
```
"
Class {
	#name : 'TurboMaster',
	#superclass : 'TurboModule',
	#classInstVars : [
		'default'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboMaster class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
	^ '// same response as HPF, but on BiQuad: at low cutoffs HPF keeps a state thousands of
// times louder than the signal, so any cutoff change there comes out as a click.
// the cutoff also glides, because the knob moves it in big steps
class ZdHighPass extends Chugraph
{
    inlet => BiQuad filter => outlet;
    second / samp => float sr;
    0.0 => float current;
    1.0 => float res;

    fun float Q(float q)
    {
        Math.max(1.0, q) => res;
        if (current > 0.0) setCoefficients();
        return res;
    }

    fun float freq(float f)
    {
        Math.max(20.0, Math.min(20000.0, f)) => float target;
        if (target == current) return current;

        // the first call jumps, then about 80 ms from 20 Hz to 20 kHz
        if (current == 0.0) target => current;
        else current * Math.pow(target / current, 0.05) => current;
        if (Math.fabs(target / current - 1.0) < 0.001) target => current;

        setCoefficients();
        return current;
    }

    // the same coefficients as HPF
    fun void setCoefficients()
    {
        2.0 * pi * current / sr => float w;
        Math.tan(w / res * 0.5) => float d;
        (1.0 - d) / (1.0 + d) => float c;
        (1.0 + c) * Math.cos(w) => float b;
        (1.0 + c + b) * 0.25 => float g;
        g => filter.b0;
        -2.0 * g => filter.b1;
        g => filter.b2;
        -b => filter.a1;
        c => filter.a2;
    }
}'
]

{ #category : 'instance creation' }
TurboMaster class >> default [
	"the one master bus of the VM"

	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
TurboMaster class >> reset [

	default := nil
]

{ #category : 'parameters' }
TurboMaster >> bpm: aNumber [

	self vm setValue: aNumber parameter: 'performanceBPM'
]

{ #category : 'chuck code' }
TurboMaster >> code [
	"the master bus every voice plays into, a global Gain shared by all shreds"

	^ '0.8 => global float masterGain;
1 => global float pitchShift;
20.0 => global float highpassFreq;
174 => global float performanceBPM;

global Gain master => PitShift shifter => ZdHighPass highPass => Dyno lim => dac;
1 => shifter.mix;
2.6 => highPass.Q;
lim.limit();

while (1::ms => now)
{
    masterGain => master.gain;
    pitchShift => shifter.shift;
    highpassFreq => highPass.freq;
}'
]

{ #category : 'parameters' }
TurboMaster >> gain: aNumber [

	self vm setValue: aNumber parameter: 'masterGain'
]

{ #category : 'parameters' }
TurboMaster >> highpassFreq: aNumber [

	self vm setValue: aNumber parameter: 'highpassFreq'
]

{ #category : 'parameters' }
TurboMaster >> pitchShift: aNumber [

	self vm setValue: aNumber parameter: 'pitchShift'
]

{ #category : 'chuck code' }
TurboMaster >> prepare [

	TurboLibrary default play
]
