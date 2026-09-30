Class {
	#name : 'PhuckVMTest',
	#superclass : 'TestCase',
	#instVars : [
		'vm'
	],
	#category : 'Phuck-Tests-Core',
	#package : 'Phuck-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
PhuckVMTest >> setUp [
	super setUp.
	vm := PhuckVM offline
]

{ #category : 'helpers' }
PhuckVMTest >> sineCode [
	^ 'global float freq; 220 => freq; SinOsc s => dac; 0.2 => s.gain;
while (true) { freq => s.freq; 10::ms => now; }'
]

{ #category : 'running' }
PhuckVMTest >> tearDown [
	vm releaseVM.
	super tearDown
]

{ #category : 'tests' }
PhuckVMTest >> testBootVMTwiceIsHarmless [
	vm bootVM.
	self assert: vm isRunning
]

{ #category : 'tests' }
PhuckVMTest >> testChuckIsPhuckPointer [
	self assert: (vm instVarNamed: 'chuck') class equals: PhuckPointer
]

{ #category : 'tests' }
PhuckVMTest >> testCompileErrorSignals [
	self should: [ vm run: 'this is not chuck' ] raise: Error
]

{ #category : 'tests' }
PhuckVMTest >> testNewIsBlocked [
	self should: [ PhuckVM new ] raise: Error
]

{ #category : 'tests' }
PhuckVMTest >> testOfflineIsRunningWithoutAudio [
	self assert: vm isRunning.
	self deny: vm isAudioRunning
]

{ #category : 'tests' }
PhuckVMTest >> testReleaseVM [
	vm releaseVM.
	self deny: vm isRunning
]

{ #category : 'tests' }
PhuckVMTest >> testReleaseVMTwiceIsHarmless [
	vm
		releaseVM;
		releaseVM.
	self deny: vm isRunning
]

{ #category : 'tests' }
PhuckVMTest >> testRunOnReleasedVMSignals [
	vm releaseVM.
	self should: [ vm run: self sineCode ] raise: Error
]

{ #category : 'tests' }
PhuckVMTest >> testRunRegistersGlobalTypes [
	vm run: self sineCode.
	self
		assert: (vm globalTypeOf: 'freq' ifAbsent: [ nil ])
		equals: #float
]

{ #category : 'tests' }
PhuckVMTest >> testRunTwiceGivesDifferentIds [
	| first second |
	first := vm run: self sineCode.
	second := vm run: self sineCode.
	self deny: first id equals: second id
]

{ #category : 'tests' }
PhuckVMTest >> testSetValueDoesNotFail [

	vm run: self sineCode.
	vm setValue: 440 parameter: 'freq'
]

{ #category : 'tests' }
PhuckVMTest >> testSetValueOnReleasedVMSignals [
	vm releaseVM.
	self should: [ vm setValue: 440 parameter: 'freq' ] raise: Error
]
