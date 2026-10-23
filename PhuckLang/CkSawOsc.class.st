"
Sawtooth wave oscillator.
"
Class {
	#name : 'CkSawOsc',
	#superclass : 'CkOsc',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'accessing' }
CkSawOsc >> width: aFloat [

"Set width of triangle wave (ratio of rise time to fall time).

"self param: #width put: aFloat 
]
