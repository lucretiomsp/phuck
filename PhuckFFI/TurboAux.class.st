"
I am an effect on an auxiliary bus of the rig, run once in my own shred: every voice sends into my global Gain <name>Bus through its own send level, the global float <voice><Name>Send (hooverDelaySend), and I play my return back into the master bus, so the master pitch shift, high-pass and limiter take me too.

```language=Pharo
	TurboDelay default spork.
	(TurboPhuckRig default at: 'hoover') send: 0.4 to: 'delay'.
	TurboDelay default time: 0.375; feedback: 0.5; returnLevel: 0.7.
```
A send starts at 0, so a voice sounds as before until its send is turned up; it is post-fader, after the voice Gain. My concrete subclasses are the auxes of the rig (TurboAux all), each voice shred is built with one send per aux: spork the voices again after adding one.

A subclass gives defaultName, globals (suffix -> default), ranges (suffix -> { min. max. step }, the ranges of my knobs, which clamped: also applies in ChucK), graphCode (ChucK from <name>Bus, called in, into master) and tickCode (run every ms).
"
Class {
	#name : 'TurboAux',
	#superclass : 'TurboModule',
	#classInstVars : [
		'default'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'accessing' }
TurboAux class >> all [
	"the auxes of the rig, one default instance per concrete subclass; every voice sends into each of them"

	^ (self allSubclasses reject: [ :each | each isAbstract ]) collect: [ :each | each default ]
]

{ #category : 'instance creation' }
TurboAux class >> default [
	"the one bus of the VM"

	^ default ifNil: [ default := self new ]
]

{ #category : 'testing' }
TurboAux class >> isAbstract [

	^ self == TurboAux
]

{ #category : 'instance creation' }
TurboAux class >> named: aName [

	^ self all detect: [ :each | each name = aName ] ifNone: [ self error: 'no aux named ' , aName ]
]

{ #category : 'instance creation' }
TurboAux class >> reset [

	default := nil.
	self subclasses do: [ :each | each reset ]
]

{ #category : 'accessing' }
TurboAux >> bus [
	"the global Gain the voices send into: delayBus"

	^ self name , 'Bus'
]

{ #category : 'chuck code' }
TurboAux >> clamped: aSuffix [
	"the ChucK expression of my global for aSuffix kept inside its range"

	^ 'Math.max(' , (self minOf: aSuffix) printString , ', Math.min(' , (self maxOf: aSuffix) printString , ', '
	  , (self parameter: aSuffix) , '))'
]

{ #category : 'chuck code' }
TurboAux >> code [
	"my globals, my bus played through graphCode into the master, tickCode every ms"

	^ String streamContents: [ :stream |
			  self globals do: [ :each |
					  stream
						  print: each value;
						  << ' => global float ';
						  << (self parameter: each key);
						  << ';';
						  cr ].
			  stream
				  << 'global Gain master;';
				  cr;
				  << 'global Gain ';
				  << self bus;
				  << ';';
				  cr;
				  << self bus;
				  << ' => Gain in;';
				  cr;
				  << self graphCode;
				  cr;
				  cr;
				  << 'while (1::ms => now)';
				  cr;
				  << '{';
				  cr.
			  self tickCode lines do: [ :each |
					  stream
						  << '    ';
						  << each;
						  cr ].
			  stream
				  << '}';
				  cr ]
]

{ #category : 'accessing' }
TurboAux >> defaultName [

	^ self subclassResponsibility
]

{ #category : 'chuck code' }
TurboAux >> globals [
	"suffix -> default of my ChucK globals, with my name in front: delayFeedback"

	^ self subclassResponsibility
]

{ #category : 'chuck code' }
TurboAux >> graphCode [
	"ChucK from in (my bus) into master"

	^ self subclassResponsibility
]

{ #category : 'accessing' }
TurboAux >> label [

	^ self class name , '(' , self name , ')'
]

{ #category : 'chuck code' }
TurboAux >> maxOf: aSuffix [

	^ (self ranges at: aSuffix) second asFloat
]

{ #category : 'chuck code' }
TurboAux >> minOf: aSuffix [

	^ (self ranges at: aSuffix) first asFloat
]

{ #category : 'accessing' }
TurboAux >> name [
	"the prefix of my ChucK globals and of my bus: delayFeedback, delayBus"

	^ self defaultName
]

{ #category : 'parameters' }
TurboAux >> parameter: aSuffix [

	^ self name , aSuffix
]

{ #category : 'running' }
TurboAux >> prepare [
	"the library and the master bus I play into"

	TurboLibrary default isLoaded ifFalse: [
			TurboMaster default forgetShred.
			self forgetShred.
			TurboLibrary default spork ].
	TurboMaster default isSporked ifFalse: [ TurboMaster default spork ]
]

{ #category : 'chuck code' }
TurboAux >> ranges [
	"suffix -> { min. max. step } of each of my globals: the ranges of my knobs, clamped in ChucK too"

	^ self subclassResponsibility
]

{ #category : 'parameters' }
TurboAux >> returnLevel: aNumber [
	"how much of me goes back into the master"

	self set: 'Return' to: aNumber
]

{ #category : 'accessing' }
TurboAux >> sendSuffix [
	"the suffix of the send level of each voice: hooverDelaySend"

	^ self name capitalized , 'Send'
]

{ #category : 'parameters' }
TurboAux >> set: aSuffix to: aNumber [

	self vm setValue: aNumber parameter: (self parameter: aSuffix)
]

{ #category : 'chuck code' }
TurboAux >> tickCode [
	"ChucK lines run every ms, reading my globals"

	^ self subclassResponsibility
]
