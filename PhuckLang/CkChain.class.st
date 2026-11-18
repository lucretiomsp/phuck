"
I am one ChucK line of connected UGens: osc => lpf => dac.

CkObject >> => creates me, and my own => appends and answers me, so a => b => c is a single chain. Writing a UGen that was already declared prints only its name, so a chain can close a feedback loop (delay => gain => delay) or reuse a UGen of another chain.

every: sets how often the main loop runs (default 1 ms):

	CkSinOsc new => CkDac new every: 100 milliSeconds
"
Class {
	#name : 'CkChain',
	#superclass : 'CkPart',
	#instVars : [
		'ugens',
		'period'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'connecting' }
CkChain >> => aUGen [
	"Append aUGen and answer the chain, so a => b => c stays one chain"

	ugens add: aUGen
]

{ #category : 'timing' }
CkChain >> ckPeriod [
	"The rate asked with every:, nil when none"

	^ period
]

{ #category : 'writing' }
CkChain >> ckWritePartOn: aWriter [
	"Visitor: a chain is written as one ChucK line"

	aWriter writeChain: ugens
]

{ #category : 'timing' }
CkChain >> every: aDuration [
	"Run the main loop every aDuration instead of every 1 ms: expressions and
	sliders are then updated at that rate. Answers the chain"

	period := aDuration
]

{ #category : 'initialization' }
CkChain >> initialize [
	"An empty chain; => fills it"

	super initialize.
	ugens := OrderedCollection new
]

{ #category : 'accessing' }
CkChain >> ugens [
	"The UGens in connection order"

	^ ugens
]
