Extension { #name : 'Number' }

{ #category : '*PhuckLang' }
Number >> ckCode [
	"ChucK floats: 1/2 -> 0.5"

	^ self asFloat printString
]

{ #category : '*PhuckLang' }
Number >> ckReturnCodeIn: aWriter [
	"tick returns a float: return 1.0, not 1"

	^ self asFloat ckCode
]
