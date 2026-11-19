"
Base class for basic filters with a notion of center/cutoff frequency and Q.
"
Class {
	#name : 'CkFilterBasic',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-Filters',
	#package : 'PhuckLang',
	#tag : 'Filters'
}

{ #category : 'trait' }
CkFilterBasic >> freq: aValue [
	self param: #freq put: aValue
]

{ #category : 'trait' }
CkFilterBasic >> q: aValue [
	"Filter resonance. ChucK spells this param with a capital: 3 => lpf1.Q;"

	self param: #Q put: aValue
]
