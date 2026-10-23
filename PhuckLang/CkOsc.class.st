"
Base class for simple oscillator unit generators.
"
Class {
	#name : 'CkOsc',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'API' }
CkOsc >> freq: aFloat [ 
"Set frequency of oscillator in Hertz; maintains phase"
	self param: #freq put: aFloat 
]

{ #category : 'API' }
CkOsc >> period: aFloat [ 
"Set period of oscillator (inverse of frequency)."
	self param: #period put: aFloat 
]

{ #category : 'API' }
CkOsc >> phase: aFloat [ 
"Set oscillator phase, in range [0,1)."
	self param: #period put: aFloat 
]

{ #category : 'API' }
CkOsc >> sfreq: aFloat [ 
"Set frequency of oscillator in Hertz; resets phase to 0"
	self param: #sfreq put: aFloat 
]

{ #category : 'API' }
CkOsc >> sync: anInt [ 
"Choose how to interpret input: (0) sync frequency to input; (1) sync phase to input; (2) frequency modulation (add input to internal frequency).

"
	self param: #sync put: anInt 
]
