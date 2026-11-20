"
I am the whole Turbo instrument as small shreds: the twelve STK instruments, the seven synths and one ZdSampler or ZdLoopPlayer per folder of TurboSamples, with the global names of the old TurboPhuck code.

```language=Pharo
	TurboPhuckRig start.
	TurboPhuck new.	""Coypu as before""
	(TurboPhuckRig default at: 'kick') trig.
	(TurboPhuckRig default at: 'acid') cutoff: 0.6; trig: 0.3.
	TurboPhuckRig default sporked.
	TurboPhuckRig stop.
```
start connects Coypu through TurboPhuck class>>connectPerformanceTo:, like the old TurboPhuck start. On a fresh VM (PhuckVM reset, old TurboPhuck start, image restart) start forgets the old shreds and sporks everything anew. TurboPhuckRig reset forgets everything. A new sample folder: TurboPhuckRig default root: aFolder, or TurboPhuckRig reset.
"
Class {
	#name : 'TurboPhuckRig',
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
TurboPhuckRig class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
TurboPhuckRig class >> reset [
	"after PhuckVM reset: the VM has forgotten the library, the master and every shred"

	default := nil.
	TurboLibrary reset.
	TurboMaster reset
]

{ #category : 'instance creation' }
TurboPhuckRig class >> start [

	^ self default start
]

{ #category : 'instance creation' }
TurboPhuckRig class >> stop [

	^ self default stop
]

{ #category : 'accessing' }
TurboPhuckRig >> at: aName [
	"the voice whose globals start with aName: kick, hoover, bell ..."

	^ self voices detect: [ :each | each name = aName ] ifNone: [ self error: 'no voice named ' , aName ]
]

{ #category : 'accessing' }
TurboPhuckRig >> buildVoices [

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
TurboPhuckRig >> names [

	^ self voices collect: [ :each | each name ]
]

{ #category : 'accessing' }
TurboPhuckRig >> root [
	"the sample folders, one ZdSampler or ZdLoopPlayer each"

	^ root ifNil: [ root := (FileLocator imageDirectory / 'TurboSamples') asFileReference ]
]

{ #category : 'accessing' }
TurboPhuckRig >> root: aFileReference [

	root := aFileReference.
	voices := nil
]

{ #category : 'running' }
TurboPhuckRig >> sporked [
	"the voices whose shred runs"

	^ self voices select: [ :each | each isSporked ]
]

{ #category : 'running' }
TurboPhuckRig >> start [
	"library, master, then one shred per voice; Coypu then plays through the rig like through the old TurboPhuck.
	A VM without the library is a fresh one (PhuckVM reset, old TurboPhuck start, image restart): the shreds I knew are gone"

	self vm isRunning ifFalse: [ self vm start ].
	TurboLibrary default isLoaded ifFalse: [
			TurboMaster default forgetShred.
			self voices do: [ :each | each forgetShred ].
			TurboLibrary default spork ].
	TurboMaster default isSporked ifFalse: [ TurboMaster default spork ].
	self voices do: [ :each | each isSporked ifFalse: [ each spork ] ].
	TurboPhuck connectPerformanceTo: self vm
]

{ #category : 'running' }
TurboPhuckRig >> stop [
	"unspork every voice and the master; the library stays compiled in the VM"

	self voices do: [ :each | each unspork ].
	TurboMaster default unspork
]

{ #category : 'accessing' }
TurboPhuckRig >> vm [

	^ PhuckVM uniqueInstance
]

{ #category : 'accessing' }
TurboPhuckRig >> voices [
	"the STK instruments, the synths, then one player per sample folder, with the global names of the old TurboPhuck code"

	^ voices ifNil: [ voices := self buildVoices ]
]
