Extension { #name : 'FileReference' }

{ #category : '*PhuckFFI' }
FileReference >> asChuckPath [
	"Path usable inside a ChucK string literal on any OS"

	^ self fullName copyReplaceAll: '\' with: '/'
]
