Class {
	#name : 'CkChainRunTest',
	#superclass : 'TestCase',
	#instVars : [
		'vm'
	],
	#category : 'Phuck-Tests-Lang',
	#package : 'Phuck-Tests',
	#tag : 'Lang'
}

{ #category : 'running' }
CkChainRunTest >> assertCompiles: aChain [
	"run: signals 'ChucK compile error' when ChucK rejects the code"
	| shred |
	shred := vm run: aChain asPhuck.
	self assert: shred id > 0.
	shred remove
]

{ #category : 'running' }
CkChainRunTest >> setUp [
	super setUp.
	vm := PhuckVM offline
]

{ #category : 'running' }
CkChainRunTest >> tearDown [
	vm releaseVM.
	super tearDown
]

{ #category : 'running' }
CkChainRunTest >> testGeneratedCodeCompiles [
	| delay |
	delay := CkDelay new.
	self
		assertCompiles: CkSqrOsc new => CkDac new;
		assertCompiles: (CkSqrOsc new freq: 330; sync: 1; gain: 1/2) => CkDac new;
		assertCompiles: (CkSqrOsc new gain: CkSlider new) => CkDac new;
		assertCompiles: delay => CkGain new => delay
]

{ #category : 'tests' }
CkChainRunTest >> testReadUGenCompiles [
	| lfo |
	lfo := CkSinOsc new freq: 0.5.
	self assertCompiles: (CkSinOsc new freq: 440 + (lfo last * 200)) => CkDac new
]

{ #category : 'running' }
CkChainRunTest >> testSliderGlobalIsRegistered [
	"so setValue:parameter: sends sqr1Gain as a float"
	(vm run: ((CkSqrOsc new gain: CkSlider new) => CkDac new) asPhuck) remove.
	self assert: (vm globals at: 'sqr1Gain') equals: #float
]
