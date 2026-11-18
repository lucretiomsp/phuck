Extension { #name : 'Object' }

{ #category : '*PhuckLang' }
Object >> ckAssign: aSymbol to: aName in: aWriter [
	"The ChucK statement that sets param aSymbol of aName to me: 440 => sin1.freq;"

	^ (self ckCodeIn: aWriter) , ' => ' , aName , '.' , aSymbol , ';'
]

{ #category : '*PhuckLang' }
Object >> ckCode [
	"Objects with no ChucK equivalent end up here"

	^ self error: 'No ChucK code for ' , self printString
]

{ #category : '*PhuckLang' }
Object >> ckCodeIn: aWriter [
	"Most values print the same in every program; expressions need the writer to name UGens"

	^ self ckCode
]

{ #category : '*PhuckLang' }
Object >> ckOperandIn: aWriter [
	"Code of me as one side of an operator; only nested operations need parentheses"

	^ self ckCodeIn: aWriter
]

{ #category : '*PhuckLang' }
Object >> ckReturnCodeIn: aWriter [
	"Code of me as the value a Chugen tick returns"

	^ self ckCodeIn: aWriter
]

{ #category : '*PhuckLang' }
Object >> ckWriteParam: aSymbol of: aName on: aWriter [
	"A constant is set once, before the main loop"

	aWriter addInit: (self ckAssign: aSymbol to: aName in: aWriter)
]
