"
I am the opaque handle to a phuck_t (one ChucK VM in libphuck). 
```language=Pharo
LibPhuck>>phuck_new 
```
answers me.
I am not meant to be used directly: PhuckVM holds me in its chuck slot and passes me to LibPhuck.
"
Class {
	#name : 'PhuckPointer',
	#superclass : 'PhuckBaseObject',
	#category : 'PhuckFFI-Core',
	#package : 'PhuckFFI',
	#tag : 'Core'
}
