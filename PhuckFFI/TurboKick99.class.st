Class {
	#name : 'TurboKick99',
	#superclass : 'TurboVoice',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboKick99 class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
	^ 'class Kick99Clip extends Chugen
{
    fun float tick(float in)
    {
        Math.max(-1.0, Math.min(1.0, in)) => float x;
        return 1.5 * (x - (x * x * x) / 3.0);
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

    fun void tick(float note, float gate, float gain, float decay,
                  float pitchAmt, float pitchDecay, float click)
    {
        Std.mtof(note) => body.freq;
        pitchAmt => pAmt.gain;
        click    => clickAmp.gain;
        gain     => out.gain;
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
}'
]

{ #category : 'chuck code' }
TurboKick99 >> chuckType [
	^ 'Kick99'
]

{ #category : 'parameters' }
TurboKick99 >> click: aNumber [
	"default 0.3"
	self set: 'Click' to: aNumber
]

{ #category : 'parameters' }
TurboKick99 >> decay: aNumber [
	"default 0.1"
	self set: 'Decay' to: aNumber
]

{ #category : 'accessing' }
TurboKick99 >> defaultName [
	^ 'kick99'
]

{ #category : 'chuck code' }
TurboKick99 >> eventNote [

	^ (self parameter: 'Note') , ' - 12'
]

{ #category : 'chuck code' }
TurboKick99 >> globals [
	^ { 'Note' -> 33. 'Gate' -> 0. 'Gain' -> 0.4. 'Decay' -> 0.1. 'PitchAmt' -> 150. 'PitchDecay' -> 0.03. 'Click' -> 0.3 }
]

{ #category : 'parameters' }
TurboKick99 >> pitchAmt: aNumber [
	"default 150"
	self set: 'PitchAmt' to: aNumber
]

{ #category : 'parameters' }
TurboKick99 >> pitchDecay: aNumber [
	"default 0.03"
	self set: 'PitchDecay' to: aNumber
]

{ #category : 'chuck code' }
TurboKick99 >> tickArguments [
	"plays an octave below its note, as in the old TurboPhuck code"

	^ super tickArguments copy
		  at: 1 put: self eventNote;
		  yourself
]
