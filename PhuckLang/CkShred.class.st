"
I am a sequence of parameter changes in time, played by a sporked ChucK shred.

	CkShred loop: [ :t |
		osc freq: 440. t wait: 200 milliSeconds.
		osc freq: 660. t wait: 200 milliSeconds ]

The block is not ChucK code: it runs once in Pharo, when the program is printed, with a CkRecorder installed as CkCurrentRecorder. UGen setters called inside it are recorded as statements instead of changing the UGens, and t wait: records a wait. The writer prints them as

	fun void shred1() { while (1) { 440 => sin1.freq; 200::ms => now; ... } }
	spork ~ shred1();

loop: repeats forever and must wait somewhere (otherwise ChucK hangs, so I refuse it); once: runs through and ends. Pharo control flow inside the block is unrolled when recording: a to:do: produces one statement per iteration.
"
Class {
	#name : 'CkShred',
	#superclass : 'CkPart',
	#instVars : [
		'block',
		'looping'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'instance creation' }
CkShred class >> loop: aBlock [
	"A shred repeating aBlock forever. aBlock gets the recorder:
		CkShred loop: [ :t | osc freq: 440. t wait: 200 milliSeconds ]
	It must wait somewhere, or ChucK never gets time to make sound"

	^ self new setBlock: aBlock looping: true
]

{ #category : 'instance creation' }
CkShred class >> once: aBlock [
	"A shred running aBlock once, then ending"

	^ self new setBlock: aBlock looping: false
]

{ #category : 'recording' }
CkShred >> checkRecorded: aRecorder [
	"while (1) without time passing freezes the ChucK VM"

	(looping and: [ aRecorder waits not ]) ifTrue: [ self error: 'A looping shred must wait, e.g. t wait: 100 milliSeconds' ]
]

{ #category : 'printing' }
CkShred >> ckPrefix [
	"Shreds are named shred1, shred2, ..."

	^ 'shred'
]

{ #category : 'writing' }
CkShred >> ckWriteBodyOf: aRecorder on: aWriter [
	"Looping shreds wrap their statements in while (1)"

	looping
		ifTrue: [ aWriter writeLoopOf: aRecorder ]
		ifFalse: [ aWriter writeStatementsOf: aRecorder indent: '  ' ]
]

{ #category : 'writing' }
CkShred >> ckWritePartOn: aWriter [
	"Visitor: a shred is written as a sporked function"

	aWriter writeShred: self
]

{ #category : 'recording' }
CkShred >> record [
	"Run the block once with a recorder in place: UGen setters inside it
	become statements instead of changing the UGens (see CkCurrentRecorder)"

	| recorder |
	recorder := CkRecorder new.
	CkCurrentRecorder value: recorder during: [ block cull: recorder ].
	self checkRecorded: recorder.
	^ recorder
]

{ #category : 'initialization' }
CkShred >> setBlock: aBlock looping: aBoolean [
	"aBlock is recorded at asPhuck time; aBoolean chooses loop: or once:"

	block := aBlock.
	looping := aBoolean
]
