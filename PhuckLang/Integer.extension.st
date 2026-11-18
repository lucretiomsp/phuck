Extension { #name : 'Integer' }

{ #category : '*PhuckLang' }
Integer >> ckCode [
	"ChucK ints stay ints, so int params (sync) get an int"

	^ self printString
]
