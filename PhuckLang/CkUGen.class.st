"
I am the base class of every Phuck unit generator (UGen). Setters store their value through param:put:, which hands it to the current recorder (see CkCurrentRecorder): outside a shred the value becomes the initial setting of the param, inside a shred it is recorded as a change in time. last reads my last sample as a CkExpr.
"
Class {
	#name : 'CkUGen',
	#superclass : 'CkObject',
	#instVars : [
		'inputs',
		'outputs',
		'params'
	],
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'API' }
CkUGen >> gain: aValue [
	"Every UGen has a gain"

	self param: #gain put: aValue
]

{ #category : 'initialization' }
CkUGen >> initialize [
	"Params keep the order they were set in, so the code prints in that order"

	super initialize.
	params := OrderedDictionary new
]

{ #category : 'API' }
CkUGen >> last [
	"My last sample, as an expression usable in params of other UGens"

	^ CkGetter ugen: self selector: #last
]

{ #category : 'API' }
CkUGen >> param: aSymbol put: aValue [
	"Every setter ends here. The current recorder decides: outside a shred the
	param is set, inside a shred the change is recorded (Strategy)"

	CkCurrentRecorder value ugen: self param: aSymbol put: aValue
]

{ #category : 'accessing' }
CkUGen >> params [
	"The initial settings, written by the CkGraphWriter"

	^ params
]

{ #category : 'private' }
CkUGen >> setParam: aSymbol to: aValue [
	"Store the initial setting of a param; CkNullRecorder calls me"

	params at: aSymbol put: aValue
]
