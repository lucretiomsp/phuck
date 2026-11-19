"
I am one instrument of the rig in its own shred, playing into the master bus. My globals are float and start with my name (hooverNote, hooverGate, hooverGain ...), the names of the old TurboPhuck code, so Coypu and PhuckVM>>trig:for: drive me unchanged. Each gate change sends /<name>Event on note over OSC to localhost:57120, like before.

```language=Pharo
	hoover := TurboHoover new.
	hoover play.
	hoover note: 62; trig.
	hoover code.	""the ChucK program I run""
	hoover stop.
```
A subclass gives globals (suffix -> default, in the order the ChucK tick takes them), chuckType and defaultName; setupCode, declaration, tickArguments and eventNote when it needs more. play first makes sure TurboLibrary and TurboMaster run.
"
Class {
	#name : 'TurboVoice',
	#superclass : 'TurboModule',
	#instVars : [
		'name'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
TurboVoice class >> chuckClass [
	"TurboOsc: the OSC events every voice sends, one shared socket"

	^ '// one message per gate change: /<name>Event on note (on 1 or 0, MIDI note), to localhost:57120
class TurboOsc
{
    static OscOut @ out;
    string address;
    0 => int last;

    fun TurboOsc(string name) { "/" + name + "Event" => address; }

    fun void tick(float gate, float note)
    {
        (gate > 0) => int on;
        if (on == last) return;
        on => last;
        if (out == null)
        {
            new OscOut @=> out;
            out.dest("localhost", 57120);
        }
        out.start(address).add(on $ float).add(note).send();
    }
}'
]

{ #category : 'instance creation' }
TurboVoice class >> named: aString [

	^ self new name: aString
]

{ #category : 'chuck code' }
TurboVoice >> chuckType [
	"the ChucK class I play, from TurboLibrary"

	^ self subclassResponsibility
]

{ #category : 'chuck code' }
TurboVoice >> code [
	"my shred: my globals, my player into the master bus, a 1 ms loop calling tick and sending the OSC event"

	^ String streamContents: [ :stream |
			  self globals do: [ :each |
					  stream
						  print: each value;
						  << ' => global float ';
						  << (self parameter: each key);
						  << ';';
						  cr ].
			  self sharedGlobals do: [ :each |
					  stream
						  << 'global float ';
						  << each;
						  << ';';
						  cr ].
			  stream
				  << 'global Gain master;';
				  cr.
			  self setupCode ifNotEmpty: [ :setup |
					  stream
						  << setup;
						  cr ].
			  stream
				  << self declaration;
				  << ' => master;';
				  cr.
			  stream
				  << 'TurboOsc event("';
				  << self name;
				  << '");';
				  cr;
				  cr.
			  stream
				  << 'while (1::ms => now)';
				  cr;
				  << '{';
				  cr.
			  stream << '    v.tick('.
			  self tickArguments do: [ :each | stream << each ] separatedBy: [ stream << ', ' ].
			  stream
				  << ');';
				  cr.
			  stream
				  << '    event.tick(';
				  << (self parameter: 'Gate');
				  << ', ';
				  << self eventNote;
				  << ');';
				  cr.
			  stream
				  << '}';
				  cr ]
]

{ #category : 'chuck code' }
TurboVoice >> declaration [
	"the ChucK declaration of my player, called v"

	^ self chuckType , ' v'
]

{ #category : 'accessing' }
TurboVoice >> defaultName [

	^ self subclassResponsibility
]

{ #category : 'chuck code' }
TurboVoice >> eventNote [
	"the note my OSC event reports"

	^ self parameter: 'Note'
]

{ #category : 'parameters' }
TurboVoice >> gain: aNumber [

	self set: 'Gain' to: aNumber
]

{ #category : 'parameters' }
TurboVoice >> gate: aNumber [

	self set: 'Gate' to: aNumber
]

{ #category : 'chuck code' }
TurboVoice >> globals [
	"suffix -> default of my ChucK globals, in the order tick takes them"

	^ {
		  ('Note' -> 60).
		  ('Gate' -> 0).
		  ('Gain' -> 0.5) }
]

{ #category : 'accessing' }
TurboVoice >> label [

	^ self class name , '(' , self name , ')'
]

{ #category : 'accessing' }
TurboVoice >> name [
	"the prefix of my ChucK globals: hooverNote, hooverGate, ..."

	^ name ifNil: [ self defaultName ]
]

{ #category : 'accessing' }
TurboVoice >> name: aString [

	name := aString
]

{ #category : 'parameters' }
TurboVoice >> note: aMidiNote [

	self set: 'Note' to: aMidiNote
]

{ #category : 'parameters' }
TurboVoice >> parameter: aSuffix [
	"the ChucK global for aSuffix, hooverGate for Gate"

	^ self name , aSuffix
]

{ #category : 'running' }
TurboVoice >> prepare [
	"the classes and the master bus I play into"

	TurboLibrary default play.
	TurboMaster default isPlaying ifFalse: [ TurboMaster default play ]
]

{ #category : 'parameters' }
TurboVoice >> set: aSuffix to: aNumber [

	self vm setValue: aNumber parameter: (self parameter: aSuffix)
]

{ #category : 'chuck code' }
TurboVoice >> setupCode [
	"ChucK lines run before my player is declared"

	^ ''
]

{ #category : 'chuck code' }
TurboVoice >> sharedGlobals [
	"globals other shreds own too: declared without a value, so I do not reset them"

	^ #(  )
]

{ #category : 'chuck code' }
TurboVoice >> tickArguments [

	^ self globals collect: [ :each | self parameter: each key ]
]

{ #category : 'parameters' }
TurboVoice >> trig [

	self trig: 0.1
]

{ #category : 'parameters' }
TurboVoice >> trig: seconds [

	self vm trig: (self parameter: 'Gate') for: seconds
]
