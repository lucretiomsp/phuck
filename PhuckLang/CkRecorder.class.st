"
I am the recording Strategy installed in CkCurrentRecorder while a CkShred block runs. UGen setters reach me through CkUGen >> param:put: and I store them as CkParamStatement commands; wait: stores a CkWaitStatement. touched lists the UGens the shred changes.
"
Class {
	#name : 'CkRecorder',
	#superclass : 'Object',
	#instVars : [
		'statements',
		'touched'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'initialization' }
CkRecorder >> initialize [
	"Nothing recorded, nothing touched"

	super initialize.
	statements := OrderedCollection new.
	touched := IdentitySet new
]

{ #category : 'accessing' }
CkRecorder >> statements [
	"The recorded statements, in the order the block ran them"

	^ statements
]

{ #category : 'accessing' }
CkRecorder >> touched [
	"The UGens this shred changes"

	^ touched
]

{ #category : 'recording' }
CkRecorder >> ugen: aUGen param: aSymbol put: aValue [
	"Inside a shred: aUGen keeps its params, the change is replayed in time"

	statements add: (CkParamStatement ugen: aUGen param: aSymbol value: aValue).
	touched add: aUGen
]

{ #category : 'recording' }
CkRecorder >> wait: aDuration [
	"Let time pass in the shred: 200::ms => now;"

	statements add: (CkWaitStatement duration: aDuration)
]

{ #category : 'testing' }
CkRecorder >> waits [
	"Does time pass somewhere in the shred? A loop without a wait would freeze ChucK"

	^ statements anySatisfy: [ :each | each isWait ]
]
