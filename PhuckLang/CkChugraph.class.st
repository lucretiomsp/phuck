"
I am a reusable subgraph. Subclass me and implement the template method buildFrom: inlet to: outlet, answering the chain between them:

	(CkChugraph << #CkMyVoice package: 'MyMusic') install.
	CkMyVoice >> buildFrom: inlet to: outlet [
		^ inlet => (CkLPF new freq: 800) => outlet ]

Each Pharo subclass becomes one ChucK class, defined once per program however many instances are used:

	class MyVoice extends Chugraph { inlet => LPF lpf1 => outlet; 800 => lpf1.freq; }
	SinOsc sin1 => MyVoice myvoice1 => dac;

Inside, only constant params are allowed (no sliders, no expressions); set gain etc. on the instance as on any UGen.
"
Class {
	#name : 'CkChugraph',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'building' }
CkChugraph >> buildFrom: inlet to: outlet [
	"Template method for subclasses: answer the chain (or chains joined with ,)
	running from inlet to outlet:
		^ inlet => (CkLPF new freq: 800) => outlet"

	self subclassResponsibility
]

{ #category : 'printing' }
CkChugraph >> ckTypeIn: aWriter [
	"One ChucK class per Pharo subclass, shared by all its instances"

	^ aWriter
		  defineClassFor: self class
		  named: self ckClassName
		  extends: 'Chugraph'
		  with: [ :members | (self buildFrom: CkPort inlet to: CkPort outlet) ckWritePartOn: members ]
]
