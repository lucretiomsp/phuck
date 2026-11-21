Extension { #name : 'ByteSymbol' }

{ #category : '*PhuckFFI' }
ByteSymbol >> send: aNumber to: aStringWIthFxName [
	(TurboPhuckRig default at: self asString ) send: aNumber to: aStringWIthFxName .
]

{ #category : '*PhuckFFI' }
ByteSymbol >> stop [
	
	PhuckVM uniqueInstance setValue: 0 parameter: self asSymbol , 'Gate'
]
