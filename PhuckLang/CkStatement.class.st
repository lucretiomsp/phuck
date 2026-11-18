"
I am a Command recorded in a shred: one ChucK statement that prints itself with ckCodeIn: aWriter. Statements keep objects, not strings, so UGen names are resolved by the writer of the program they end up in.
"
Class {
	#name : 'CkStatement',
	#superclass : 'Object',
	#category : 'PhuckLang-Statements',
	#package : 'PhuckLang',
	#tag : 'Statements'
}

{ #category : 'printing' }
CkStatement >> ckCodeIn: aWriter [
	"One line of ChucK, without indentation"

	self subclassResponsibility
]

{ #category : 'testing' }
CkStatement >> isWait [
	"Most statements take no time"

	^ false
]
