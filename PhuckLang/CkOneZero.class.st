"
This Filter subclass implements a one-zero digital filter. A method is provided for setting the zero position along the real axis of the z-plane while maintaining a constant filter gain. by Perry R. Cook and Gary P. Scavone, 1995 - 2002.
"
Class {
	#name : 'CkOneZero',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-Filters',
	#package : 'PhuckLang',
	#tag : 'Filters'
}

{ #category : 'trait' }
CkOneZero >> b0: aValue [
"Set filter coefficient."
	self param: #b0 put: aValue
]

{ #category : 'trait' }
CkOneZero >> b1: aValue [
"Set filter coefficient."
	self param: #b1 put: aValue
]

{ #category : 'trait' }
CkOneZero >> zero: aValue [
"Set zero position"
	self param: #zero put: aValue
]
