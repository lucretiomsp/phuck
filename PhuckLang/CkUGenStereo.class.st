"
Base class for stereo unit generators.
"
Class {
	#name : 'CkUGenStereo',
	#superclass : 'CkUGenMulti',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'LiveCoding  - SuperDirt' }
CkUGenStereo >> pan: aFloat [ 
"Pan between left and right channels, in range [-1,1], with -1 being far-left, 1 far-right, and 0 centered."
	self param: #pan put: aFloat 
]

{ #category : 'LiveCoding  - SuperDirt' }
CkUGenStereo >> panType: aFloat [ 
"Set the panning type: (1) constant power panning, (0) unity gain anti-panning."
	self param: #panType put: aFloat 
]
