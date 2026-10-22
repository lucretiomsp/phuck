Class {
	#name : 'CkChainTest',
	#superclass : 'TestCase',
	#instVars : [
		'dac'
	],
	#category : 'Phuck-Tests-Lang',
	#package : 'Phuck-Tests',
	#tag : 'Lang'
}

{ #category : 'tests' }
CkChainTest >> testSqrOscToDac [
	self
		assert: (CkSqrOsc new => dac) asPhuck
		equals: (String lf join: #(
			'SqrOsc sqr1 => dac;'
			'while (1) {'
			'  1::ms => now;'
			'}' ))
]
