"
This Filter subclass implements a two-pole digital filter. A method is provided for creating a resonance in the frequency response while maintaining a nearly constant filter gain. by Perry R. Cook and Gary P. Scavone, 1995 - 2002.
"
Class {
	#name : 'CkTwoPole',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-Filters',
	#package : 'PhuckLang',
	#tag : 'Filters'
}

{ #category : 'API' }
CkTwoPole >> a1: aValue [
"Set filter coefficient."
	self param: #a1 put: aValue
]

{ #category : 'API' }
CkTwoPole >> a2: aValue [
"Set filter coefficient."
	self param: #a2 put: aValue
]

{ #category : 'API' }
CkTwoPole >> b0: aValue [
"Set filter coefficient."
	self param: #b0 put: aValue
]

{ #category : 'API' }
CkTwoPole >> freq: aValue [
"Set filter resonance frequency"
	self param: #freq put: aValue
]

{ #category : 'API' }
CkTwoPole >> norm: aValue [
"Set filter normalization"
	self param: #norm put: aValue
]

{ #category : 'API' }
CkTwoPole >> radius: aValue [
"Set filter radius resonance"
	self param: #radius put: aValue
]
