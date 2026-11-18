"
I am every Pharo object that becomes a named variable in ChucK. When code is printed I answer three questions:

- What is my ChucK type? ckClassName, from my class name without Ck (CkSinOsc -> SinOsc). ckTypeIn: lets Chugens and Chugraphs define their class first.
- What is my automatic name stem? ckPrefix (SqrOsc -> sqr, LPF -> lpf).
- What is my name in this program? ckNameIn: asks the writer: my label if I have one, otherwise the next automatic name (sqr1, sqr2...).

Names belong to a program, not to me: the CkGraphWriter numbers them, so every asPhuck starts again at sqr1 and the same UGen can be printed in two programs.

	(CkSqrOsc new label: 'myOsc') => CkDac new

prints SqrOsc myOsc => dac;. A label must be a valid ChucK identifier and not a ChucK keyword or built-in (CkObject class >> identifierRules).

=> starts a CkChain.
"
Class {
	#name : 'CkObject',
	#superclass : 'Object',
	#instVars : [
		'name'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'naming' }
CkObject class >> checkIdentifier: aString [
	"Labels end up verbatim in ChucK source, so refuse anything ChucK would
	not read as a plain variable name. Answer aString when it passes every rule."

	self identifierRules
		detect: [ :rule | (rule key value: aString) not ]
		ifFound: [ :rule | self error: aString printString , rule value ].
	^ aString
]

{ #category : 'naming' }
CkObject class >> identifierRules [
	"Each rule is a test -> the complaint when it fails. They are checked in
	order and the first failure wins, so later tests may assume earlier ones
	(a non-empty string before looking at its first character)."

	^ {
		  ([ :s | s isString and: [ s isNotEmpty ] ] -> ' is not a ChucK name: it must be a non-empty string').
		  ([ :s | s first isLetter or: [ s first = $_ ] ] -> ' is not a ChucK name: it must start with a letter or _').
		  ([ :s | s allSatisfy: [ :each | each isAlphaNumeric or: [ each = $_ ] ] ]
		   -> ' is not a ChucK name: use only letters, digits and _').
		  ([ :s | (self reservedWords includes: s) not ] -> ' is a ChucK keyword or built-in and cannot be a label') }
]

{ #category : 'naming' }
CkObject class >> reservedWords [
	"Words a label may not take: ChucK keywords, types and the built-in
	objects every program already has (dac, now, ...)"

	^ #( 'if' 'else' 'while' 'until' 'for' 'repeat' 'break' 'continue' 'return' 'switch' 'case' 'class' 'extends' 'public' 'private'
	     'protected' 'static' 'pure' 'const' 'global' 'fun' 'function' 'spork' 'new' 'this' 'super' 'interface' 'implements'
	     'true' 'false' 'maybe' 'null' 'NULL' 'me' 'now' 'start' 'dac' 'adc' 'blackhole' 'inlet' 'outlet' 'pi' 'e' 'samp' 'ms' 'second'
	     'minute' 'hour' 'day' 'week' 'eon' 'int' 'float' 'time' 'dur' 'void' 'string' 'complex' 'polar' 'vec2' 'vec3' 'vec4' 'auto'
	     'Object' 'UGen' 'Event' 'Shred' 'Math' 'Std' 'Machine' 'chout' 'cherr' )
]

{ #category : 'connecting' }
CkObject >> => aUGen [
	"Start a chain: osc => dac. The chain answers itself to further =>, so
	osc => lpf => dac is one CkChain of three"

	^ CkChain new => self => aUGen
]

{ #category : 'printing' }
CkObject >> ckClassName [
	"The ChucK type I am declared with. CkSawOsc and SawOsc both print as SawOsc"

	^ self class name asString withoutPrefix: 'Ck'
]

{ #category : 'printing' }
CkObject >> ckNameIn: aWriter [
	"My variable name in the program aWriter is printing: my label, claimed so
	no other UGen can take it, or the next automatic name for my prefix"

	^ name ifNil: [ aWriter autoNameFor: self ] ifNotNil: [ :label | aWriter claimLabel: label ]
]

{ #category : 'printing' }
CkObject >> ckPrefix [
	"Stem of my automatic name. SqrOsc -> sqr, LPF -> lpf"

	^ (self ckClassName withoutSuffix: 'Osc') asLowercase
]

{ #category : 'printing' }
CkObject >> ckTypeIn: aWriter [
	"The type the writer declares me with. Most objects are a ChucK built-in
	and answer their class name; Chugens and Chugraphs override me to make the
	writer define their class first and answer its name."

	^ self ckClassName
]

{ #category : 'printing' }
CkObject >> ckWriteOn: aWriter [
	"Print myself where I appear in a chain: declared the first time, by name after"

	aWriter writeUGen: self
]

{ #category : 'printing' }
CkObject >> ckWritePartOn: aWriter [
	"Only chains, shreds and programs are parts of a program. Getting here
	almost always means a buildFrom:to: that forgot its ^"

	self error:
		'Expected a chain or a program but got ' , self printString , ' (did buildFrom:to: forget to answer its chain with ^ ?)'
]

{ #category : 'naming' }
CkObject >> label [
	"The name chosen with label:, or nil when the writer picks one (sqr1, sqr2, ...)"

	^ name
]

{ #category : 'naming' }
CkObject >> label: aString [
	"Print me as aString instead of an automatic name:
		(CkSqrOsc new label: 'myOsc') => CkDac new
	gives
		SqrOsc myOsc => dac;
	The label is used verbatim, so it is also the prefix of my slider globals (myOscGain)."

	name := self class checkIdentifier: aString
]
