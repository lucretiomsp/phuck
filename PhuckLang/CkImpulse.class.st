"
An impulse generator: outputs the value set with next: for one sample, then 0.

```language=Pharo
	(CkImpulse new next: 1.0) => CkBiQuad new => CkDac new
```
"
Class {
	#name : 'CkImpulse',
	#superclass : 'CkUGen',
	#category : 'PhuckLang-UGen',
	#package : 'PhuckLang',
	#tag : 'UGen'
}

{ #category : 'API' }
CkImpulse >> next [
	"the value of the next sample, as an expression usable in params of other UGens"

	^ CkGetter ugen: self selector: #next
]

{ #category : 'API' }
CkImpulse >> next: aValue [
	"Set the value of the next sample: 1.0 => i.next fires one click.
	(Read with last, the value shows one sample later.)"

	self param: #next put: aValue
]
