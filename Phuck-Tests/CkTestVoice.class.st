"
I am a test fixture: the smallest CkChugraph with an inner param (inlet => LPF at 800 Hz => outlet).
"
Class {
	#name : 'CkTestVoice',
	#superclass : 'CkChugraph',
	#category : 'Phuck-Tests-Lang',
	#package : 'Phuck-Tests',
	#tag : 'Lang'
}

{ #category : 'building' }
CkTestVoice >> buildFrom: inlet to: outlet [
	"A low-passed voice: the simplest Chugraph with an inner param"

	^ inlet => (CkLPF new freq: 800) => outlet
]
