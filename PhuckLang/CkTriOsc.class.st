"
A triangle wave oscillator.
"
Class {
	#name : 'CkTriOsc',
	#superclass : 'CkOsc',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'accessing' }
CkTriOsc >> width: aFloat [

"Set width of triangle wave (ratio of rise time to fall time).

"self param: #width put: aFloat 
]
