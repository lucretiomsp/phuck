"
I am the dynamic variable holding the recorder UGen setters talk to. By default it is a CkNullRecorder (setters set params). CkShred >> record binds a CkRecorder for the duration of its block, so the same setter calls become recorded statements. Being process-specific, recording in one process never disturbs another.
"
Class {
	#name : 'CkCurrentRecorder',
	#superclass : 'DynamicVariable',
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'accessing' }
CkCurrentRecorder >> default [
	"Outside a shred, setters just set the param (Null Object)"

	^ CkNullRecorder new
]
