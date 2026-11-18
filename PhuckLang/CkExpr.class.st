"
I am a ChucK expression built with Pharo arithmetic (Interpreter pattern: CkBinOp nodes over CkGetter, CkArg and numbers).

	440 + (lfo last * 200)

Because an expression can change, a param set to me is re-evaluated on every main-loop iteration instead of once. adaptToNumber:andSend: lets a number on the left (440 + ...) build me too.
"
Class {
	#name : 'CkExpr',
	#superclass : 'Object',
	#category : 'PhuckLang-Expressions',
	#package : 'PhuckLang',
	#tag : 'Expressions'
}

{ #category : 'arithmetic' }
CkExpr >> * anObject [
	"Build the expression instead of computing it: it is evaluated in ChucK"

	^ CkBinOp left: self operator: #* right: anObject
]

{ #category : 'arithmetic' }
CkExpr >> + anObject [
	"Build the expression instead of computing it: it is evaluated in ChucK"

	^ CkBinOp left: self operator: #+ right: anObject
]

{ #category : 'arithmetic' }
CkExpr >> - anObject [
	"Build the expression instead of computing it: it is evaluated in ChucK"

	^ CkBinOp left: self operator: #- right: anObject
]

{ #category : 'arithmetic' }
CkExpr >> / anObject [
	"Build the expression instead of computing it: it is evaluated in ChucK"

	^ CkBinOp left: self operator: #/ right: anObject
]

{ #category : 'arithmetic' }
CkExpr >> adaptToNumber: aNumber andSend: aSymbol [
	"440 + lfo last: Pharo hands us the number and the operator"
	^ CkBinOp left: aNumber operator: aSymbol right: self
]

{ #category : 'printing' }
CkExpr >> ckWriteParam: aSymbol of: aName on: aWriter [
	"Expressions are evaluated again on every loop iteration"

	aWriter addToLoop: (self ckAssign: aSymbol to: aName in: aWriter)
]
