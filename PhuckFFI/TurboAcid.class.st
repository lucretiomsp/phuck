Class {
	#name : 'TurboAcid',
	#superclass : 'TurboVoice',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboAcid class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
	^ 'class AcidCubic extends Chugen
{
    fun float tick(float in)
    {
        Math.max(-1.0, Math.min(1.0, in)) => float x;
        return x - (x * x * x) / 3.0;
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

    fun void tick(float note, float gate, float gain, float cutoff, float res,
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
        gain => out.gain;
    }
}'
]

{ #category : 'chuck code' }
TurboAcid >> chuckType [
	^ 'Acid'
]

{ #category : 'parameters' }
TurboAcid >> cutoff: aNumber [
	"default 0.3"
	self set: 'Cutoff' to: aNumber
]

{ #category : 'parameters' }
TurboAcid >> decay: aNumber [
	"default 0.282"
	self set: 'Decay' to: aNumber
]

{ #category : 'accessing' }
TurboAcid >> defaultName [
	^ 'acid'
]

{ #category : 'parameters' }
TurboAcid >> envMod: aNumber [
	"default 0.64"
	self set: 'EnvMod' to: aNumber
]

{ #category : 'chuck code' }
TurboAcid >> globals [
	^ { 'Note' -> 48. 'Gate' -> 0. 'Gain' -> 0.6. 'Cutoff' -> 0.3. 'Resonance' -> 4.5. 'EnvMod' -> 0.64. 'Decay' -> 0.282. 'Tuning' -> 0. 'Waveform' -> 0 }
]

{ #category : 'parameters' }
TurboAcid >> resonance: aNumber [
	"default 4.5"
	self set: 'Resonance' to: aNumber
]

{ #category : 'parameters' }
TurboAcid >> tuning: aNumber [
	"default 0"
	self set: 'Tuning' to: aNumber
]

{ #category : 'parameters' }
TurboAcid >> waveform: aNumber [
	"default 0"
	self set: 'Waveform' to: aNumber
]
