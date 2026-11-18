"
I am a variable of the generated code, standing for a value only ChucK knows: the in of a Chugen tick. I print as my name and combine like any CkExpr.
"
Class {
	#name : 'CkArg',
	#superclass : 'CkExpr',
	#instVars : [
		'name'
	],
	#category : 'PhuckLang-Expressions',
	#package : 'PhuckLang',
	#tag : 'Expressions'
}

{ #category : 'instance creation' }
CkArg class >> named: aString [
	"A variable of the generated ChucK code, such as the in of a Chugen tick"

	^ self new setName: aString
]

{ #category : 'printing' }
CkArg >> ckCodeIn: aWriter [
	"A variable prints as its name"

	^ name
]

{ #category : 'printing' }
CkArg >> printOn: aStream [
	"Show which variable I stand for"

	aStream nextPutAll: 'CkArg ' , name
]

{ #category : 'initialization' }
CkArg >> setName: aString [
	"The name the variable has in the generated ChucK code"

	name := aString
]
