"
Base class for all Phuck unit generator (UGen) types.
"
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

{ #category : 'API' }
CkUGen >> gain: aValue [
	self param: #gain put: aValue
]

{ #category : 'initialization' }
CkUGen >> initialize [
	super initialize.
	params := OrderedDictionary new

]

{ #category : 'private' }
CkUGen >> param: aSymbol put: aValue [
	params at: aSymbol put: aValue
]

{ #category : 'accessing' }
CkUGen >> params [
	^ params
]
