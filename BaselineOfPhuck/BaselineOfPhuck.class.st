Class {
	#name : 'BaselineOfPhuck',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfPhuck',
	#package : 'BaselineOfPhuck'
}

{ #category : 'baselines' }
BaselineOfPhuck >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec postLoadDoIt: #copyLibraries.
		spec package: 'PhuckFFI'.
		spec package: 'Phuck' with: [ spec requires: #( 'PhuckFFI' ) ].
		spec package: 'Phuck-Tests' with: [ spec requires: #( 'Phuck' ) ].
		spec group: 'default' with: #( 'Phuck' 'Phuck-Tests' ).
		spec group: 'ci' with: #( 'Phuck' 'Phuck-Tests' ) ]
]

{ #category : 'copying' }
BaselineOfPhuck >> copyLibraries [
	"Copy phuckLibraries from the local Iceberg clone, or download them from GitHub as a fallback."
	IceRepository registry
		detect: [ :each | each includesPackageNamed: self class packageName ]
		ifFound: [ :repository |
			self copyLibrariesFrom: repository location / 'phuckLibraries' ]
		ifNone: [ self downloadLibraries ]
]

{ #category : 'copying' }
BaselineOfPhuck >> copyLibrariesFrom: sourceDirectory [
	"phuckLibraries sits at the repository root, not in src."
	| destination |
	sourceDirectory exists ifFalse: [ ^ self downloadLibraries ].
	destination := self librariesDirectory ensureCreateDirectory.
	('Copying ' , sourceDirectory pathString , ' to ' , destination pathString) traceCr.
	sourceDirectory files do: [ :file |
		| target |
		target := destination / file basename.
		target exists ifTrue: [ target delete ].
		file copyTo: target ]
]

{ #category : 'copying' }
BaselineOfPhuck >> downloadLibraries [
	"Fallback when no local clone is found."
	| destination |
	destination := self librariesDirectory ensureCreateDirectory.
	[ self libraryFileNames do: [ :fileName |
		| target |
		target := destination / fileName.
		target exists ifTrue: [ target delete ].
		('Downloading ' , fileName) traceCr.
		ZnClient new
			url: self rawLibrariesUrl , fileName;
			downloadTo: target ] ]
		on: Error
		do: [ :e | self warnCopyFailed ]
]

{ #category : 'copying' }
BaselineOfPhuck >> librariesDirectory [
	^ FileLocator imageDirectory asFileReference / 'phuckLibraries'
]

{ #category : 'copying' }
BaselineOfPhuck >> libraryFileNames [
	^ #( 'phuck.h' 'libphuck.dylib' 'libphuck.so' 'phuck.dll' )
]

{ #category : 'defaults' }
BaselineOfPhuck >> rawLibrariesUrl [
	^ 'https://raw.githubusercontent.com/lucretiomsp/phuck/main/phuckLibraries/'
]

{ #category : 'warning' }
BaselineOfPhuck >> warnCopyFailed [
	<debuggerCompleteToSender>
	Warning signal:
		'Failed to install the Phuck libraries: copy the content of https://github.com/lucretiomsp/phuck/tree/main/phuckLibraries into '
		, self librariesDirectory pathString
]
