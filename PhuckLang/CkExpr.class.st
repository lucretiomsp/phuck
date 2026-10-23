Class {
	#name : 'CkExpr',
	#superclass : 'Object',
	#category : 'PhuckLang-Expressions',
	#package : 'PhuckLang',
	#tag : 'Expressions'
}

{ #category : 'arithmetic' }
CkExpr >> * anObject [
	^ CkBinOp left: self operator: #* right: anObject
]

{ #category : 'arithmetic' }
CkExpr >> + anObject [
	^ CkBinOp left: self operator: #+ right: anObject

]

{ #category : 'arithmetic' }
CkExpr >> - anObject [
	^ CkBinOp left: self operator: #- right: anObject

]

{ #category : 'arithmetic' }
CkExpr >> / anObject [
	^ CkBinOp left: self operator: #/ right: anObject
]

{ #category : 'arithmetic' }
CkExpr >> adaptToNumber: aNumber andSend: aSymbol [
	"440 + lfo last: Pharo hands us the number and the operator"
	^ CkBinOp left: aNumber operator: aSymbol right: self
]

{ #category : 'as yet unclassified' }
CkExpr >> ckWriteParam: aSymbol of: aName on: aWriter [
	"Expressions are evaluated again on every loop iteration"
	aWriter addToLoop: (self ckCodeIn: aWriter) , ' => ' , aName , '.' , aSymbol , ';'
]
