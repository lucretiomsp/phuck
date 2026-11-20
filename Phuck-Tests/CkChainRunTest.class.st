Class {
	#name : 'CkChainRunTest',
	#superclass : 'TestCase',
	#instVars : [
		'vm'
	],
	#category : 'Phuck-Tests-Lang',
	#package : 'Phuck-Tests',
	#tag : 'Lang'
}

{ #category : 'running' }
CkChainRunTest >> assertCompiles: aChain [
	"run: signals 'ChucK compile error' when ChucK rejects the code"
	| shred |
	shred := vm run: aChain asPhuck.
	self assert: shred id > 0.
	shred remove
]

{ #category : 'running' }
CkChainRunTest >> setUp [
	super setUp.
	vm := PhuckVM offline
]

{ #category : 'running' }
CkChainRunTest >> tearDown [
	vm releaseVM.
	super tearDown
]

{ #category : 'tests' }
CkChainRunTest >> testClassesCompile [

	self
		assertCompiles: CkSinOsc new => (CkChugen tick: [ :in | in * 0.5 ]) => CkDac new;
		assertCompiles: CkSinOsc new => CkTestVoice new => CkDac new;
		assertCompiles: CkSinOsc new => ((CkChugraphRef ugenClass: 'NRev')
					 param: #mix put: 0.1;
					 yourself) => CkDac new
]

{ #category : 'tests' }
CkChainRunTest >> testEveryAndProgramCompile [

	self
		assertCompiles: (CkSinOsc new => CkDac new every: 100 milliSeconds);
		assertCompiles: (CkSinOsc new => CkDac new every: 10 milliSeconds) , (CkSqrOsc new => CkDac new)
]

{ #category : 'tests' }
CkChainRunTest >> testFilterQCompiles [
	"ChucK spells the resonance Q, not q"

	self
		assertCompiles: CkSawOsc new => (CkLPF new
					 freq: 800;
					 q: 3) => CkDac new;
		assertCompiles: CkSawOsc new => (CkBPF new q: (#( 1 4 8 ) ckEvery: 100 milliSeconds)) => CkDac new
]

{ #category : 'running' }
CkChainRunTest >> testGeneratedCodeCompiles [
	| delay |
	delay := CkDelay new.
	self
		assertCompiles: CkSqrOsc new => CkDac new;
		assertCompiles: (CkSqrOsc new freq: 330; sync: 1; gain: 1/2) => CkDac new;
		assertCompiles: (CkSqrOsc new gain: CkSlider new) => CkDac new;
		assertCompiles: delay => CkGain new => delay
]

{ #category : 'tests' }
CkChainRunTest >> testImpulseAndBiQuadCompile [
	"next and eqzs are real ChucK params (eqz is not)"

	| imp filter |
	imp := CkImpulse new.
	filter := CkBiQuad new
		          prad: 0.99;
		          eqzs: 1;
		          b0: 1;
		          norm: 1;
		          yourself.
	self assertCompiles: (imp next: 1.0) => filter => CkDac new.
	imp := CkImpulse new.
	filter := CkBiQuad new
		          prad: 0.99;
		          eqzs: 1;
		          yourself.
	self assertCompiles: imp => filter => CkDac new , (CkShred loop: [ :t |
				 (0 to: 30) do: [ :k |
						 imp next: 1.0.
						 filter pfreq: ((k / 10) sin abs * 400000) rounded / 100.0.
						 t wait: 100 milliSeconds ] ])
]

{ #category : 'tests' }
CkChainRunTest >> testLabelsAndSlidersCompile [

	| volume |
	volume := CkSlider label: 'volume'.
	self
		assertCompiles: ((CkSqrOsc new label: 'myOsc') gain: CkSlider new) => CkDac new;
		assertCompiles: (CkSqrOsc new gain: volume) => CkDac new , ((CkSinOsc new gain: volume) => CkDac new)
]

{ #category : 'tests' }
CkChainRunTest >> testReadUGenCompiles [
	| lfo |
	lfo := CkSinOsc new freq: 0.5.
	self assertCompiles: (CkSinOsc new freq: 440 + (lfo last * 200)) => CkDac new
]

{ #category : 'tests' }
CkChainRunTest >> testSequencesCompile [

	| m |
	m := (CkSinOsc new label: 'm')
		     freq: (#( 10 5 20 2.5 ) ckEvery: 1 second);
		     gain: 200;
		     yourself.
	self
		assertCompiles: m => ((CkSinOsc new label: 'c')
					 freq: 220;
					 sync: 2;
					 gain: 0.1;
					 yourself) => CkDac new;
		assertCompiles: (CkSqrOsc new sync: (#( 0 1 ) ckEvery: 10 milliSeconds)) => CkDac new
]

{ #category : 'tests' }
CkChainRunTest >> testShredsCompile [

	| osc |
	osc := CkSinOsc new.
	self
		assertCompiles: osc => CkDac new , (CkShred loop: [ :t |
							 osc freq: 440.
							 t wait: 200 milliSeconds.
							 osc freq: 660.
							 t wait: 200 milliSeconds ]);
		assertCompiles: osc => CkDac new , (CkShred once: [ :t |
							 t wait: 1 second.
							 osc gain: 0 ])
]

{ #category : 'running' }
CkChainRunTest >> testSliderGlobalIsRegistered [
	"so setValue:parameter: sends sqr1Gain as a float"
	(vm run: ((CkSqrOsc new gain: CkSlider new) => CkDac new) asPhuck) remove.
	self assert: (vm globals at: 'sqr1Gain') equals: #float
]

{ #category : 'tests' }
CkChainRunTest >> testSliderLabelIsRegistered [

	(vm run: ((CkSqrOsc new gain: (CkSlider label: 'justGain')) => CkDac new) asPhuck) remove.
	self assert: (vm globals at: 'justGain') equals: #float
]
