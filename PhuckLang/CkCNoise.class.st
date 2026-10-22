"
A noise generator with multiple noise synthesis modes.



"
Class {
	#name : 'CkCNoise',
	#superclass : 'CkUGen',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'API' }
CkCNoise >> fprob: aFloat [ 
"Probability [0-1] used for calculating XOR noise"
	self param: #fprob put: aFloat 
]

{ #category : 'API' }
CkCNoise >> mode: aString [
"Noise synthesis mode. Supported modes are ""white"", ""pink"", ""flip"", and ""xor""."
self param: #mode put: aString 
]
