Class {
	#name : 'CkDac',
	#superclass : 'CkUGen',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'as yet unclassified' }
CkDac >> ckWriteOn: aWriter [
	aWriter nextPutAll: 'dac'
]
