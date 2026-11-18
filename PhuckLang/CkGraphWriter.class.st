"
I am the Builder that turns parts into ChucK source. Parts visit me (ckWritePartOn:), UGens and values tell me what to write (double dispatch), and I keep the sections in order:

	globals    global float sqr1Gain;          sliders, declared once
	classes    class Chugen1 extends Chugen { ... }   Chugen and Chugraph definitions
	body       SinOsc sin1 => dac;             chains, silent UGens on blackhole
	inits      440 => sin1.freq;               constant params, run once
	shreds     fun void shred1() { ... } spork ~ shred1();
	loop       while (1) { expressions and sliders; period => now; }

The main loop always exists: it keeps the program, and so its sporked shreds, alive.

I also own naming for one program: declared maps each UGen to its name, taken holds every name used, counters numbers automatic names per prefix, and classNames/definedClasses do the same for generated classes.
"
Class {
	#name : 'CkGraphWriter',
	#superclass : 'Object',
	#instVars : [
		'declared',
		'counters',
		'taken',
		'globals',
		'classes',
		'classNames',
		'definedClasses',
		'body',
		'inits',
		'shreds',
		'loop',
		'pending',
		'period'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'defaults' }
CkGraphWriter class >> builtinClassNames [
	"ChucK classes a generated class must not be named after"

	^ #( 'Chugen' 'Chugraph' 'UGen' 'Object' )
]

{ #category : 'defaults' }
CkGraphWriter class >> defaultPeriod [
	"How often the main loop wakes up when nobody asked with every:.
	1 ms is fast enough for parameters driven by expressions or sliders"

	^ 1 milliSecond
]

{ #category : 'adding' }
CkGraphWriter >> addGlobal: aString [
	"A slider used by several params is declared once"

	globals addIfNotPresent: aString
]

{ #category : 'adding' }
CkGraphWriter >> addInit: aString [
	"A line run once, after every UGen is declared"

	inits
		nextPutAll: aString;
		lf
]

{ #category : 'adding' }
CkGraphWriter >> addToLoop: aString [
	"A line run on every iteration of the main loop"

	loop
		nextPutAll: '  ';
		nextPutAll: aString;
		lf
]

{ #category : 'naming' }
CkGraphWriter >> autoNameFor: anObject [
	"prefix + counter, numbered per program so every asPhuck starts at sqr1.
	Skips numbers a label already took"

	| prefix candidate |
	prefix := anObject ckPrefix.
	[
		counters add: prefix.
		candidate := prefix , (counters occurrencesOf: prefix) printString.
		taken includes: candidate ] whileTrue.
	taken add: candidate.
	^ candidate
]

{ #category : 'naming' }
CkGraphWriter >> claimLabel: aString [
	"Two UGens printed with the same name would silently be one variable in ChucK"

	(taken includes: aString) ifTrue: [
		^ self error: 'The name ' , aString printString , ' is used by two UGens of the same program' ].
	taken add: aString.
	^ aString
]

{ #category : 'accessing' }
CkGraphWriter >> contents [
	"The whole program, section by section: globals first so Pharo can set
	them, classes before the UGens that use them, then the graph, the
	constant params, the sporked shreds and the main loop that keeps them all alive"

	^ String streamContents: [ :s |
			  globals do: [ :each |
					  s
						  nextPutAll: each;
						  lf ].
			  s
				  nextPutAll: classes contents;
				  nextPutAll: body contents;
				  nextPutAll: inits contents;
				  nextPutAll: shreds contents;
				  nextPutAll: 'while (1) {';
				  lf;
				  nextPutAll: loop contents;
				  nextPutAll: '  ' , period ckCode , ' => now;';
				  lf;
				  nextPutAll: '}' ]
]

{ #category : 'writing' }
CkGraphWriter >> declare: aUGen [
	"First appearance in a chain: Type name. Its params wait in pending
	until the chain line is finished"

	| type |
	type := aUGen ckTypeIn: self.
	body nextPutAll: type , ' ' , (self newNameFor: aUGen).
	pending add: aUGen
]

{ #category : 'writing' }
CkGraphWriter >> declareSilent: aUGen [
	"A UGen nobody listens to still has to tick to have a last() value"

	| type name |
	type := aUGen ckTypeIn: self.
	name := self newNameFor: aUGen.
	body
		nextPutAll: type , ' ' , name , ' => blackhole;';
		lf.
	self writeParamsOf: aUGen.
	^ name
]

{ #category : 'writing classes' }
CkGraphWriter >> define: aKey named: aClassName extends: aSuperName with: aBlock [
	"The name is recorded before the members are written, so a class that
	needs other classes defines them first and they come out above it"

	| members |
	definedClasses at: aKey put: aClassName.
	members := CkClassBodyWriter parent: self.
	aBlock value: members.
	classes
		nextPutAll: 'class ' , aClassName , ' extends ' , aSuperName , ' {';
		lf;
		nextPutAll: members contents;
		nextPutAll: '}';
		lf.
	^ aClassName
]

{ #category : 'writing classes' }
CkGraphWriter >> defineClassFor: aKey named: aBaseName extends: aSuperName with: aBlock [
	"Answer the ChucK class name for aKey, defining the class the first time.
	aBlock fills a CkClassBodyWriter with the members"

	^ definedClasses at: aKey ifAbsent: [
			  self
				  define: aKey
				  named: (self newClassName: aBaseName)
				  extends: aSuperName
				  with: aBlock ]
]

{ #category : 'initialization' }
CkGraphWriter >> initialize [
	"One section stream per part of the program, see the class comment"

	super initialize.
	declared := IdentityDictionary new.
	counters := Bag new.
	taken := Set new.
	globals := OrderedCollection new.
	classes := String new writeStream.
	classNames := self class builtinClassNames asSet.
	definedClasses := IdentityDictionary new.
	body := String new writeStream.
	inits := String new writeStream.
	shreds := String new writeStream.
	loop := String new writeStream.
	pending := OrderedCollection new.
	period := self class defaultPeriod
]

{ #category : 'naming' }
CkGraphWriter >> nameOf: aUGen [
	"Name of a UGen read by an expression. One that is read but never heard
	was not declared by a chain: it runs on blackhole"

	^ declared at: aUGen ifAbsent: [ self declareSilent: aUGen ]
]

{ #category : 'writing classes' }
CkGraphWriter >> newClassName: aBaseName [
	"aBaseName itself if free, else aBaseName1, aBaseName2, ..."

	| candidate counter |
	candidate := aBaseName.
	counter := 0.
	[ classNames includes: candidate ] whileTrue: [
			counter := counter + 1.
			candidate := aBaseName , counter printString ].
	classNames add: candidate.
	^ candidate
]

{ #category : 'naming' }
CkGraphWriter >> newNameFor: aUGen [
	"Remember the name the first time, so later mentions print the same one"

	^ declared at: aUGen put: (aUGen ckNameIn: self)
]

{ #category : 'writing' }
CkGraphWriter >> nextPutAll: aString [
	"Raw text into the graph section; used by keywords such as dac"

	body nextPutAll: aString
]

{ #category : 'accessing' }
CkGraphWriter >> period: aDuration [
	"How long the main loop waits between two iterations"

	period := aDuration
]

{ #category : 'writing' }
CkGraphWriter >> writeChain: aCollection [
	"One ChucK line per chain. Params come after the chain line, so they can
	add lines of their own (a UGen read on blackhole, a global)"

	aCollection do: [ :each | each ckWriteOn: self ] separatedBy: [ body nextPutAll: ' => ' ].
	body
		nextPutAll: ';';
		lf.
	[ pending isEmpty ] whileFalse: [ self writeParamsOf: pending removeFirst ]
]

{ #category : 'writing shreds' }
CkGraphWriter >> writeLoopOf: aRecorder [
	"Body of a shred made with CkShred loop:"

	shreds
		nextPutAll: '  while (1) {';
		lf.
	self writeStatementsOf: aRecorder indent: '    '.
	shreds
		nextPutAll: '  }';
		lf
]

{ #category : 'writing' }
CkGraphWriter >> writeParamsOf: aUGen [
	"Each value decides where its line goes: constants run once, expressions
	and sliders every loop (double dispatch on the value)"

	| ugenName |
	ugenName := declared at: aUGen.
	aUGen params keysAndValuesDo: [ :param :value | value ckWriteParam: param of: ugenName on: self ]
]

{ #category : 'writing shreds' }
CkGraphWriter >> writeShred: aShred [
	"fun void shred1() { ... } spork ~ shred1();
	The shred decides whether its statements loop"

	| recorder shredName |
	recorder := aShred record.
	shredName := self autoNameFor: aShred.
	shreds
		nextPutAll: 'fun void ' , shredName , '() {';
		lf.
	aShred ckWriteBodyOf: recorder on: self.
	shreds
		nextPutAll: '}';
		lf;
		nextPutAll: 'spork ~ ' , shredName , '();';
		lf
]

{ #category : 'writing shreds' }
CkGraphWriter >> writeStatementsOf: aRecorder indent: aString [
	"Each recorded statement prints itself (Command), resolving UGen names here"

	aRecorder statements do: [ :each |
			shreds
				nextPutAll: aString , (each ckCodeIn: self);
				lf ]
]

{ #category : 'writing' }
CkGraphWriter >> writeUGen: aUGen [
	"Declare on first appearance, refer by name afterwards: that is how one
	UGen can sit in two chains, or close a feedback loop"

	declared at: aUGen ifPresent: [ :ugenName | body nextPutAll: ugenName ] ifAbsent: [ self declare: aUGen ]
]
