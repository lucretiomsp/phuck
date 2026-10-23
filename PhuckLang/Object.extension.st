Extension { #name : 'Object' }

{ #category : '*PhuckLang' }
Object >> ckCode [
	^ self error: 'No ChucK code for ' , self printString
]

{ #category : '*PhuckLang' }
Object >> ckWriteParam: aSymbol of: aName on: aWriter [
	"Constants are set once, before the loop"
	aWriter addInit: self ckCode , ' => ' , aName , '.' , aSymbol , ';'
]
