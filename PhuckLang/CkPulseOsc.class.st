"
A pulse width oscillator.
"
Class {
	#name : 'CkPulseOsc',
	#superclass : 'CkOsc',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'accessing' }
CkPulseOsc >> width: aFloat [

"Set width of triangle wave (ratio of rise time to fall time).

"self param: #width put: aFloat 
]
