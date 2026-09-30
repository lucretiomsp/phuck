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
		'library',
		'chuck',
		'sampleRate',
		'bufferFrames',
		'audioRunning',
		'globals'
	],
	#classVars : [
		'UniqueInstance'
	],
	#category : 'PhuckFFI-Core',
	#package : 'PhuckFFI',
	#tag : 'Core'
}

{ #category : 'instance creation' }
PhuckVM class >> new [
	self error: 'PhuckVM is a singleton, use PhuckVM uniqueInstance or PhuckVM offline'
]

{ #category : 'instance creation' }
PhuckVM class >> offline [
	"A VM without sound card, for tests and rendering. Protocol: instance creation."
	^ self basicNew
		initialize;
		bootVM;
		yourself
]

{ #category : 'initialization' }
PhuckVM class >> reset [
	"reset frees the C VM and lets the next uniqueInstance create a fresh one: useful between tests and after an image restart. Offline rendering then goes through the same instance (stop audio first, then phuck_run)."

	UniqueInstance ifNotNil: [ :vm | vm releaseVM ].
	UniqueInstance := nil
]

{ #category : 'instance creation' }
PhuckVM class >> uniqueInstance [
	^ UniqueInstance ifNil: [
		UniqueInstance := self basicNew
			initialize;
			start;
			yourself ]
]

{ #category : 'accessing' }
PhuckVM >> bootVM [
	"VM only, no sound card: enough for offline rendering and tests."
	self isRunning ifTrue: [ ^ self ].
	chuck := library phuck_new.
	library
		phuck_set_param_intCk: chuck key: 'SAMPLE_RATE' v: sampleRate;
		phuck_set_param_intCk: chuck key: 'INPUT_CHANNELS' v: 0;
		phuck_set_param_intCk: chuck key: 'OUTPUT_CHANNELS' v: 2;
		phuck_set_param_intCk: chuck key: 'VM_HALT' v: 0.
	(library phuck_init: chuck) = 1 ifFalse: [ ^ self failBoot: 'ChucK init failed' ].
	(library phuck_start: chuck) = 1 ifFalse: [ ^ self failBoot: 'ChucK start failed' ]
]

{ #category : 'accessing' }
PhuckVM >> bufferFrames: anInteger [
	self isRunning ifTrue: [ ^ self error: 'Set the buffer size before start' ].
	bufferFrames := anInteger
]

{ #category : 'running' }
PhuckVM >> compile: aString [
	"Spork aString, answer the shred id. Protocol: running."
	| id |
	self ensureRunning.
	id := library phuck_compile_codeCk: chuck code: aString args: ''.
	id = 0 ifTrue: [ ^ self error: 'ChucK compile error: ' , self output ].
	self registerGlobalsIn: aString.
	^ id
]

{ #category : 'testing' }
PhuckVM >> ensureRunning [
	self isRunning ifFalse: [ self error: 'PhuckVM is not running' ]
]

{ #category : 'accessing' }
PhuckVM >> failBoot: aString [
	library phuck_free: chuck.
	chuck := nil.
	^ self error: aString
]

{ #category : 'parameters' }
PhuckVM >> globalTypeOf: aString ifAbsent: aBlock [
	^ globals at: aString asString ifAbsent: aBlock
]

{ #category : 'initialization' }
PhuckVM >> initialize [
	super initialize.
	library := LibPhuck uniqueInstance.
	sampleRate := 48000.
	bufferFrames := 256.
	audioRunning := false.
	globals := Dictionary new
]

{ #category : 'accessing' }
PhuckVM >> inputChannels: anInteger [  
self paramInt: 'INPUT_CHANNELS' put: anInteger
]

{ #category : 'testing' }
PhuckVM >> isAudioRunning [
	^ audioRunning
]

{ #category : 'testing' }
PhuckVM >> isRunning [
	^ chuck notNil
]

{ #category : 'accessing' }
PhuckVM >> keepAlive [                 
self paramInt: 'VM_HALT' put: 0
]

{ #category : 'logging' }
PhuckVM >> output [
	"Drain chout / cherr."
	| buffer size |
	self ensureRunning.
	buffer := ByteArray new: 4096.
	size := library phuck_read_outputCk: chuck buf: buffer cap: buffer size.
	^ (buffer copyFrom: 1 to: size) utf8Decoded
]

{ #category : 'accessing' }
PhuckVM >> outputChannels: anInteger [ 
self paramInt: 'OUTPUT_CHANNELS' put: anInteger
]

{ #category : 'accessing' }
PhuckVM >> paramInt: aKey put: anInteger [
	(library phuck_set_param_intCk: chuck key: aKey v: anInteger) = 1
		ifFalse: [ self error: 'cannot set ' , aKey ]
]

{ #category : 'parameters' }
PhuckVM >> registerGlobalsIn: aString [
	| matcher |
	matcher := 'global\s+(int|float|string)\s+(\w+)' asRegex.
	matcher matchesIn: aString do: [ :each |
		globals
			at: (matcher subexpression: 3)
			put: (matcher subexpression: 2) asSymbol ]
]

{ #category : 'accessing' }
PhuckVM >> releaseVM [
	chuck ifNil: [ ^ self ].
	self stopAudio.
	library phuck_free: chuck.
	chuck := nil.
	UniqueInstance == self ifTrue: [ UniqueInstance := nil ]
]

{ #category : 'accessing' }
PhuckVM >> removeShred: anId [
	self ensureRunning.
	^ (library phuck_remove_shredCk: chuck shredId: anId) = 1
]

{ #category : 'running' }
PhuckVM >> run: aString [
	^ PhuckShred new
		vm: self id: (self compile: aString) source: aString;
		yourself
]

{ #category : 'initialization' }
PhuckVM >> sampleRate: anInteger [
	self isRunning ifTrue: [ ^ self error: 'Set the sample rate before start' ].
	sampleRate := anInteger
]

{ #category : 'defaults' }
PhuckVM >> setDefaults [
	self
		sampleRate: 48000;
		inputChannels: 0;
		outputChannels: 2;
		keepAlive
]

{ #category : 'parameters' }
PhuckVM >> setFloat: aNumber parameter: aString [
	library phuck_set_floatCk: chuck name: aString asString v: aNumber asFloat
]

{ #category : 'parameters' }
PhuckVM >> setInt: aNumber parameter: aString [
	library phuck_set_intCk: chuck name: aString asString v: aNumber asInteger
]

{ #category : 'parameters' }
PhuckVM >> setString: aString parameter: aName [
	library phuck_set_stringCk: chuck name: aName asString v: aString asString
]

{ #category : 'parameters' }
PhuckVM >> setValue: aValue parameter: aString [
	"Dispatch on the declared ChucK type, or on the value's class if the global is unknown."
	| type |
	self ensureRunning.
	type := self globalTypeOf: aString ifAbsent: [ aValue phuckGlobalType ].
	type = #float ifTrue: [ ^ self setFloat: aValue parameter: aString ].
	type = #int ifTrue: [ ^ self setInt: aValue parameter: aString ].
	type = #string ifTrue: [ ^ self setString: aValue parameter: aString ].
	self error: 'Unsupported ChucK global type: ' , type
]

{ #category : 'accessing' }
PhuckVM >> start [
	"Boot the VM and open the sound card."
	self
		bootVM;
		startAudio
]

{ #category : 'accessing' }
PhuckVM >> startAudio [
	self ensureRunning.
	audioRunning ifTrue: [ ^ self ].
	(library phuck_audio_startCk: chuck bufferFrames: bufferFrames) = 1
		ifFalse: [ ^ self error: 'Could not open the audio device' ].
	audioRunning := true
]

{ #category : 'accessing' }
PhuckVM >> stopAudio [
	audioRunning ifFalse: [ ^ self ].
	library phuck_audio_stop: chuck.
	audioRunning := false
]
