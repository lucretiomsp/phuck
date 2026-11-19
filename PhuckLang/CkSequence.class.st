"
I am a param value that steps through a list of values in time, inside ChucK. Pharo is not needed while the program plays.

	m freq: (#(10 5 20 40) ckEvery: 1 second)

becomes a sporked shred holding the values in a ChucK array:

	fun void seq1() {
	  [10, 5, 20, 40] @=> int values[];
	  0 => int i;
	  while (1) {
	    values[i % values.size()] => m.freq;
	    i++;
	    1000::ms => now;
	  }
	}
	spork ~ seq1();

Unlike a CkShred, nothing is unrolled: long sequences stay one array. All-Integer values give an int array (so int params such as sync work), otherwise a float array.
"
Class {
	#name : 'CkSequence',
	#superclass : 'Object',
	#instVars : [
		'values',
		'period'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'instance creation' }
CkSequence class >> values: aCollection every: aDuration [
	"A param value playing aCollection in a loop, one value per aDuration:
		m freq: (CkSequence values: #(10 5 20 40) every: 1 second)"

	aCollection isEmpty ifTrue: [ ^ self error: 'A sequence needs at least one value' ].
	aDuration > Duration zero ifFalse: [ ^ self error: 'A sequence must wait between values, e.g. 100 milliSeconds' ].
	^ self new setValues: aCollection asArray period: aDuration
]

{ #category : 'ChucK' }
CkSequence >> ckArrayCode [
	"[10, 5, 20, 40] or [0.5, 2.0]: in a float array every element prints as a float"

	| elements |
	elements := self ckArrayType = 'int'
		            ifTrue: [ values ]
		            ifFalse: [ values collect: [ :each | each asFloat ] ].
	^ '[' , (', ' join: (elements collect: [ :each | each ckCode ])) , ']'
]

{ #category : 'ChucK' }
CkSequence >> ckArrayType [
	"ChucK ints stay ints, so an int param (sync) can be sequenced; anything else is a float array"

	^ (values allSatisfy: [ :each | each isInteger ])
		  ifTrue: [ 'int' ]
		  ifFalse: [ 'float' ]
]

{ #category : 'ChucK' }
CkSequence >> ckAssign: aSymbol to: aName in: aWriter [
	"Inside a CkShred a param can only take one value per statement"

	^ self error: 'A sequence plays on its own: set it outside CkShred blocks'
]

{ #category : 'printing' }
CkSequence >> ckPrefix [
	"Sequences are named seq1, seq2, ..."

	^ 'seq'
]

{ #category : 'ChucK' }
CkSequence >> ckWriteParam: aSymbol of: aName on: aWriter [
	"Double dispatch: a sequence changes its param in time, so it becomes a sporked shred"

	aWriter writeSequence: self param: aSymbol of: aName
]

{ #category : 'accessing' }
CkSequence >> period [
	"How long each value lasts"

	^ period
]

{ #category : 'initialization' }
CkSequence >> setValues: anArray period: aDuration [
	"The already checked values and step duration"

	values := anArray.
	period := aDuration
]

{ #category : 'accessing' }
CkSequence >> values [
	"The values, played in order and then again"

	^ values
]
