"
I am a shred (a ChucK process) running in a PhuckVM. PhuckVM>>run: answers me.

```language=Pharo
	shred := PhuckVM uniqueInstance run: 'SinOsc s => dac; 1::day => now;'.
	shred replace: 'TriOsc t => dac; 1::day => now;'.
	shred remove.
```

replace: removes my current code and sporks the new one; I keep the same identity with a new id,
so references to me stay valid.
isRemoved only knows what went through me: a shred that ends by itself inside ChucK
(its code reaches the end) is not detected, libphuck has no call to ask for shred status yet.
"
Class {
	#name : 'PhuckShred',
	#superclass : 'Object',
	#instVars : [
		'vm',
		'id',
		'source',
		'removed'
	],
	#category : 'PhuckFFI-Core',
	#package : 'PhuckFFI',
	#tag : 'Core'
}

{ #category : 'accessing' }
PhuckShred >> globals [ 

^ vm globalsIn: source.
]

{ #category : 'accessing' }
PhuckShred >> id [ 
^ id
]

{ #category : 'testing' }
PhuckShred >> isRemoved [ 
^ removed
]

{ #category : 'printing' }
PhuckShred >> printOn: aStream [
	aStream
		nextPutAll: 'PhuckShred(';
		print: id;
		nextPutAll: (removed ifTrue: [ ', removed)' ] ifFalse: [ ')' ])
]

{ #category : 'actions' }
PhuckShred >> remove [
	removed ifTrue: [ ^ false ].
	removed := true.
	^ vm removeShred: id
]

{ #category : 'actions' }
PhuckShred >> replace: aString [
	"Swap my code, keep me as the same object."
	| newId |
	newId := vm compile: aString.
	removed ifFalse: [ vm removeShred: id ].
	id := newId.
	source := aString.
	removed := false
]

{ #category : 'actions' }
PhuckShred >> respork [
	"Run my code again, e.g. after remove."
	self replace: source
]

{ #category : 'accessing' }
PhuckShred >> source [ 
^ source
]

{ #category : 'accessing' }
PhuckShred >> vm [ 
^ vm
]

{ #category : 'initialization' }
PhuckShred >> vm: aVM id: anInteger source: aString [
	vm := aVM.
	id := anInteger.
	source := aString.
	removed := false
]
