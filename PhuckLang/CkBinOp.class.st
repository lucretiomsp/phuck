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
	^ self new setLeft: a operator: aSymbol right: b

]

{ #category : 'API' }
CkBinOp >> ckCodeIn: aWriter [
	^ (left ckOperandIn: aWriter) , ' ' , operator , ' ' , (right ckOperandIn: aWriter)

]

{ #category : 'API' }
CkBinOp >> ckOperandIn: aWriter [
	"nested operations keep Pharo's grouping"
	^ '(' , (self ckCodeIn: aWriter) , ')'
]

{ #category : 'initialization' }
CkBinOp >> setLeft: a operator: aSymbol right: b [
	left := a.
	operator := aSymbol.
	right := b
]
