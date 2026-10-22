Class {
	#name : 'CkSlider',
	#superclass : 'Object',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'as yet unclassified' }
CkSlider >> ckWriteParam: aSymbol of: aName on: aWriter [
	"#gain of sqr1: global float sqr1Gain; and sqr1Gain => sqr1.gain;"
	| global |
	global := aName , aSymbol capitalized.
	aWriter
		addGlobal: 'global float ' , global , ';';
		addToLoop: global , ' => ' , aName , '.' , aSymbol , ';'
]
