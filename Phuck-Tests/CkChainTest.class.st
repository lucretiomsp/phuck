Class {
	#name : 'CkChainTest',
	#superclass : 'TestCase',
	#category : 'Phuck-Tests-Lang',
	#package : 'Phuck-Tests',
	#tag : 'Lang'
}

{ #category : 'asserting' }
CkChainTest >> assert: aChain generates: lines [
	self assert: aChain asPhuck equals: (String lf join: lines)
]

{ #category : 'tests' }
CkChainTest >> testOperatorsKeepPharoOrder [
	"Pharo reads 1 + x * 2 as (1 + x) * 2"
	self
		assert: ((1 + CkSinOsc new last * 2) ckCodeIn: CkGraphWriter new)
		equals: '(1 + sin1.last()) * 2'

]

{ #category : 'tests' }
CkChainTest >> testReadUGenInLoop [
	| lfo osc |
	lfo := CkSinOsc new freq: 0.5.
	osc := CkSinOsc new freq: 440 + (lfo last * 200).
	self
		assert: osc => CkDac new
		generates: #(
			'SinOsc sin1 => dac;'
			'SinOsc sin2 => blackhole;'
			'0.5 => sin2.freq;'
			'while (1) {'
			'  440 + (sin2.last() * 200) => sin1.freq;'
			'  1::ms => now;'
			'}' )
]

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
