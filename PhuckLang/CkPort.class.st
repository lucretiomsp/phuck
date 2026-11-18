"
I am one of the fixed ends of a graph that ChucK already names: inlet and outlet inside a Chugraph class. Like CkDac I am never declared: the writer prints my keyword where I appear in a chain.

	CkPort inlet => (CkLPF new freq: 800) => CkPort outlet

prints inlet => LPF lpf1 => outlet;. CkChugraph >> buildFrom:to: hands me in as its arguments.
"
Class {
	#name : 'CkPort',
	#superclass : 'CkObject',
	#instVars : [
		'keyword'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'instance creation' }
CkPort class >> inlet [
	"The input of the Chugraph being defined"

	^ self new setKeyword: 'inlet'
]

{ #category : 'instance creation' }
CkPort class >> outlet [
	"The output of the Chugraph being defined"

	^ self new setKeyword: 'outlet'
]

{ #category : 'printing' }
CkPort >> ckWriteOn: aWriter [
	"Ports are ChucK keywords, never declared"

	aWriter nextPutAll: keyword
]

{ #category : 'printing' }
CkPort >> printOn: aStream [
	"Show which port I am in inspectors and errors"

	aStream nextPutAll: 'CkPort ' , keyword
]

{ #category : 'initialization' }
CkPort >> setKeyword: aString [
	"inlet or outlet"

	keyword := aString
]
