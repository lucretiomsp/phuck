"
TurboSampleCodegen comment: 'I turn the folders of TurboSamples into ChucK code: one player per subfolder, so a new folder needs no change in the template.

A folder becomes a ZdLoopPlayer when one of its files has a bpm tag, a | in the file name like amen|170.wav (the tag ZdLoopPlayer reads). Every other folder becomes a ZdSampler. Hidden folders are skipped, the rest is taken in alphabetical order.

I fill four markers of a ChucK template, each one must appear exactly once:
- //@GLOBALS: Note, Gate, Index and Level of each player, plus Reverse, Position, Slice and Length for loops
- //@GRAPH: the player declaration, loaded from turbo + the folder name
- //@UPDATES: the update call of each player, inside the control loop
- //@EVENTS: one trigEvent line per player

The template defines the rest: ZdSampler, ZdLoopPlayer, master, performanceBPM, trigEvent and turbo (the TurboSamples path, the caller replaces TURBO_ROOT after expand:).

Typical use, with samplesFolder the TurboSamples directory and template the ChucK source:

```language=Pharo
	TurboSampleCodegen new
		root: samplesFolder;
		expand: template
```

The ChucK name of a folder is its name reduced to ASCII letters and digits, starting with a letter (hi-hat gives hihat). The path keeps the real name. I raise an error for two folders with the same name, a name the template already declares (hoover, bell), a missing marker, or a folder without a usable name.

report tells what each folder becomes. Check it after adding a folder: a loop folder without any tagged file becomes a sampler, without a warning.'
"
Class {
	#name : 'TurboSampleCodegen',
	#superclass : 'Object',
	#instVars : [
		'root'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'helpers' }
TurboSampleCodegen >> checkNames: names against: aTemplate [
	"catches clashes with what the template already declares, e.g. a folder named hoover or bell"
	names do: [ :each |
		(names occurrencesOf: each) > 1
			ifTrue: [ self error: 'two folders give the name ', each ].
		(aTemplate includesSubstring: ' ', each, 'Gain')
			ifTrue: [ self error: each, ' is already declared in the template' ] ]
]

{ #category : 'helpers' }
TurboSampleCodegen >> eventFor: aFolder [
	^ '    trigEvent("<1s>", <1s>Gate, <1s>Note);' expandMacrosWith: (self nameFor: aFolder)
]

{ #category : 'helpers' }
TurboSampleCodegen >> expand: aTemplate [
	| code |
	self
		checkNames: (self folders collect: [ :each | self nameFor: each ])
		against: aTemplate.
	code := aTemplate.
	#('//@GLOBALS' globalsFor: '//@GRAPH' graphFor: '//@UPDATES' updateFor: '//@EVENTS' eventFor:)
		pairsDo: [ :marker :selector |
			(code includesSubstring: marker)
				ifFalse: [ self error: 'template has no ', marker ].
			code := code copyReplaceAll: marker with: (self join: selector) ].
	^ code
]

{ #category : 'helpers' }
TurboSampleCodegen >> folders [
	"visible subfolders, alphabetical so the output is stable between runs"
	^ (root directories reject: [ :each | each basename beginsWith: '.' ])
		sorted: [ :a :b | a basename <= b basename ]
]

{ #category : 'helpers' }
TurboSampleCodegen >> globalsFor: aFolder [
	^ ((self isLoop: aFolder)
		ifTrue: [ '60 => global int <1s>Note; 0 => global int <1s>Gate; 0 => global int <1s>Index; 0.4 => global float <1s>Gain; 0 => global int <1s>Reverse; 0 => global float <1s>Position; -1 => global float <1s>Slice; 0 => global float <1s>Length;' ]
		ifFalse: [ '60 => global int <1s>Note; global int <1s>Gate; global int <1s>Index; 0.4 => global float <1s>Gain;' ])
			expandMacrosWith: (self nameFor: aFolder)
]

{ #category : 'helpers' }
TurboSampleCodegen >> graphFor: aFolder [
	^ '<1s> <2s>(turbo + "/<3s>") => master;'
		expandMacrosWith: (self playerClassFor: aFolder)
		with: (self nameFor: aFolder)
		with: aFolder basename
]

{ #category : 'helpers' }
TurboSampleCodegen >> isLoop: aFolder [
	"a loop folder holds at least one file with a bpm tag, like amen|170.wav"
	^ aFolder files anySatisfy: [ :each | each basename includes: $| ]
]

{ #category : 'helpers' }
TurboSampleCodegen >> join: aSelector [
	"one generated line per folder, with Pharo line endings like the template"
	^ String streamContents: [ :stream |
		self folders
			do: [ :each | stream << (self perform: aSelector with: each) ]
			separatedBy: [ stream cr ] ]

]

{ #category : 'helpers' }
TurboSampleCodegen >> nameFor: aFolder [
	"folder name as a ChucK identifier"
	| name |
	name := aFolder basename select: [ :c | c isAlphaNumeric and: [ c asInteger < 128 ] ].
	(name notEmpty and: [ name first isLetter ])
		ifFalse: [ self error: 'no ChucK name possible for folder ', aFolder basename ].
	^ name
]

{ #category : 'helpers' }
TurboSampleCodegen >> playerClassFor: aFolder [
	^ (self isLoop: aFolder) ifTrue: [ 'ZdLoopPlayer' ] ifFalse: [ 'ZdSampler' ]
]

{ #category : 'helpers' }
TurboSampleCodegen >> report [
	"what every folder becomes, worth a look after adding one"
	^ String streamContents: [ :stream |
		self folders
			do: [ :each | stream << each basename << ' : ' << (self playerClassFor: each) ]
			separatedBy: [ stream cr ] ]
]

{ #category : 'accessing' }
TurboSampleCodegen >> root: aFileReference [
	root := aFileReference
]

{ #category : 'helpers' }
TurboSampleCodegen >> updateFor: aFolder [
	^ ((self isLoop: aFolder)
		ifTrue: [ '    <1s>.update(<1s>Note, <1s>Gate, <1s>Index, performanceBPM, <1s>Gain, <1s>Reverse, <1s>Position, <1s>Slice, <1s>Length);' ]
		ifFalse: [ '    <1s>.update(<1s>Note, <1s>Gate, <1s>Index, <1s>Gain);' ])
			expandMacrosWith: (self nameFor: aFolder)
]
