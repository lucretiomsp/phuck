"
I am a binary operation of a CkExpr: left operator right. When nested I print in parentheses, so ChucK keeps Pharo's left-to-right grouping: 1 + x * 2 -> (1 + x) * 2.
"
Class {
	#name : 'CkBinOp',
	#superclass : 'CkExpr',
	#instVars : [
		'left',
		'operator',
		'right'
	],
	#category : 'PhuckLang-Expressions',
	#package : 'PhuckLang',
	#tag : 'Expressions'
}

{ #category : 'as yet unclassified' }
CkBinOp class >> left: a operator: aSymbol right: b [
	"The expression a aSymbol b, for example lfo last * 200"

	^ self new setLeft: a operator: aSymbol right: b
]

{ #category : 'API' }
CkBinOp >> ckCodeIn: aWriter [
	"Operands print themselves; nested operations add their own parentheses"

	^ (left ckOperandIn: aWriter) , ' ' , operator , ' ' , (right ckOperandIn: aWriter)
]

{ #category : 'API' }
CkBinOp >> ckOperandIn: aWriter [
	"nested operations keep Pharo's grouping"
	^ '(' , (self ckCodeIn: aWriter) , ')'
]

{ #category : 'initialization' }
CkBinOp >> setLeft: a operator: aSymbol right: b [
	"Operands may be numbers or other expressions"

	left := a.
	operator := aSymbol.
	right := b
]
