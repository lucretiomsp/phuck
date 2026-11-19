"
I compile the ChucK classes of the rig once, as public classes every shred can use. Each class side chuckClass of a TurboModule subclass gives me some: ZdFiles from ZdPlayer, Acid and AcidCubic from TurboAcid, ZdHighPass from TurboMaster ...

A public class cannot be defined twice in a running VM. After changing a chuckClass:

```language=Pharo
	PhuckVM reset.
	TurboRig reset.
	TurboRig start.
```
isLoaded asks the VM, by compiling a reference to TurboOsc.
"
Class {
	#name : 'TurboLibrary',
	#superclass : 'TurboModule',
	#classInstVars : [
		'default'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'instance creation' }
TurboLibrary class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
TurboLibrary class >> reset [

	default := nil
]

{ #category : 'running' }
TurboLibrary >> code [
	"the ChucK classes of all owners as public classes, so every shred of the VM can use them"

	^ String cr join: (self owners collect: [ :each | self publicize: each chuckClass ])
]

{ #category : 'running' }
TurboLibrary >> isLoaded [

	^ self isLoadedIn: self vm
]

{ #category : 'running' }
TurboLibrary >> isLoadedIn: aPhuckVM [
	"public classes stay until PhuckVM reset; compiling a reference to one tells whether they are there"

	aPhuckVM isRunning ifFalse: [ ^ false ].
	^ [
		  aPhuckVM compile: 'TurboOsc @ probe;'.
		  true ]
		  on: Error
		  do: [ false ]
]

{ #category : 'running' }
TurboLibrary >> isSporked [

	^ self isLoaded
]

{ #category : 'running' }
TurboLibrary >> owners [
	"every module class that brings ChucK classes, superclasses first: ZdFiles before ZdSampler"

	^ TurboModule allSubclasses select: [ :each | each class includesSelector: #chuckClass ]
]

{ #category : 'running' }
TurboLibrary >> publicize: aString [

	^ String cr join: (aString lines collect: [ :line |
				   (line beginsWith: 'class ')
					   ifTrue: [ 'public ' , line ]
					   ifFalse: [ line ] ])
]

{ #category : 'running' }
TurboLibrary >> spork [
	"compile the classes once: a public class cannot be defined twice in the same VM.
	After changing a chuckClass, PhuckVM reset and spork again"

	self vm isRunning ifFalse: [ self vm start ].
	self isLoaded ifFalse: [ self vm compile: self code ]
]

{ #category : 'running' }
TurboLibrary >> unspork [
	"public classes cannot be removed from a running VM"

	
]
