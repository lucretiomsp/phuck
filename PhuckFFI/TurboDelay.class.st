"
I am the delay on an aux bus of the rig: delayBus => DelayL => LPF (in the feedback too, each repeat darker) => return => master. I am at most one second long.

```language=Pharo
	TurboDelay default spork.
	TurboDelay default time: 0.375; feedback: 0.5; tone: 2500; returnLevel: 0.6.
	(TurboPhuckRig default at: 'acid') send: 0.3 to: 'delay'.
```
My ranges are the ones of my knobs (TurboPhuck>>displayMasterUI, TurboPhuckDisplay) and my ChucK clamps them too:
- delayTime: seconds, 0.01 to 1
- delayFeedback: 0 one repeat, at most 0.95
- delayTone: low-pass cutoff of the repeats, 200 to 12000 Hz
- delayReturn: level back into the master, 0 to 1
"
Class {
	#name : 'TurboDelay',
	#superclass : 'TurboAux',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'accessing' }
TurboDelay >> defaultName [

	^ 'delay'
]

{ #category : 'parameters' }
TurboDelay >> feedback: aNumber [

	self set: 'Feedback' to: aNumber
]

{ #category : 'chuck code' }
TurboDelay >> globals [

	^ {
		  ('Time' -> 0.375).
		  ('Feedback' -> 0.45).
		  ('Tone' -> 3000.0).
		  ('Return' -> 0.6) }
]

{ #category : 'chuck code' }
TurboDelay >> graphCode [
	"the delay line is as long as the longest time"

	^ 'in => DelayL d => LPF tone => Gain ret => master;
tone => Gain fb => d;
' , (self maxOf: 'Time') printString , '::second => d.max;'
]

{ #category : 'chuck code' }
TurboDelay >> ranges [

	^ Dictionary new
		  at: 'Time' put: #( 0.01 1.0 0.01 );
		  at: 'Feedback' put: #( 0.0 0.95 0.01 );
		  at: 'Tone' put: #( 200.0 12000.0 10 );
		  at: 'Return' put: #( 0.0 1.0 0.01 );
		  yourself
]

{ #category : 'chuck code' }
TurboDelay >> tickCode [

	^ (self clamped: 'Time') , '::second => d.delay;
' , (self clamped: 'Feedback') , ' => fb.gain;
' , (self clamped: 'Tone') , ' => tone.freq;
' , (self clamped: 'Return') , ' => ret.gain;'
]

{ #category : 'parameters' }
TurboDelay >> time: seconds [
	"the delay time, at most one second"

	self set: 'Time' to: seconds
]

{ #category : 'parameters' }
TurboDelay >> tone: aFrequency [
	"the low-pass cutoff of the repeats, in Hz"

	self set: 'Tone' to: aFrequency
]
