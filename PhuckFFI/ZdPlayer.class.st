"
I am a sample player of one folder, a TurboVoice playing into the master bus. My subclasses say which ChucK class plays: ZdSampler (one-shots) or ZdLoopPlayer (loops in sync with performanceBPM).

```language=Pharo
	kick := ZdSampler folder: 'TurboSamples/kick'.
	kick spork.
	kick trig.
	kick index: 3; note: 67; gain: 0.5; trig.
	kick unspork.
```

My ChucK globals are float and start with my name, the folder name by default: kickNote, kickGate, kickGain, kickIndex. ChucK globals are shared by the whole VM: if the old TurboPhuck program runs too, its kick plays along. Give me another name with name: before spork.
"
Class {
	#name : 'ZdPlayer',
	#superclass : 'TurboVoice',
	#instVars : [
		'folder'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
ZdPlayer class >> chuckClass [
	"my ChucK classes, the old ChucK code; TurboLibrary compiles them once as public classes"
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
ZdPlayer >> chuckType [
	"ZdSampler or ZdLoopPlayer: the ChucK class has my class name"

	^ self class name
]

{ #category : 'chuck code' }
ZdPlayer >> declaration [

	^ self chuckType , ' v("' , folder asChuckPath , '")'
]

{ #category : 'accessing' }
ZdPlayer >> defaultName [
	"the folder name as a ChucK identifier: hi-hat gives hihat"

	^ TurboSampleCodegen new nameFor: folder
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
