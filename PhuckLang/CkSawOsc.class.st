"
Sawtooth wave oscillator.
"
Class {
	#name : 'CkSawOsc',
	#superclass : 'CkOsc',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'accessing' }
CkSawOsc >> width: aFloat [

"Set width of triangle wave (ratio of rise time to fall time).

"self param: #width put: aFloat 
]
