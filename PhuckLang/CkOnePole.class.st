"
This Filter subclass implements a one-pole digital filter. A method is provided for setting the pole position along the real axis of the z-plane while maintaining a constant peak filter gain. by Perry R. Cook and Gary P. Scavone, 1995 - 2002.



"
Class {
	#name : 'CkOnePole',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-Filters',
	#package : 'PhuckLang',
	#tag : 'Filters'
}

{ #category : 'API' }
CkOnePole >> a1: aValue [
"Set filter coefficient."
	self param: #a1 put: aValue
]

{ #category : 'API' }
CkOnePole >> b0: aValue [
"Set filter coefficient."
	self param: #b0 put: aValue
]

{ #category : 'API' }
CkOnePole >> pole: aValue [
"Set pole position along real axis of z-plane."
	self param: #pole put: aValue
]
