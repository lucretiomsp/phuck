"
Base class for basic filters with a notion of center/cutoff frequency and Q.
"
Class {
	#name : 'CkFilterBasic',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-Filters',
	#package : 'PhuckLang',
	#tag : 'Filters'
}

{ #category : 'trait' }
CkFilterBasic >> freq: aValue [
	self param: #freq put: aValue
]

{ #category : 'trait' }
CkFilterBasic >> q: aValue [
	self param: #q put: aValue
]
