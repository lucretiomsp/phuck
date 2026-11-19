"
I am a sample player of one folder, running as my own shred in PhuckVM uniqueInstance, straight into dac. My subclasses say which ChucK class plays: ZdSampler (one-shots) or ZdLoopPlayer (loops in sync with performanceBPM).

```language=Pharo
	kick := ZdSampler folder: 'TurboSamples/kick'.
	kick play.
	kick trig.
	kick index: 3; note: 67; gain: 0.5; trig.
	kick stop.
```

My ChucK globals are float and start with my name, the folder name by default: kickNote, kickGate, kickGain, kickIndex. So a Coypu sequencer can trigger me like any Phuck instrument, through PhuckVM>>trig:for: on kickGate.

ChucK globals are shared by the whole VM: if TurboPhuck runs too and has a folder of the same name, both play. Give me another name with name: before play.

play while I play swaps my code, and my globals restart at their defaults.
"
Class {
	#name : 'ZdPlayer',
	#superclass : 'Object',
	#instVars : [
		'name',
		'folder',
		'shred'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'instance creation' }
ZdPlayer class >> chuckClass [
	"the ChucK class an instance runs"

	^ self subclassResponsibility
]

{ #category : 'chuck code' }
ZdPlayer class >> filesCode [
	"ChucK class ZdFiles: lists, filters and sorts the audio files of a folder"
	^ '// ===================== SAMPLE FOLDERS =====================
// the audio files of a folder, hidden files skipped, sorted ignoring case
class ZdFiles
{
    fun static string slash(string folder)
    {
        if (folder.length() > 0 && folder.charAt(folder.length() - 1) != 47) return folder + "/";
        return folder;
    }

    fun static string[] audio(string folder)
    {
        string keep[0];
        FileIO dir;
        if (!dir.open(folder, FileIO.READ) || !dir.isDir())
        {
            cherr <= "[ZdFiles] cannot open folder: " <= folder <= IO.nl();
            return keep;
        }
        dir.dirList() @=> string names[];
        dir.close();
        ["wav", "aif", "aiff", "flac", "ogg", "raw", "snd"] @=> string exts[];
        for (0 => int i; i < names.size(); i++)
        {
            names[i] => string name;
            name.rfind(".") => int dot;
            if (name.length() == 0 || name.charAt(0) == 46 || dot < 0) continue;
            name.substring(dot + 1).lower() => string ext;
            for (0 => int j; j < exts.size(); j++)
                if (ext == exts[j]) { keep << name; break; }
        }
        // insertion sort
        for (1 => int i; i < keep.size(); i++)
        {
            keep[i] => string item;
            i - 1 => int j;
            while (j >= 0 && keep[j].lower() > item.lower())
            {
                keep[j] => keep[j + 1];
                j--;
            }
            item => keep[j + 1];
        }
        if (keep.size() == 0) cherr <= "[ZdFiles] no audio files in: " <= folder <= IO.nl();
        return keep;
    }

    fun static int wrap(float index, int size)
    {
        index $ int => int i;
        return ((i % size) + size) % size;
    }
}
'
]

{ #category : 'instance creation' }
ZdPlayer class >> folder: aPath [

	^ self new folder: aPath
]

{ #category : 'instance creation' }
ZdPlayer class >> folder: aPath name: aString [

	^ (self folder: aPath) name: aString
]

{ #category : 'chuck code' }
ZdPlayer >> code [
	"my whole shred: the ChucK classes, my globals, the player into dac and a 1 ms control loop"

	^ String streamContents: [ :stream |
			  stream
				  << self class filesCode;
				  cr;
				  cr;
				  << self class chuckClass;
				  cr;
				  cr.
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
				  cr;
				  << self class name;
				  << ' player("';
				  << folder asChuckPath;
				  << '") => dac;';
				  cr.
			  stream << 'while (1::ms => now) player.tick('.
			  self tickArguments do: [ :each | stream << each ] separatedBy: [ stream << ', ' ].
			  stream
				  << ');';
				  cr ]
]

{ #category : 'accessing' }
ZdPlayer >> folder [

	^ folder
]

{ #category : 'accessing' }
ZdPlayer >> folder: aPath [
	"a FileReference, or a String: relative ones start from the image directory, like 'TurboSamples/kick'"

	folder := aPath isString
		          ifTrue: [ FileLocator imageDirectory asFileReference resolveString: aPath ]
		          ifFalse: [ aPath asFileReference ]
]

{ #category : 'parameters' }
ZdPlayer >> gain: aNumber [

	self set: 'Gain' to: aNumber
]

{ #category : 'parameters' }
ZdPlayer >> gate: aNumber [
	"1 starts the file, 0 releases it"

	self set: 'Gate' to: aNumber
]

{ #category : 'chuck code' }
ZdPlayer >> globals [
	"suffix -> default of my own ChucK globals, in the order tick takes them"

	^ {
		  ('Note' -> 60).
		  ('Gate' -> 0).
		  ('Gain' -> 0.4).
		  ('Index' -> 0) }
]

{ #category : 'parameters' }
ZdPlayer >> index: anInteger [
	"which file of the folder, wraps, 0 is the first in alphabetical order"

	self set: 'Index' to: anInteger
]

{ #category : 'running' }
ZdPlayer >> isPlaying [

	^ shred isNotNil and: [ shred isRemoved not ]
]

{ #category : 'accessing' }
ZdPlayer >> name [
	"the prefix of my ChucK globals, the folder name by default (hi-hat gives hihat)"

	^ name ifNil: [ TurboSampleCodegen new nameFor: folder ]
]

{ #category : 'accessing' }
ZdPlayer >> name: aString [

	name := aString
]

{ #category : 'parameters' }
ZdPlayer >> note: aMidiNote [
	"60 plays the file at its own pitch"

	self set: 'Note' to: aMidiNote
]

{ #category : 'parameters' }
ZdPlayer >> parameter: aSuffix [
	"the ChucK global for aSuffix, kickGate for Gate"

	^ self name , aSuffix
]

{ #category : 'running' }
ZdPlayer >> play [
	"spork my shred, or swap its code when I already play; boots the VM when needed"

	self vm isRunning ifFalse: [ self vm start ].
	self isPlaying
		ifTrue: [ shred replace: self code ]
		ifFalse: [ shred := self vm run: self code ]
]

{ #category : 'printing' }
ZdPlayer >> printOn: aStream [

	aStream << self class name << '(' << self name << (self isPlaying
		 ifTrue: [ ', playing' ]
		 ifFalse: [ '' ]) << ')'
]

{ #category : 'parameters' }
ZdPlayer >> set: aSuffix to: aNumber [

	self vm setValue: aNumber parameter: (self parameter: aSuffix)
]

{ #category : 'chuck code' }
ZdPlayer >> sharedGlobals [
	"globals other shreds own too: declared without a value, so I do not reset them"

	^ #(  )
]

{ #category : 'accessing' }
ZdPlayer >> shred [

	^ shred
]

{ #category : 'running' }
ZdPlayer >> stop [

	self isPlaying ifTrue: [ shred remove ]
]

{ #category : 'chuck code' }
ZdPlayer >> tickArguments [

	^ self globals collect: [ :each | self parameter: each key ]
]

{ #category : 'parameters' }
ZdPlayer >> trig [

	self trig: 0.1
]

{ #category : 'parameters' }
ZdPlayer >> trig: seconds [

	self vm trig: (self parameter: 'Gate') for: seconds
]

{ #category : 'accessing' }
ZdPlayer >> vm [

	^ PhuckVM uniqueInstance
]
