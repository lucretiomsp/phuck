"
I am the composite of the Composite pattern: several parts (chains, shreds, programs) written by a single CkGraphWriter, so a UGen used by two chains is declared once and gets one name.

	(lfo => a => CkDac new) , (lfo => b => CkDac new)

The main loop runs every: my explicit period, or else the fastest period one of my parts asked for, or else 1 ms.
"
Class {
	#name : 'CkProgram',
	#superclass : 'CkPart',
	#instVars : [
		'parts',
		'period'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'building' }
CkProgram >> add: aPart [
	"Programs are composites: a part may itself be a program"

	parts add: aPart
]

{ #category : 'timing' }
CkProgram >> ckPeriod [
	"An explicit every: wins; otherwise the fastest rate any part asked for"

	^ period ifNil: [ self fastestPartPeriod ]
]

{ #category : 'writing' }
CkProgram >> ckWritePartOn: aWriter [
	"All parts share aWriter, so a UGen used by two chains is declared once"

	parts do: [ :each | each ckWritePartOn: aWriter ]
]

{ #category : 'timing' }
CkProgram >> every: aDuration [
	"Force the loop rate of the whole program. Answers the program"

	period := aDuration
]

{ #category : 'timing' }
CkProgram >> fastestPartPeriod [
	"The shortest period any part asked for, nil when none did"

	^ (parts collect: [ :each | each ckPeriod ] thenReject: [ :each | each isNil ])
		  ifEmpty: [ nil ]
		  ifNotEmpty: [ :periods | periods min ]
]

{ #category : 'initialization' }
CkProgram >> initialize [
	"An empty program; , and add: fill it"

	super initialize.
	parts := OrderedCollection new
]

{ #category : 'accessing' }
CkProgram >> parts [
	"Chains, shreds and nested programs, in writing order"

	^ parts
]
