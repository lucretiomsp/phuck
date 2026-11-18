"
I am a UGen computing every sample with an expression written in Pharo.

	CkSinOsc new => (CkChugen tick: [ :in | in * 0.5 ]) => CkDac new

prints a class of my own and an instance of it:

	class Chugen1 extends Chugen { fun float tick(float in) { return in * 0.5; } }
	SinOsc sin1 => Chugen1 chugen1 => dac;

in is a CkArg. The block may only use in, numbers and arithmetic: a ChucK class cannot see the UGens of the file, so the CkClassBodyWriter refuses them.
"
Class {
	#name : 'CkChugen',
	#superclass : 'CkUGen',
	#instVars : [
		'tickBlock'
	],
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'instance creation' }
CkChugen class >> tick: aBlock [
	"A UGen computing each sample in ChucK from the block's expression:
		CkChugen tick: [ :in | in * 0.5 ]
	in is a CkArg. Only in, numbers and arithmetic may appear"

	^ self new setTickBlock: aBlock
]

{ #category : 'printing' }
CkChugen >> ckTypeIn: aWriter [
	"Every Chugen has its own tick, so its own class: Chugen1, Chugen2, ..."

	^ aWriter
		  defineClassFor: self
		  named: 'Chugen'
		  extends: 'Chugen'
		  with: [ :members | members nextPutAll: (self tickFunctionIn: members) ]
]

{ #category : 'initialization' }
CkChugen >> setTickBlock: aBlock [
	"aBlock takes the input sample (a CkArg) and answers the output expression"

	tickBlock := aBlock
]

{ #category : 'printing' }
CkChugen >> tickFunctionIn: aWriter [
	"fun float tick(float in) { return <expression>; }"

	^ String streamContents: [ :s |
			  s
				  nextPutAll: 'fun float tick(float in) {';
				  lf;
				  nextPutAll: '  return ' , ((tickBlock value: (CkArg named: 'in')) ckReturnCodeIn: aWriter) , ';';
				  lf;
				  nextPutAll: '}';
				  lf ]
]
