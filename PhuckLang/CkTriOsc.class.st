"
A triangle wave oscillator.
"
Class {
	#name : 'CkTriOsc',
	#superclass : 'CkOsc',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'accessing' }
CkTriOsc >> width: aFloat [

"Set width of triangle wave (ratio of rise time to fall time).

"self param: #width put: aFloat 
]
