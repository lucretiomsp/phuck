"
A step generator. Step behaves like Impulse, except that once a next value is set, that value is held for all following samples, until a different value is set.
"
Class {
	#name : 'CkStep',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'accessing' }
CkStep >> next [ 

" ? Get value of next sample to be generated."
self shouldBeImplemented 
]

{ #category : 'accessing' }
CkStep >> next: aFloat [ 

"Set the value of next sample. (Note: if you are using the UGen.last() method to read the output of the impulse, the value set by Impulse.next() does not appear as the output until after the next sample boundary. In this case, there is a consistent 1::samp offset between setting .next(...) and reading that value using .last().)"
self shouldBeImplemented 
]
