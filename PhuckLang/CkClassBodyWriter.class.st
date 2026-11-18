"
I am the State of the writer inside a generated ChucK class (Chugen or Chugraph). I write members the same way as my superclass, but a ChucK class cannot see the file around it, so I refuse what only makes sense at file level: globals (sliders), main-loop lines (expressions), shreds, and reading UGens that are not my own. Classes needed by my class are defined by my parent, the root writer, because ChucK classes are file-level.
"
Class {
	#name : 'CkClassBodyWriter',
	#superclass : 'CkGraphWriter',
	#instVars : [
		'parent'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'instance creation' }
CkClassBodyWriter class >> parent: aWriter [
	"A writer for the members of a class defined by aWriter"

	^ self new setParent: aWriter
]

{ #category : 'adding' }
CkClassBodyWriter >> addGlobal: aString [
	"A ChucK class cannot declare a global for Pharo to set"

	self error: 'Sliders cannot be used inside a Chugraph or Chugen class: set the param on the instance instead'
]

{ #category : 'adding' }
CkClassBodyWriter >> addToLoop: aString [
	"Expressions need the main loop, which only exists at file level"

	self error: 'Only constant params are allowed inside a Chugraph or Chugen class: a class has no main loop'
]

{ #category : 'accessing' }
CkClassBodyWriter >> contents [
	"Members only, indented: no globals, no shreds, no main loop"

	^ String streamContents: [ :s |
			  (body contents , inits contents) lines do: [ :each |
					  s
						  nextPutAll: '  ' , each;
						  lf ] ]
]

{ #category : 'writing classes' }
CkClassBodyWriter >> defineClassFor: aKey named: aBaseName extends: aSuperName with: aBlock [
	"Classes are file-level in ChucK: a class used inside a class is defined by the root writer"

	^ parent
		  defineClassFor: aKey
		  named: aBaseName
		  extends: aSuperName
		  with: aBlock
]

{ #category : 'naming' }
CkClassBodyWriter >> nameOf: aUGen [
	"A ChucK class cannot see the UGens of the file around it"

	^ declared at: aUGen ifAbsent: [ self error: 'A Chugraph or Chugen class can only use its own UGens, not ' , aUGen printString ]
]

{ #category : 'initialization' }
CkClassBodyWriter >> setParent: aWriter [
	"The writer of the file this class is defined in"

	parent := aWriter
]

{ #category : 'writing shreds' }
CkClassBodyWriter >> writeShred: aShred [
	"A class has no place to spork from"

	self error: 'Shreds cannot be sporked from inside a Chugraph class'
]
