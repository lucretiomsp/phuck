Extension { #name : 'Duration' }

{ #category : '*PhuckLang' }
Duration >> ckCode [
	"ChucK durations in ms: 100 milliSeconds -> 100::ms, 1/2 milliSecond ->
	0.5::ms. Integer and Fraction pick their own printing (double dispatch)"

	^ (self asNanoSeconds / 1000000) ckCode , '::ms'
]
