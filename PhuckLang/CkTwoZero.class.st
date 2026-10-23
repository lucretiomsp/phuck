"
This Filter subclass implements a two-zero digital filter. A method is provided for creating a 'notch' in the frequency response while maintaining a constant filter gain. by Perry R. Cook and Gary P. Scavone, 1995 - 2002.
"
Class {
	#name : 'CkTwoZero',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-Filters',
	#package : 'PhuckLang',
	#tag : 'Filters'
}

{ #category : 'trait' }
CkTwoZero >> b0: aValue [
"Set filter coefficient."
	self param: #b0 put: aValue
]

{ #category : 'trait' }
CkTwoZero >> b1: aValue [
"Set filter coefficient."
	self param: #b1 put: aValue
]

{ #category : 'trait' }
CkTwoZero >> b2: aValue [
"Set filter coefficient."
	self param: #b2 put: aValue
]

{ #category : 'trait' }
CkTwoZero >> freq: aValue [
"Set filter notch frequency."
	self param: #freq put: aValue
]

{ #category : 'trait' }
CkTwoZero >> radius: aValue [
"Set filter notch radius."
	self param: #radius put: aValue
]
