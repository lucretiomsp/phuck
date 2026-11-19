Extension { #name : 'SequenceableCollection' }

{ #category : '*PhuckLang' }
SequenceableCollection >> ckEvery: aDuration [
	"A PhuckLang param value playing my elements in a loop, one per aDuration:
		m freq: (#(10 5 20 40) ckEvery: 1 second)"

	^ CkSequence values: self every: aDuration
]
