Class {
	#name : 'CkChain',
	#superclass : 'Object',
	#instVars : [
		'ugens'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'initialization' }
CkChain >> => aUGen [
	ugens add: aUGen
]

{ #category : 'converting' }
CkChain >> asPhuck [
	^ CkGraphWriter new
		writeChain: ugens;
		contents
]

{ #category : 'initialization' }
CkChain >> initialize [
	super initialize.
	ugens := OrderedCollection new
]
