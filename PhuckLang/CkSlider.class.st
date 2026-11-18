"
I am a value that Pharo can change while the program runs. Used as a param, I become a ChucK global float copied into the param on every loop iteration; set it from Pharo with PhuckVM >> setValue:parameter:.

	osc gain: CkSlider new                     -> global float sqr1Gain; (or myOscGain for a labelled osc)
	osc gain: (CkSlider label: 'justGain')     -> global float justGain;

One slider may drive several params: its global is declared once.
"
Class {
	#name : 'CkSlider',
	#superclass : 'Object',
	#instVars : [
		'label'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'instance creation' }
CkSlider class >> label: aString [
	"A slider whose ChucK global is called aString, whatever param it drives:
		osc gain: (CkSlider label: 'justGain')
	gives global float justGain;"

	^ self new setLabel: (CkObject checkIdentifier: aString)
]

{ #category : 'printing' }
CkSlider >> ckAssign: aSymbol to: aName in: aWriter [
	"Declare the global (once per program) and copy it into the param:
	global float sqr1Gain; ... sqr1Gain => sqr1.gain;"

	| global |
	global := self globalNameFor: aSymbol of: aName.
	aWriter addGlobal: 'global float ' , global , ';'.
	^ global , ' => ' , aName , '.' , aSymbol , ';'
]

{ #category : 'printing' }
CkSlider >> ckWriteParam: aSymbol of: aName on: aWriter [
	"The global can change at any time from Pharo, so it is copied every loop"

	aWriter addToLoop: (self ckAssign: aSymbol to: aName in: aWriter)
]

{ #category : 'printing' }
CkSlider >> globalNameFor: aSymbol of: aName [
	"My label, or UGen name + param: #gain of sqr1 -> sqr1Gain"

	^ label ifNil: [ aName , aSymbol capitalized ]
]

{ #category : 'accessing' }
CkSlider >> label [
	"The global name chosen with label:, nil when it is derived from the UGen"

	^ label
]

{ #category : 'initialization' }
CkSlider >> setLabel: aString [
	"The already checked name of my global"

	label := aString
]
