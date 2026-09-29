"
I am the Pharo-side facade to a *ChucK* virtual machine running in _libphuck_.

I own a Phuck handle and hide the raw LibPhuck calls: VM setup and parameters, starting and stopping audio, compiling code into shreds, setting and reading globals, events and console output.

Use PhuckVM default for the single realtime VM (*ChucK*''s audio layer allows only one per process). Offline instances, driven block by block with render:, can be created for tests.

Rules inherited from the shim:
- nothing calls back into Pharo: events and console are polled;
- setters apply at the next audio block;
- getters are asynchronous: request, wait until ready, read, free.

After an image restart my handle is null: I recreate the VM on first use. Call release to stop audio and free the VM.
"
Class {
	#name : 'PhuckVM',
	#superclass : 'PhuckBaseObject',
	#instVars : [
		'vm'
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

{ #category : 'accessing' }
PhuckVM >> vm [ 
(vm isNil or: [ vm isNull ]) ifTrue: [
		vm := self lib phuck_new.
		self setDefaults ].
	^ vm
]
