"
I am a read of a UGen value: lfo last -> sin2.last(). If the UGen is not in any chain, the writer declares it on blackhole so it still ticks.
"
Class {
	#name : 'CkGetter',
	#superclass : 'CkExpr',
	#instVars : [
		'ugen',
		'selector'
	],
	#category : 'PhuckLang-Expressions',
	#package : 'PhuckLang',
	#tag : 'Expressions'
}

{ #category : 'as yet unclassified' }
CkGetter class >> ugen: aUGen selector: aSymbol [
	"A read of aUGen.aSymbol()"

	^ self new setUGen: aUGen selector: aSymbol
]

{ #category : 'as yet unclassified' }
CkGetter >> ckCodeIn: aWriter [
	"sin2.last(); the writer declares the UGen on blackhole if nothing else did"

	^ (aWriter nameOf: ugen) , '.' , selector , '()'
]

{ #category : 'initialization' }
CkGetter >> setUGen: aUGen selector: aSymbol [
	"aSymbol is the ChucK method read, such as last"

	ugen := aUGen.
	selector := aSymbol
]
