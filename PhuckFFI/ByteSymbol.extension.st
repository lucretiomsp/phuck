Extension { #name : 'ByteSymbol' }

{ #category : '*PhuckFFI' }
ByteSymbol >> stop [
	
	PhuckVM uniqueInstance setValue: 0 parameter: self asSymbol , 'Gate'
]
