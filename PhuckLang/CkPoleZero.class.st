"
A one-pole, one-zero digital filter. A method is provided for creating an allpass filter with a given coefficient. Another method is provided to create a DC blocking filter. by Perry R. Cook and Gary P. Scavone, 1995 - 2002.
"
Class {
	#name : 'CkPoleZero',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-Filters',
	#package : 'PhuckLang',
	#tag : 'Filters'
}

{ #category : 'trait' }
CkPoleZero >> a1: aValue [
"Set filter coefficient."
	self param: #a1 put: aValue
]

{ #category : 'trait' }
CkPoleZero >> allpass: aValue [
"Set allpass filter with given coefficient"
	self param: #allpass put: aValue
]

{ #category : 'trait' }
CkPoleZero >> b0: aValue [
"Set filter coefficient."
	self param: #b0 put: aValue
]

{ #category : 'trait' }
CkPoleZero >> b1: aValue [
"Set filter coefficient."
	self param: #b1 put: aValue
]

{ #category : 'trait' }
CkPoleZero >> blockZero: aValue [
"Set DC blocking filter with given pole position"
	self param: #blockZero put: aValue
]
