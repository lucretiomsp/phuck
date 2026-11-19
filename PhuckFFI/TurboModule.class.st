"
I am one small ChucK program of the Turbo rig, run as its own shred in PhuckVM uniqueInstance. My subclasses hold their ChucK code as plain strings, one piece each, so the old single TurboPhuck program can move to PhuckLang one piece at a time.

play sporks my shred, or swaps its code when I already play. stop removes it. prepare runs first: what I need running before me.

- TurboLibrary: every ChucK class, compiled once as public classes
- TurboMaster: the master bus, a global Gain every voice plays into
- TurboVoice: one instrument, its globals and its control loop
"
Class {
	#name : 'TurboModule',
	#superclass : 'Object',
	#instVars : [
		'shred'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'accessing' }
TurboModule >> code [
	"my whole shred as ChucK source"

	^ self subclassResponsibility
]

{ #category : 'running' }
TurboModule >> forgetShred [
	"my shred died with its VM (PhuckVM reset, image restart): the next play sporks a new one"

	shred := nil
]

{ #category : 'running' }
TurboModule >> isPlaying [

	^ shred isNotNil and: [ shred isRemoved not ]
]

{ #category : 'accessing' }
TurboModule >> label [

	^ self class name
]

{ #category : 'running' }
TurboModule >> play [
	"spork my shred, or swap its code when I already play; boots the VM when needed"

	self vm isRunning ifFalse: [ self vm start ].
	self prepare.
	self isPlaying
		ifTrue: [ shred replace: self code ]
		ifFalse: [ shred := self vm run: self code ]
]

{ #category : 'running' }
TurboModule >> prepare [
	"what must run before my shred, nothing by default"

	
]

{ #category : 'printing' }
TurboModule >> printOn: aStream [

	aStream << self label << (self isPlaying
		 ifTrue: [ ' (playing)' ]
		 ifFalse: [ '' ])
]

{ #category : 'accessing' }
TurboModule >> shred [

	^ shred
]

{ #category : 'running' }
TurboModule >> stop [

	self isPlaying ifTrue: [ shred remove ]
]

{ #category : 'accessing' }
TurboModule >> vm [

	^ PhuckVM uniqueInstance
]
