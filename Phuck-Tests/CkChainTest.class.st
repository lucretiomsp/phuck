Class {
	#name : 'CkChainTest',
	#superclass : 'TestCase',
	#category : 'Phuck-Tests-Lang',
	#package : 'Phuck-Tests',
	#tag : 'Lang'
}

{ #category : 'tests' }
CkChainTest >> testSliderBecomesGlobal [
	| osc |
	osc := CkSqrOsc new.
	osc gain: CkSlider new.
	self
		assert: (osc => CkDac new) asPhuck
		equals: (String lf join: #(
			'global float sqr1Gain;'
			'SqrOsc sqr1 => dac;'
			'while (1) {'
			'  sqr1Gain => sqr1.gain;'
			'  1::ms => now;'
			'}' ))
]

{ #category : 'tests' }
CkChainTest >> testSqrOscToDac [

	self
		assert: (CkSqrOsc new => CkDac new) asPhuck
		equals: (String lf join: #( 'SqrOsc sqr1 => dac;' 'while (1) {' '  1::ms => now;' '}' ))
]
