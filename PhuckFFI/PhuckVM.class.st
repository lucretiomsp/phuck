"
I am the Pharo-side facade to the ChucK virtual machine running in libphuck.

I am a singleton: use PhuckVM uniqueInstance (new is blocked). PhuckVM reset frees the C VM; the next uniqueInstance creates a fresh one.

I own a Phuck handle (slot vm) and hide the raw LibPhuck calls: VM parameters, init and start, audio, compiling code into shreds, globals, events and console output.

Defaults:
- C VM parameters, applied by setDefaults every time a new C VM is created (first use, after reset, after an image restart): sample rate 48000, 0 input channels, 2 output channels, VM kept alive with no shreds (VM_HALT 0).
- Pharo side, set once in initialize: bufferFrames 256, used by startAudio.

Parameters must be changed before init. Typical use:

```language=Pharo
	PhuckVM uniqueInstance
		init;
		start;
		startAudio.
```
Rules inherited from the shim:
- nothing calls back into Pharo: events and console are polled;
- setters apply at the next audio block;
- getters are asynchronous: request, wait until ready, read, free.

Call release to stop audio and free the C VM
"
Class {
	#name : 'PhuckVM',
	#superclass : 'PhuckBaseObject',
	#instVars : [
		'vm',
		'bufferFrames'
	],
	#classVars : [
		'UniqueInstance'
	],
	#category : 'PhuckFFI-Base',
	#package : 'PhuckFFI',
	#tag : 'Base'
}

{ #category : 'instance creation' }
PhuckVM class >> new [
	self error: 'PhuckVM is a singleton, use PhuckVM uniqueInstance'
]

{ #category : 'initialization' }
PhuckVM class >> reset [
"reset frees the C VM and lets the next uniqueInstance create a fresh one: useful between tests and after an image restart. Offline rendering then goes through the same instance (stop audio first, then phuck_run)."
	UniqueInstance ifNotNil: [ :vm | vm release ].
	UniqueInstance := nil
]

{ #category : 'instance creation' }
PhuckVM class >> uniqueInstance [
	^ UniqueInstance ifNil: [ UniqueInstance := self basicNew initialize ]

]

{ #category : 'initialization' }
PhuckVM >> initialize [

	super initialize.
	bufferFrames := 256.
	self vm
]

{ #category : 'accessing' }
PhuckVM >> inputChannels: anInteger [  
self paramInt: 'INPUT_CHANNELS' put: anInteger
]

{ #category : 'accessing' }
PhuckVM >> keepAlive [                 
self paramInt: 'VM_HALT' put: 0
]

{ #category : 'accessing' }
PhuckVM >> lib [
	^ LibPhuck uniqueInstance
]

{ #category : 'accessing' }
PhuckVM >> outputChannels: anInteger [ 
self paramInt: 'OUTPUT_CHANNELS' put: anInteger
]

{ #category : 'accessing' }
PhuckVM >> paramInt: aKey put: anInteger [
	(self lib phuck_set_param_intCk: self handle key: aKey v: anInteger) = 1
		ifFalse: [ self error: 'cannot set ' , aKey ]

]

{ #category : 'running' }
PhuckVM >> releaseVM [

	handle ifNil: [ ^ self ].
	self stopAudio.
	self lib phuck_free: handle.
	handle := nil
]

{ #category : 'accessing' }
PhuckVM >> removeShred: anId [  self lib phuck_remove_shredCk: self handle shredId: anId

]

{ #category : 'accessing' }
PhuckVM >> sampleRate: anInteger [     
self paramInt: 'SAMPLE_RATE' put: anInteger
]

{ #category : 'defaults' }
PhuckVM >> setDefaults [
	self
		sampleRate: 48000;
		inputChannels: 0;
		outputChannels: 2;
		keepAlive
]

{ #category : 'running' }
PhuckVM >> startAudio [
	self startAudio: bufferFrames
]

{ #category : 'running' }
PhuckVM >> startAudio: frames [
	(self lib phuck_audio_startCk: self handle bufferFrames: frames) = 1
		ifFalse: [ self error: 'audio start failed' ]
]

{ #category : 'running' }
PhuckVM >> stopAudio [  self lib phuck_audio_stop: self handle
]

{ #category : 'accessing' }
PhuckVM >> vm [ 
(vm isNil or: [ vm isNull ]) ifTrue: [
		vm := self lib phuck_new.
		self setDefaults ].
	^ vm
]
