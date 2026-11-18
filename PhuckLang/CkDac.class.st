"
I am the sound card: ChucK's dac. I am never declared, only printed as the keyword dac at the end of a chain.
"
Class {
	#name : 'CkDac',
	#superclass : 'CkUGen',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'printing' }
CkDac >> ckWriteOn: aWriter [
	"dac is the sound card, already defined by ChucK: print the keyword, never declare it"

	aWriter nextPutAll: 'dac'
]
