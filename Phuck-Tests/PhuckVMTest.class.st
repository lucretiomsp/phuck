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
PhuckVMTest >> testNewIsBlocked [
	self should: [ PhuckVM new ] raise: Error
]

{ #category : 'tests' }
PhuckVMTest >> testOfflineIsRunningWithoutAudio [
	self assert: vm isRunning.
	self deny: vm isAudioRunning
]
