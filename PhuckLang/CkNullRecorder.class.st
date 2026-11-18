"
I am the Null Object of CkCurrentRecorder: the recorder in place when no shred is being recorded. I record nothing and just set the param on the UGen, so CkUGen >> param:put: never has to test whether it is inside a shred.
"
Class {
	#name : 'CkNullRecorder',
	#superclass : 'Object',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'recording' }
CkNullRecorder >> ugen: aUGen param: aSymbol put: aValue [
	"Nothing to record: the value becomes the param's initial setting"

	aUGen setParam: aSymbol to: aValue
]
