Class {
	#name : 'CkUGen',
	#superclass : 'CkObject',
	#instVars : [
		'inputs',
		'outputs',
		'params'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'as yet unclassified' }
CkUGen >> gain: aValue [
	self param: #gain put: aValue
]

{ #category : 'initialization' }
CkUGen >> initialize [
	super initialize.
	params := OrderedDictionary new

]

{ #category : 'as yet unclassified' }
CkUGen >> param: aSymbol put: aValue [
	params at: aSymbol put: aValue
]

{ #category : 'as yet unclassified' }
CkUGen >> params [
	^ params
]
