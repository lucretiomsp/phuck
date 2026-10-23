"
The same as the Gain UGen, but the constructor sets the gain in deciBels rather than linear scaling.
"
Class {
	#name : 'CkImpulse',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'accessing' }
CkImpulse >> next [ 

" ? Get value of next sample to be generated."
self shouldBeImplemented 
]

{ #category : 'accessing' }
CkImpulse >> next: aFloat [ 

"Set the value of next sample. (Note: if you are using the UGen.last() method to read the output of the impulse, the value set by Impulse.next() does not appear as the output until after the next sample boundary. In this case, there is a consistent 1::samp offset between setting .next(...) and reading that value using .last().)"
self shouldBeImplemented 
]
