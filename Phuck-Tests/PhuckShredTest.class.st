Class {
	#name : 'PhuckShredTest',
	#superclass : 'TestCase',
	#instVars : [
		'vm'
	],
	#category : 'Phuck-Tests-Core',
	#package : 'Phuck-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
PhuckShredTest >> setUp [
	super setUp.
	vm := PhuckVM offline
]

{ #category : 'helpers' }
PhuckShredTest >> sineCode [
	^ 'SinOsc s => dac; 0.2 => s.gain; 1::day => now;'
]

{ #category : 'running' }
PhuckShredTest >> tearDown [
	vm releaseVM.
	super tearDown
]

{ #category : 'tests' }
PhuckShredTest >> testNewShredIsNotRemoved [
	| shred |
	shred := vm run: self sineCode.
	self deny: shred isRemoved
]

{ #category : 'tests' }
PhuckShredTest >> testPrintOn [
	| shred |
	shred := vm run: self sineCode.
	self assert: shred printString equals: 'PhuckShred(' , shred id printString , ')'
]

{ #category : 'tests' }
PhuckShredTest >> testRemove [
	| shred |
	shred := vm run: self sineCode.
	self assert: shred remove.
	self assert: shred isRemoved
]

{ #category : 'tests' }
PhuckShredTest >> testRemoveTwiceIsHarmless [
	| shred |
	shred := vm run: self sineCode.
	shred remove.
	self deny: shred remove
]

{ #category : 'tests' }
PhuckShredTest >> testReplaceKeepsIdentity [
	| shred oldId |
	shred := vm run: self sineCode.
	oldId := shred id.
	shred replace: self triCode.
	self deny: shred id equals: oldId.
	self assert: shred source equals: self triCode.
	self deny: shred isRemoved
]

{ #category : 'tests' }
PhuckShredTest >> testReplaceWithBadCodeKeepsOldShred [
	| shred oldId |
	shred := vm run: self sineCode.
	oldId := shred id.
	self should: [ shred replace: 'not chuck' ] raise: Error.
	self assert: shred id equals: oldId.
	self assert: shred source equals: self sineCode
]

{ #category : 'tests' }
PhuckShredTest >> testResporkAfterRemove [
	| shred |
	shred := vm run: self sineCode.
	shred
		remove;
		respork.
	self deny: shred isRemoved
]

{ #category : 'helpers' }
PhuckShredTest >> triCode [
	^ 'TriOsc t => dac; 0.2 => t.gain; 1::day => now;'
]
