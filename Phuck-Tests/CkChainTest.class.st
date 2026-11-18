Class {
	#name : 'CkChainTest',
	#superclass : 'TestCase',
	#category : 'Phuck-Tests-Lang',
	#package : 'Phuck-Tests',
	#tag : 'Lang'
}

{ #category : 'asserting' }
CkChainTest >> assert: aChain generates: lines [
	self assert: aChain asPhuck equals: (String lf join: lines)
]

{ #category : 'tests - classes' }
CkChainTest >> testChugen [

	self
		assert: CkSinOsc new => (CkChugen tick: [ :in | in * 0.5 ]) => CkDac new
		generates:
			#( 'class Chugen1 extends Chugen {' '  fun float tick(float in) {' '    return in * 0.5;' '  }' '}' 'SinOsc sin1 => Chugen1 chugen1 => dac;'
			   'while (1) {' '  1::ms => now;' '}' )
]

{ #category : 'tests - classes' }
CkChainTest >> testChugenCannotReadOuterUGen [

	| lfo |
	lfo := CkSinOsc new.
	self should: [ ((CkChugen tick: [ :in | in * lfo last ]) => CkDac new) asPhuck ] raise: Error
]

{ #category : 'tests - classes' }
CkChainTest >> testChugenReturnsFloat [

	self assert: (((CkChugen tick: [ :in | 1 ]) => CkDac new) asPhuck includesSubstring: 'return 1.0;')
]

{ #category : 'tests - classes' }
CkChainTest >> testChugraph [

	self
		assert: CkSinOsc new => CkTestVoice new => CkDac new
		generates:
			#( 'class TestVoice extends Chugraph {' '  inlet => LPF lpf1 => outlet;' '  800 => lpf1.freq;' '}' 'SinOsc sin1 => TestVoice testvoice1 => dac;'
			   'while (1) {' '  1::ms => now;' '}' )
]

{ #category : 'tests - classes' }
CkChainTest >> testChugraphClassDefinedOnce [

	| code |
	code := (CkSinOsc new => CkTestVoice new => CkDac new , (CkSqrOsc new => CkTestVoice new => CkDac new)) asPhuck.
	self
		assert: (code allRangesOfSubstring: 'class TestVoice') size equals: 1;
		assert: (code includesSubstring: 'TestVoice testvoice2')
]

{ #category : 'tests - classes' }
CkChainTest >> testChugraphRef [

	self
		assert: CkSinOsc new => ((CkChugraphRef ugenClass: 'NRev')
				 param: #mix put: 0.1;
				 yourself) => CkDac new
		generates: #( 'SinOsc sin1 => NRev nrev1 => dac;' '0.1 => nrev1.mix;' 'while (1) {' '  1::ms => now;' '}' )
]

{ #category : 'tests - labels' }
CkChainTest >> testDuplicateLabelFails [

	self should: [ ((CkSinOsc new label: 'x') => (CkSqrOsc new label: 'x') => CkDac new) asPhuck ] raise: Error
]

{ #category : 'tests - timing' }
CkChainTest >> testDurationCode [

	self
		assert: 100 milliSeconds ckCode equals: '100::ms';
		assert: 2 seconds ckCode equals: '2000::ms';
		assert: (Duration nanoSeconds: 500000) ckCode equals: '0.5::ms'
]

{ #category : 'as yet unclassified' }
CkChainTest >> testEvery [
	self
		assert: (CkSinOsc new => CkDac new every: 100 milliSeconds; yourself)
		generates: #('SinOsc sin1 => dac;' 'while (1) {' '  100::ms => now;' '}')
]

{ #category : 'tests - labels' }
CkChainTest >> testInvalidLabelFails [

	#( '' '1osc' 'my osc' 'dac' 'while' ) do: [ :each | self should: [ CkSinOsc new label: each ] raise: Error ]
]

{ #category : 'tests - labels' }
CkChainTest >> testLabelDrivesSliderName [
	"An unlabelled slider takes the UGen's label as prefix"

	| osc |
	osc := CkSqrOsc new label: 'myOsc'.
	osc gain: CkSlider new.
	self
		assert: osc => CkDac new
		generates:
		#( 'global float myOscGain;' 'SqrOsc myOsc => dac;' 'while (1) {' '  myOscGain => myOsc.gain;' '  1::ms => now;'
		   '}' )
]

{ #category : 'tests - labels' }
CkChainTest >> testLabelNamesUGen [

	self
		assert: (CkSqrOsc new label: 'myOsc') => CkDac new
		generates: #( 'SqrOsc myOsc => dac;' 'while (1) {' '  1::ms => now;' '}' )
]

{ #category : 'tests - labels' }
CkChainTest >> testLabelSkippedByAutoName [
	"A label that looks like an automatic name pushes the counter on"

	self
		assert: (CkSqrOsc new label: 'sqr1') => CkSqrOsc new => CkDac new
		generates: #( 'SqrOsc sqr1 => SqrOsc sqr2 => dac;' 'while (1) {' '  1::ms => now;' '}' )
]

{ #category : 'tests - shreds' }
CkChainTest >> testLoopingShred [

	| osc |
	osc := CkSinOsc new.
	self
		assert: osc => CkDac new , (CkShred loop: [ :t |
					 osc freq: 440.
					 t wait: 200 milliSeconds.
					 osc freq: 660.
					 t wait: 200 milliSeconds ])
		generates:
			#( 'SinOsc sin1 => dac;' 'fun void shred1() {' '  while (1) {' '    440 => sin1.freq;' '    200::ms => now;'
			   '    660 => sin1.freq;' '    200::ms => now;' '  }' '}' 'spork ~ shred1();' 'while (1) {' '  1::ms => now;'
			   '}' ).
	self assert: osc params isEmpty
]

{ #category : 'tests - shreds' }
CkChainTest >> testLoopingShredMustWait [

	| osc |
	osc := CkSinOsc new.
	self should: [ (osc => CkDac new , (CkShred loop: [ :t | osc freq: 440 ])) asPhuck ] raise: Error
]

{ #category : 'tests' }
CkChainTest >> testOperatorsKeepPharoOrder [
	"Pharo reads 1 + x * 2 as (1 + x) * 2"
	self
		assert: ((1 + CkSinOsc new last * 2) ckCodeIn: CkGraphWriter new)
		equals: '(1 + sin1.last()) * 2'

]

{ #category : 'tests - timing' }
CkChainTest >> testProgramEveryWins [

	self
		assert: (((CkSinOsc new => CkDac new every: 10 milliSeconds) , (CkSqrOsc new => CkDac new))
				 every: 20 milliSeconds;
				 yourself)
		generates: #( 'SinOsc sin1 => dac;' 'SqrOsc sqr1 => dac;' 'while (1) {' '  20::ms => now;' '}' )
]

{ #category : 'tests' }
CkChainTest >> testProgramSharesUGens [
	| lfo |
	lfo := CkSinOsc new freq: 0.5; gain: 200.
	self
		assert: (lfo => (CkSinOsc new freq: 440; sync: 2) => CkDac new)
			, (lfo => (CkSinOsc new freq: 660; sync: 2) => CkDac new)
		generates: #(
			'SinOsc sin1 => SinOsc sin2 => dac;'
			'sin1 => SinOsc sin3 => dac;'
			'0.5 => sin1.freq;'
			'200 => sin1.gain;'
			'440 => sin2.freq;'
			'2 => sin2.sync;'
			'660 => sin3.freq;'
			'2 => sin3.sync;'
			'while (1) {'
			'  1::ms => now;'
			'}' )
]

{ #category : 'tests - timing' }
CkChainTest >> testProgramUsesFastestPart [

	self
		assert: (CkSinOsc new => CkDac new every: 10 milliSeconds) , (CkSqrOsc new => CkDac new every: 5 milliSeconds)
		generates: #( 'SinOsc sin1 => dac;' 'SqrOsc sqr1 => dac;' 'while (1) {' '  5::ms => now;' '}' )
]

{ #category : 'tests' }
CkChainTest >> testReadUGenInLoop [
	| lfo osc |
	lfo := CkSinOsc new freq: 0.5.
	osc := CkSinOsc new freq: 440 + (lfo last * 200).
	self
		assert: osc => CkDac new
		generates: #(
			'SinOsc sin1 => dac;'
			'SinOsc sin2 => blackhole;'
			'0.5 => sin2.freq;'
			'while (1) {'
			'  440 + (sin2.last() * 200) => sin1.freq;'
			'  1::ms => now;'
			'}' )
]

{ #category : 'tests - shreds' }
CkChainTest >> testRecorderTouched [

	| osc recorder |
	osc := CkSinOsc new.
	recorder := (CkShred loop: [ :t |
			             osc freq: 440.
			             t wait: 1 second ]) record.
	self
		assert: recorder touched asArray equals: { osc };
		assert: recorder statements size equals: 2
]

{ #category : 'tests - sliders' }
CkChainTest >> testSharedSliderDeclaredOnce [

	| volume |
	volume := CkSlider label: 'volume'.
	self
		assert: (CkSqrOsc new gain: volume) => CkDac new , ((CkSinOsc new gain: volume) => CkDac new)
		generates: #( 'global float volume;' 'SqrOsc sqr1 => dac;' 'SinOsc sin1 => dac;' 'while (1) {' '  volume => sqr1.gain;'
			   '  volume => sin1.gain;' '  1::ms => now;' '}' )
]

{ #category : 'tests - shreds' }
CkChainTest >> testShredOnce [

	| osc |
	osc := CkSinOsc new freq: 220.
	self
		assert: osc => CkDac new , (CkShred once: [ :t |
					 t wait: 1 second.
					 osc gain: 0 ])
		generates:
			#( 'SinOsc sin1 => dac;' '220 => sin1.freq;' 'fun void shred1() {' '  1000::ms => now;' '  0 => sin1.gain;' '}' 'spork ~ shred1();'
			   'while (1) {' '  1::ms => now;' '}' )
]

{ #category : 'tests' }
CkChainTest >> testSliderBecomesGlobal [
	| osc |
	osc := CkSqrOsc new.
	osc gain: CkSlider new.
	self
		assert: (osc => CkDac new) asPhuck
		equals: (String lf join: #(
			'global float sqr1Gain;'
			'SqrOsc sqr1 => dac;'
			'while (1) {'
			'  sqr1Gain => sqr1.gain;'
			'  1::ms => now;'
			'}' ))
]

{ #category : 'tests - sliders' }
CkChainTest >> testSliderLabelBecomesGlobalName [

	| osc |
	osc := CkSqrOsc new label: 'myOsc'.
	osc gain: (CkSlider label: 'justGain').
	self
		assert: osc => CkDac new
		generates: #( 'global float justGain;' 'SqrOsc myOsc => dac;' 'while (1) {' '  justGain => myOsc.gain;'
		   '  1::ms => now;' '}' )
]

{ #category : 'tests' }
CkChainTest >> testSqrOscToDac [

	self
		assert: (CkSqrOsc new => CkDac new) asPhuck
		equals: (String lf join: #( 'SqrOsc sqr1 => dac;' 'while (1) {' '  1::ms => now;' '}' ))
]
