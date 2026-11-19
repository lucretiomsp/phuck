"
I am the whole Turbo instrument as small shreds: the twelve STK instruments, the seven synths and one ZdSampler or ZdLoopPlayer per folder of TurboSamples, with the global names of the old TurboPhuck code.

```language=Pharo
	TurboRig start.
	TurboPhuck new.	""Coypu as before""
	(TurboRig default at: 'kick') trig.
	(TurboRig default at: 'acid') cutoff: 0.6; trig: 0.3.
	TurboRig default playing.
	TurboRig stop.
```
start connects Coypu through TurboPhuck class>>connectPerformanceTo:, like the old TurboPhuck start. On a fresh VM (PhuckVM reset, old TurboPhuck start, image restart) start forgets the old shreds and plays everything anew. TurboRig reset forgets everything. A new sample folder: TurboRig default root: aFolder, or TurboRig reset.
"
Class {
	#name : 'TurboRig',
	#superclass : 'Object',
	#instVars : [
		'root',
		'voices'
	],
	#classInstVars : [
		'default'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'instance creation' }
TurboRig class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
TurboRig class >> reset [
	"after PhuckVM reset: the VM has forgotten the library, the master and every shred"

	default := nil.
	TurboLibrary reset.
	TurboMaster reset
]

{ #category : 'instance creation' }
TurboRig class >> start [

	^ self default start
]

{ #category : 'instance creation' }
TurboRig class >> stop [

	^ self default stop
]

{ #category : 'accessing' }
TurboRig >> at: aName [
	"the voice whose globals start with aName: kick, hoover, bell ..."

	^ self voices detect: [ :each | each name = aName ] ifNone: [ self error: 'no voice named ' , aName ]
]

{ #category : 'accessing' }
TurboRig >> buildVoices [

	| codegen all names |
	codegen := TurboSampleCodegen new root: self root.
	all := OrderedCollection new.
	all addAll: TurboStk all.
	all addAll: ({
			 TurboHoover.
			 TurboAcid.
			 TurboReese.
			 TurboKick99.
			 TurboPsgPlus.
			 TurboFm2Op.
			 TurboChordy } collect: [ :each | each new ]).
	self root exists ifTrue: [
			codegen folders do: [ :each |
					all add: (((codegen isLoop: each)
							  ifTrue: [ ZdLoopPlayer ]
							  ifFalse: [ ZdSampler ]) folder: each) ] ].
	names := all collect: [ :each | each name ].
	names asSet size = names size ifFalse: [
		self error: 'two voices share a name: ' , (names detect: [ :n | (names occurrencesOf: n) > 1 ]) ].
	^ all
]

{ #category : 'accessing' }
TurboRig >> names [

	^ self voices collect: [ :each | each name ]
]

{ #category : 'running' }
TurboRig >> playing [

	^ self voices select: [ :each | each isPlaying ]
]

{ #category : 'accessing' }
TurboRig >> root [
	"the sample folders, one ZdSampler or ZdLoopPlayer each"

	^ root ifNil: [ root := (FileLocator imageDirectory / 'TurboSamples') asFileReference ]
]

{ #category : 'accessing' }
TurboRig >> root: aFileReference [

	root := aFileReference.
	voices := nil
]

{ #category : 'running' }
TurboRig >> start [
	"library, master, then one shred per voice; Coypu then plays through the rig like through the old TurboPhuck.
	A VM without the library is a fresh one (PhuckVM reset, old TurboPhuck start, image restart): the shreds I knew are gone"

	self vm isRunning ifFalse: [ self vm start ].
	TurboLibrary default isLoaded ifFalse: [
			TurboMaster default forgetShred.
			self voices do: [ :each | each forgetShred ].
			TurboLibrary default play ].
	TurboMaster default isPlaying ifFalse: [ TurboMaster default play ].
	self voices do: [ :each | each isPlaying ifFalse: [ each play ] ].
	TurboPhuck connectPerformanceTo: self vm
]

{ #category : 'running' }
TurboRig >> stop [
	"every voice shred and the master; the library stays compiled in the VM"

	self voices do: [ :each | each stop ].
	TurboMaster default stop
]

{ #category : 'accessing' }
TurboRig >> vm [

	^ PhuckVM uniqueInstance
]

{ #category : 'accessing' }
TurboRig >> voices [
	"the STK instruments, the synths, then one player per sample folder, with the global names of the old TurboPhuck code"

	^ voices ifNil: [ voices := self buildVoices ]
]
