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
	^ self new setUGen: aUGen selector: aSymbol

]

{ #category : 'as yet unclassified' }
CkGetter >> ckCodeIn: aWriter [
	^ (aWriter nameOf: ugen) , '.' , selector , '()'
]

{ #category : 'initialization' }
CkGetter >> setUGen: aUGen selector: aSymbol [
	ugen := aUGen.
	selector := aSymbol
]
