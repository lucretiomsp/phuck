"
I test the Turbo rig (TurboLibrary, TurboMaster, TurboVoice and its subclasses, TurboRig) without sound: the generated ChucK is checked as text, and compiled in a PhuckVM offline when a test asks for vm. Sample folders are built in a memory file system, so the tests do not need TurboSamples.
"
Class {
	#name : 'TurboRigTest',
	#superclass : 'TestCase',
	#instVars : [
		'vm'
	],
	#category : 'Phuck-Tests-TurboPhuck',
	#package : 'Phuck-Tests',
	#tag : 'TurboPhuck'
}

{ #category : 'running' }
TurboRigTest >> compile: aString [
	"compile signals 'ChucK compile error' when ChucK rejects the code"

	self assert: (self vm compile: aString) > 0
]

{ #category : 'running' }
TurboRigTest >> loadLibrary [

	self compile: TurboLibrary new code.
	self compile: TurboMaster new code
]

{ #category : 'running' }
TurboRigTest >> rig [

	^ TurboRig new root: self samplesRoot
]

{ #category : 'running' }
TurboRigTest >> samplesRoot [
	"kick: one-shots, breaks: a loop (bpm tag), hi-hat: a name to clean"

	| root |
	root := FileSystem memory root / 'TurboSamples'.
	(root / 'kick') ensureCreateDirectory.
	root / 'kick' / 'k1.wav' writeStreamDo: [ :s | s << 'x' ].
	(root / 'breaks') ensureCreateDirectory.
	root / 'breaks' / 'amen|170.wav' writeStreamDo: [ :s | s << 'x' ].
	(root / 'hi-hat') ensureCreateDirectory.
	root / 'hi-hat' / 'h1.wav' writeStreamDo: [ :s | s << 'x' ].
	(root / '.hidden') ensureCreateDirectory.
	^ root
]

{ #category : 'running' }
TurboRigTest >> tearDown [

	vm ifNotNil: [ vm releaseVM ].
	super tearDown
]

{ #category : 'tests - code' }
TurboRigTest >> testANewVoiceIsNotSporked [

	| hoover |
	hoover := TurboHoover new.
	self deny: hoover isSporked.
	self assert: hoover printString equals: 'TurboHoover(hoover)'.
	self assert: self rig sporked isEmpty.
	#( #play #stop #isPlaying ) do: [ :each | self deny: (TurboVoice canUnderstand: each) ]
]

{ #category : 'tests - vm' }
TurboRigTest >> testAVoiceCanBeCompiledTwice [
	"play again swaps the code: a voice shred defines no class, only the library is public, so nothing clashes"

	| hoover |
	self loadLibrary.
	hoover := TurboHoover new.
	self compile: hoover code.
	self compile: hoover code
]

{ #category : 'tests - vm' }
TurboRigTest >> testEveryVoiceCompiles [

	self loadLibrary.
	self rig voices do: [ :each | self compile: each code ]
]

{ #category : 'tests - code' }
TurboRigTest >> testEveryVoiceDeclaresItsGlobalsAsFloat [

	self rig voices do: [ :voice |
			| code |
			code := voice code.
			voice globals do: [ :each | self assert: (code includesSubstring: ' => global float ' , voice name , each key , ';') ] ]
]

{ #category : 'tests - code' }
TurboRigTest >> testEveryVoicePlaysIntoTheMaster [

	self rig voices do: [ :voice |
			| code |
			code := voice code.
			self assert: (code includesSubstring: 'global Gain master;').
			self assert: (code includesSubstring: voice declaration , ' => master;').
			self assert: (code includesSubstring: 'TurboOsc event("' , voice name , '");') ]
]

{ #category : 'tests - code' }
TurboRigTest >> testFolderNamesBecomeChuckNames [

	self assert: (ZdSampler folder: self samplesRoot / 'hi-hat') name equals: 'hihat'.
	self assert: (ZdSampler folder: self samplesRoot / 'kick' name: 'kick2') name equals: 'kick2'
]

{ #category : 'tests - code' }
TurboRigTest >> testKick99PlaysAnOctaveDown [

	| code |
	code := TurboKick99 new code.
	self assert: (code includesSubstring: 'v.tick(kick99Note - 12, kick99Gate').
	self assert: (code includesSubstring: 'event.tick(kick99Gate, kick99Note - 12);')
]

{ #category : 'tests - vm' }
TurboRigTest >> testLibraryCompilesOnlyOnce [

	| library |
	library := TurboLibrary new.
	self deny: (library isLoadedIn: self vm).
	self compile: library code.
	self assert: (library isLoadedIn: self vm).
	"a public class cannot be defined twice in the same VM"
	self should: [ self vm compile: library code ] raise: Error
]

{ #category : 'tests - code' }
TurboRigTest >> testLibraryMakesEveryClassPublic [

	| code |
	code := TurboLibrary new code.
	self assert: (code lines count: [ :each | each beginsWith: 'public class ' ]) equals: 15.
	self deny: (code lines anySatisfy: [ :each | each beginsWith: 'class ' ])
]

{ #category : 'tests - code' }
TurboRigTest >> testLibraryPutsSuperclassesFirst [
	"ZdFiles (ZdPlayer) must come before ZdSampler and ZdLoopPlayer, which use it"

	| owners |
	owners := TurboLibrary new owners.
	self assert: (owners indexOf: ZdPlayer) < (owners indexOf: ZdSampler).
	self assert: (owners indexOf: ZdPlayer) < (owners indexOf: ZdLoopPlayer).
	self assert: (owners indexOf: TurboVoice) equals: 1
]

{ #category : 'tests - code' }
TurboRigTest >> testLoopPlayerDoesNotResetTheTempo [
	"performanceBPM belongs to the master: a loop declares it without a value"

	| code |
	code := (self rig at: 'breaks') code.
	self assert: (code includesSubstring: String cr , 'global float performanceBPM;').
	self assert: (code includesSubstring: 'breaksIndex, performanceBPM, breaksReverse')
]

{ #category : 'tests - vm' }
TurboRigTest >> testMasterCompiles [

	self loadLibrary.
	self assert: (self vm globalTypeOf: 'masterGain' ifAbsent: [ nil ]) equals: #float.
	self assert: (self vm globalTypeOf: 'performanceBPM' ifAbsent: [ nil ]) equals: #float
]

{ #category : 'tests - code' }
TurboRigTest >> testMoogKeepsItsSettings [

	| moog |
	moog := TurboStk named: 'moog'.
	self assert: (moog code includesSubstring: 'Moog inst;').
	self assert: (moog code includesSubstring: '0 => inst.filterQ;').
	self assert: (moog globals detect: [ :each | each key = 'Gain' ]) value equals: 0.7.
	self assert: ((TurboStk named: 'bell') globals detect: [ :each | each key = 'Gain' ]) value equals: 0.5
]

{ #category : 'tests - code' }
TurboRigTest >> testParametersCarryTheVoiceName [

	self assert: ((TurboStk named: 'bell') parameter: 'Gate') equals: 'bellGate'.
	self assert: (TurboAcid new parameter: 'Cutoff') equals: 'acidCutoff'.
	self assert: ((TurboHoover named: 'hoover2') parameter: 'Note') equals: 'hoover2Note'
]

{ #category : 'tests - code' }
TurboRigTest >> testRelativeFolderStartsAtTheImage [

	self
		assert: (ZdSampler folder: 'TurboSamples/kick') folder
		equals: FileLocator imageDirectory asFileReference / 'TurboSamples' / 'kick'
]

{ #category : 'tests - code' }
TurboRigTest >> testRigHasTheOldVoiceNames [

	| names |
	names := self rig names.
	self assert: names size equals: 12 + 7 + 3.
	self assert: names asSet size equals: names size.
	#( 'bell' 'moog' 'beeThree' 'sitar' 'hoover' 'acid' 'reese' 'kick99' 'psgPlus' 'fm2Op' 'chordy' 'kick' 'breaks' 'hihat' ) do: [
		:each | self assert: (names includes: each) ]
]

{ #category : 'tests - code' }
TurboRigTest >> testRigPicksThePlayerOfEachFolder [

	| rig |
	rig := self rig.
	self assert: (rig at: 'kick') class equals: ZdSampler.
	self assert: (rig at: 'hihat') class equals: ZdSampler.
	self assert: (rig at: 'breaks') class equals: ZdLoopPlayer
]

{ #category : 'tests - code' }
TurboRigTest >> testRigRefusesTwoVoicesWithOneName [
	"a sample folder called bell would share its globals with the STK bell"

	| root |
	root := self samplesRoot.
	(root / 'bell') ensureCreateDirectory.
	self should: [ (TurboRig new root: root) voices ] raise: Error
]

{ #category : 'tests - code' }
TurboRigTest >> testTickTakesOneArgumentPerGlobal [

	self rig voices do: [ :voice | self assert: voice tickArguments size equals: voice globals size + voice sharedGlobals size ]
]

{ #category : 'tests - vm' }
TurboRigTest >> testVoiceGlobalsAreRegisteredAsFloat [
	"so setValue:parameter: sends floats, also for Index and Gate"

	self loadLibrary.
	self rig voices do: [ :voice |
			self compile: voice code.
			voice globals do: [ :each | self assert: (self vm globalTypeOf: (voice parameter: each key) ifAbsent: [ nil ]) equals: #float ] ]
]

{ #category : 'running' }
TurboRigTest >> vm [
	"a VM without sound card, booted only by the tests that compile"

	^ vm ifNil: [ vm := PhuckVM offline ]
]
