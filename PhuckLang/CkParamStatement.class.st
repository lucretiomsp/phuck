"
I am the statement setting param of ugen to value inside a shred: 440 => sin1.freq;. The value prints itself (ckAssign:to:in:): a number once, an expression, or a slider global.
"
Class {
	#name : 'CkParamStatement',
	#superclass : 'CkStatement',
	#instVars : [
		'ugen',
		'param',
		'value'
	],
	#category : 'PhuckLang-Statements',
	#package : 'PhuckLang',
	#tag : 'Statements'
}

{ #category : 'instance creation' }
CkParamStatement class >> ugen: aUGen param: aSymbol value: aValue [
	"The recorded change aUGen.aSymbol := aValue"

	^ self new setUGen: aUGen param: aSymbol value: aValue
]

{ #category : 'printing' }
CkParamStatement >> ckCodeIn: aWriter [
	"The value decides how it is assigned: a number, an expression, a slider"

	^ value ckAssign: param to: (aWriter nameOf: ugen) in: aWriter
]

{ #category : 'initialization' }
CkParamStatement >> setUGen: aUGen param: aSymbol value: aValue [
	"Keep the objects; names are resolved when the statement is printed"

	ugen := aUGen.
	param := aSymbol.
	value := aValue
]
