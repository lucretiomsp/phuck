"
I am a UGen whose ChucK class Phuck does not model: built-ins (NRev, JCRev), chugins (GVerb, Bitcrusher) or classes from your own .ck files.

	(CkChugraphRef ugenClass: 'NRev') param: #mix put: 0.1; yourself

declares NRev nrev1 and prints 0.1 => nrev1.mix;. Params go through param:put: since I know no setters.
"
Class {
	#name : 'CkChugraphRef',
	#superclass : 'CkUGen',
	#instVars : [
		'ugenClass'
	],
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'instance creation' }
CkChugraphRef class >> ugenClass: aString [
	"Any UGen class ChucK knows but Phuck does not model: built-ins (NRev),
	chugins (GVerb, Bitcrusher) or classes from your own .ck files.
	Set its params with param:put:"

	^ self new setUGenClass: (CkObject checkIdentifier: aString)
]

{ #category : 'printing' }
CkChugraphRef >> ckClassName [
	"Declared with the ChucK class I stand for"

	^ ugenClass
]

{ #category : 'initialization' }
CkChugraphRef >> setUGenClass: aString [
	"The already checked ChucK class name"

	ugenClass := aString
]
