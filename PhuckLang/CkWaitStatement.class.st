"
I am the statement letting time pass in a shred: 200::ms => now;.
"
Class {
	#name : 'CkWaitStatement',
	#superclass : 'CkStatement',
	#instVars : [
		'duration'
	],
	#category : 'PhuckLang-Statements',
	#package : 'PhuckLang',
	#tag : 'Statements'
}

{ #category : 'instance creation' }
CkWaitStatement class >> duration: aDuration [
	"The recorded wait of aDuration"

	^ self new setDuration: aDuration
]

{ #category : 'printing' }
CkWaitStatement >> ckCodeIn: aWriter [
	"200 milliSeconds -> 200::ms => now;"

	^ duration ckCode , ' => now;'
]

{ #category : 'testing' }
CkWaitStatement >> isWait [
	"The only statement that lets time pass"

	^ true
]

{ #category : 'initialization' }
CkWaitStatement >> setDuration: aDuration [
	"A Pharo Duration, printed in ChucK ms"

	duration := aDuration
]
