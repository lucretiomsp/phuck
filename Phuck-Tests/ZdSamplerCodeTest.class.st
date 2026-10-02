Class {
	#name : 'ZdSamplerCodeTest',
	#superclass : 'TestCase',
	#category : 'Phuck-Tests-Examples',
	#package : 'Phuck-Tests',
	#tag : 'Examples'
}

{ #category : 'accessing' }
ZdSamplerCodeTest >> stkInstCode [
	^ MiniPhuck zdSamplerCode
]

{ #category : 'tests' }
ZdSamplerCodeTest >> testCreatesInstancesOnSubfolders [
	self assert: (self stkInstCode includesSubstring: 'ZdSampler rim(turbo + "/rim")').
	self assert: (self stkInstCode includesSubstring: 'ZdSampler kick(turbo + "/kick")')
]

{ #category : 'tests' }
ZdSamplerCodeTest >> testDeclaresGlobalsForEachInstance [
	#( 'rim' 'kick' ) do: [ :name |
		#( 'Note' 'Gate' 'Index' ) do: [ :suffix |
			self assert: (self stkInstCode includesSubstring: 'global int ' , name , suffix , ';') ] ]
]

{ #category : 'tests' }
ZdSamplerCodeTest >> testDefinesSamplerClass [
	self assert: (self stkInstCode includesSubstring: 'class ZdSampler extends Chugraph')
]

{ #category : 'tests' }
ZdSamplerCodeTest >> testHasNoBackslashes [
	self deny: (self stkInstCode includes: $\)
]

{ #category : 'tests' }
ZdSamplerCodeTest >> testPlaceholderIsReplaced [
	self deny: (self stkInstCode includesSubstring: 'TURBO_ROOT')
]

{ #category : 'tests' }
ZdSamplerCodeTest >> testPollsEveryInstance [
	self assert: (self stkInstCode includesSubstring: 'while (samp => now)').
	self assert: (self stkInstCode includesSubstring: 'rim.update(rimNote, rimGate, rimIndex);').
	self assert: (self stkInstCode includesSubstring: 'kick.update(kickNote, kickGate, kickIndex);')
]

{ #category : 'as yet unclassified' }
ZdSamplerCodeTest >> turboRoot [

	^ (FileLocator documents / 'TurboSamples') asFileReference asChuckPath
]
