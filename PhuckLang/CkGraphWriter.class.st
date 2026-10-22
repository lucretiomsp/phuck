Class {
	#name : 'CkGraphWriter',
	#superclass : 'Object',
	#instVars : [
		'declared',
		'counters',
		'globals',
		'body',
		'loop'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'writing' }
CkGraphWriter >> addGlobal: aString [
	globals nextPutAll: aString; lf

]

{ #category : 'writing' }
CkGraphWriter >> addToLoop: aString [
	loop nextPutAll: '  '; nextPutAll: aString; lf
]

{ #category : 'writing' }
CkGraphWriter >> contents [
	^ String streamContents: [ :s |
		s
			nextPutAll: globals contents;
			nextPutAll: body contents;
			nextPutAll: 'while (1) {'; lf;
			nextPutAll: loop contents;
			nextPutAll: '  1::ms => now;'; lf;
			nextPutAll: '}' ]
]

{ #category : 'writing' }
CkGraphWriter >> declare: aUGen [
	| name |
	name := self newNameFor: aUGen.
	body nextPutAll: aUGen ckClassName , ' ' , name.
	aUGen params keysAndValuesDo: [ :param :value |
		value ckWriteParam: param of: name on: self ]
]

{ #category : 'initialization' }
CkGraphWriter >> initialize [
	super initialize.
	declared := IdentityDictionary new.
	counters := Bag new.
	globals := String new writeStream.
	body := String new writeStream.
	loop := String new writeStream
]

{ #category : 'instance creation' }
CkGraphWriter >> newNameFor: aUGen [
	"Numbered per program, so every asPhuck starts at sqr1"
	| prefix |
	prefix := aUGen ckPrefix.
	counters add: prefix.
	^ declared
		at: aUGen
		put: prefix , (counters occurrencesOf: prefix) printString

]

{ #category : 'writing' }
CkGraphWriter >> nextPutAll: aString [
	body nextPutAll: aString

]

{ #category : 'writing' }
CkGraphWriter >> writeChain: aCollection [
	aCollection
		do: [ :each | each ckWriteOn: self ]
		separatedBy: [ body nextPutAll: ' => ' ].
	body nextPutAll: ';'; lf
]

{ #category : 'writing' }
CkGraphWriter >> writeUGen: aUGen [
	declared
		at: aUGen
		ifPresent: [ :name | body nextPutAll: name ]
		ifAbsent: [ self declare: aUGen ]
]
