"
A BiQuad (two-pole, two-zero) filter section from STK. A method is provided for creating a resonance in the frequency response while maintaining a constant filter gain.



"
Class {
	#name : 'CkBiQuad',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-Filters',
	#package : 'PhuckLang',
	#tag : 'Filters'
}

{ #category : 'API' }
CkBiQuad >> a0: aValue [
"Set filter coefficient."
	self param: #a0 put: aValue
]

{ #category : 'API' }
CkBiQuad >> a1: aValue [
"Set filter coefficient."
	self param: #a1 put: aValue
]

{ #category : 'API' }
CkBiQuad >> a2: aValue [
"Set filter coefficient."
	self param: #a2 put: aValue
]

{ #category : 'API' }
CkBiQuad >> b1: aValue [
"Set filter coefficient."
	self param: #b1 put: aValue
]

{ #category : 'API' }
CkBiQuad >> b2: aValue [
"Set filter coefficient."
	self param: #b2 put: aValue
]

{ #category : 'API' }
CkBiQuad >> eqz: aValue [
"Enable equal-gain zeroes."
	self param: #eqz put: aValue
]

{ #category : 'API' }
CkBiQuad >> pfreq: aValue [
"ESet resonance frequency (poles)"
	self param: #pfreq put: aValue
]

{ #category : 'API' }
CkBiQuad >> prad: aValue [
"Set Pole radius (values greater than 1 will be unstable)."
	self param: #prad put: aValue
]

{ #category : 'API' }
CkBiQuad >> pregain: aValue [
"Set pregain"
	self param: #pregain put: aValue
]

{ #category : 'API' }
CkBiQuad >> zfreq: aValue [
"Set notch freq "
	self param: #zfreq put: aValue
]

{ #category : 'API' }
CkBiQuad >> zrad: aValue [
"Set zero radius "
	self param: #zrad put: aValue
]
