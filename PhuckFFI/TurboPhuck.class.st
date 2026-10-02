"
I am TurboPhuck, I am a Performance connected to a ChuckVM and a shred full of cool instruments
"
Class {
	#name : 'TurboPhuck',
	#superclass : 'Object',
	#instVars : [
		'tpPerf'
	],
	#classInstVars : [
		'vm'
	],
	#category : 'PhuckFFI-Core',
	#package : 'PhuckFFI',
	#tag : 'Core'
}

{ #category : 'defaults' }
TurboPhuck class >> code [ 

^ '
'
]

{ #category : 'accessing' }
TurboPhuck class >> start [
vm := PhuckVM uniqueInstance.
	vm run: MiniPhuck zdSamplerCode
]

{ #category : 'initialization' }
TurboPhuck >> initialize [

	super initialize.
	tpPerf := Performance uniqueInstance.
	tpPerf forPhuck: self class vm
]
