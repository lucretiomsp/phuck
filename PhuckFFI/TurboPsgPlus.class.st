Class {
	#name : 'TurboPsgPlus',
	#superclass : 'TurboVoice',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboPsgPlus class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
	^ 'class PsgPlus extends Chugraph
{
    SqrOsc sqr => Gain mix => ADSR env => Gain vca => Gain out => outlet;
    SawOsc saw => mix;
    TriOsc tri => mix;
    SubNoise noise => BPF reson => mix;

    // pitch LFO: square in 0..1 as FM input, runs at audio rate inside the UGens
    Step one;
    1.0 => one.next;
    SqrOsc lfo => Gain lfoSum => Gain lfoAmt;
    one => lfoSum;
    lfoAmt => sqr;  lfoAmt => saw;  lfoAmt => tri;
    2 => sqr.sync;  2 => saw.sync;  2 => tri.sync;

    // ring modulator: envelope output times 1 - 0.3 * sine at 242 Hz
    SinOsc ringOsc => Gain ring => vca;
    one => ring;
    3 => vca.op;
    242.0 => ringOsc.freq;
    -0.3 => ringOsc.gain;

    second / samp => float sr;
    0.0 => float bandFreq;
    0 => float lastGate;

    fun void tick(float note, float gate, float gain, float index, float lfoAmount,
                  float dsFreq, float q, float a, float d, float s, float r)
    {
        Std.mtof(note) => float f;
        f => sqr.freq;
        f => saw.freq;
        f => tri.freq;
        f / 48.0 => lfo.freq;
        0.5 * lfoAmount * f => lfoAmt.gain;

        // 0 square, 1 saw, 2 triangle, 3 noise
        (Math.max(0.0, Math.min(3.0, index)) + 0.5) $ int => int i;
        (i == 0 ? 0.3 : 0.0) => sqr.gain;
        (i == 1 ? 0.3 : 0.0) => saw.gain;
        (i == 2 ? 0.3 : 0.0) => tri.gain;

        // noise: held at dsFreq, band at 3 x the LFO pitch smoothed like si.smoo,
        // BPF peaks at 1 and fi.resonbp at Q, hence the gain
        Math.max(1.0, sr / Math.max(20.0, dsFreq)) $ int => noise.rate;
        3.0 * f * (1.0 + lfoAmount * 0.5 * (lfo.last() + 1.0)) => float target;
        bandFreq + 0.0432 * (target - bandFreq) => bandFreq;
        Math.max(20.0, Math.min(18000.0, bandFreq)) => reson.freq;
        Math.max(1.0, q) => float res;
        res => reson.Q;
        (i == 3 ? res : 0.0) => reson.gain;

        gain => out.gain;
        if (gate == lastGate) return;
        if (gate > 0)
        {
            0.0 => env.value;   // restart from 0 like en.adsr
            env.set(a::second, d::second, s, r::second);
            env.keyOn();
        }
        else env.keyOff();
        gate => lastGate;
    }
}'
]

{ #category : 'parameters' }
TurboPsgPlus >> attack: aNumber [
	"default 0.01"
	self set: 'Attack' to: aNumber
]

{ #category : 'chuck code' }
TurboPsgPlus >> chuckType [
	^ 'PsgPlus'
]

{ #category : 'parameters' }
TurboPsgPlus >> decay: aNumber [
	"default 0.2"
	self set: 'Decay' to: aNumber
]

{ #category : 'accessing' }
TurboPsgPlus >> defaultName [
	^ 'psgPlus'
]

{ #category : 'parameters' }
TurboPsgPlus >> dsFreq: aNumber [
	"default 180"
	self set: 'DSFreq' to: aNumber
]

{ #category : 'chuck code' }
TurboPsgPlus >> globals [
	^ { 'Note' -> 60. 'Gate' -> 0. 'Gain' -> 0.25. 'Index' -> 0. 'LfoAmount' -> 0. 'DSFreq' -> 180. 'Q' -> 3. 'Attack' -> 0.01. 'Decay' -> 0.2. 'Sustain' -> 0.5. 'Release' -> 0.1 }
]

{ #category : 'parameters' }
TurboPsgPlus >> index: aNumber [
	"default 0"
	self set: 'Index' to: aNumber
]

{ #category : 'parameters' }
TurboPsgPlus >> lfoAmount: aNumber [
	"default 0"
	self set: 'LfoAmount' to: aNumber
]

{ #category : 'parameters' }
TurboPsgPlus >> q: aNumber [
	"default 3"
	self set: 'Q' to: aNumber
]

{ #category : 'parameters' }
TurboPsgPlus >> release: aNumber [
	"default 0.1"
	self set: 'Release' to: aNumber
]

{ #category : 'parameters' }
TurboPsgPlus >> sustain: aNumber [
	"default 0.5"
	self set: 'Sustain' to: aNumber
]
