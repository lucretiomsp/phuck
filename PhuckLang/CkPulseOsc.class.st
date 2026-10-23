"
A pulse width oscillator.
"
Class {
	#name : 'CkPulseOsc',
	#superclass : 'CkOsc',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'accessing' }
CkPulseOsc >> width: aFloat [

"Set width of triangle wave (ratio of rise time to fall time).

"self param: #width put: aFloat 
]
