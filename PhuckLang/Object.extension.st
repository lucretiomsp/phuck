Extension { #name : 'Object' }

{ #category : '*PhuckLang' }
Object >> ckCode [
	^ self error: 'No ChucK code for ' , self printString
]

{ #category : '*PhuckLang' }
Object >> ckCodeIn: aWriter [
	^ self ckCode
]

{ #category : '*PhuckLang' }
Object >> ckOperandIn: aWriter [
	^ self ckCodeIn: aWriter
]

{ #category : '*PhuckLang' }
Object >> ckWriteParam: aSymbol of: aName on: aWriter [
	aWriter addInit: (self ckCodeIn: aWriter) , ' => ' , aName , '.' , aSymbol , ';'
]
