"
An interpolating sound buffer/player with single-channel output; can read audio data from a variety of uncompressed formats.
"
Class {
	#name : 'CkSndBuf',
	#superclass : 'CkUGen',
	#instVars : [
		'channel'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}

{ #category : 'accessing' }
CkSndBuf >> channel [ 
^ channel 
]

{ #category : 'accessing' }
CkSndBuf >> channel: aChannel [

"For sound file containing more than one channel of audio, select the channel to play."
channel := aChannel
]

{ #category : 'trait' }
CkSndBuf >> freq: aFloat [ 

"Set loop rate (in file loops per second).
"
]
