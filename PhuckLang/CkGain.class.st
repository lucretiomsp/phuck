"
A gain control unit generator. (All unit generators can already change their own gain; this is an explicit way to add multiple outputs together and scale them.)
"
Class {
	#name : 'CkGain',
	#superclass : 'CkUGen',
	#instVars : [
		'db'
	],
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'accessing' }
CkGain >> db [ 
^ db
]

{ #category : 'accessing' }
CkGain >> db: aGainInDB [ 

db := aGainInDB 
]
