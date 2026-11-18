"
I am the Composite component of a Phuck program. My leaves are CkChain (a line of UGens) and CkShred (a sequence in time); CkProgram is the composite holding parts, including other programs.

	(osc => lpf => CkDac new) , (CkShred loop: [ :t | ... ])

, joins two parts into a new CkProgram. asPhuck turns any part into a complete ChucK program. The writer is visited with double dispatch: ckWritePartOn: sends the writer the right writeXxx:.

ckPeriod is the main-loop rate a part asks for (nil = no preference).
"
Class {
	#name : 'CkPart',
	#superclass : 'Object',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'combining' }
CkPart >> , aPart [
	"Play two parts in one program: chain , chain, chain , shred, ...
	The result is a new CkProgram; neither part is changed"

	^ CkProgram new
		  add: self;
		  add: aPart;
		  yourself
]

{ #category : 'converting' }
CkPart >> asPhuck [
	"The ChucK source of this part as a whole program, ready for PhuckVM >> run:"

	| writer |
	writer := CkGraphWriter new period: self ckEffectivePeriod.
	self ckWritePartOn: writer.
	^ writer contents
]

{ #category : 'timing' }
CkPart >> ckEffectivePeriod [
	"The rate the main loop will really use"

	^ self ckPeriod ifNil: [ CkGraphWriter defaultPeriod ]
]

{ #category : 'timing' }
CkPart >> ckPeriod [
	"The loop rate this part asks for, nil when it does not care"

	^ nil
]

{ #category : 'writing' }
CkPart >> ckWritePartOn: aWriter [
	"Visit aWriter with the right writeXxx: (double dispatch)"

	self subclassResponsibility
]
