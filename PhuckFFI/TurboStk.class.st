"
I am one STK instrument as a voice, through the ChucK class ZdStk. The twelve of the old TurboPhuck code, by their global prefix:

```language=Pharo
	(TurboStk named: 'bell') spork; trig.
	TurboStk all.
	TurboStk instruments.
```
Another StkInstrument works too: (TurboStk new instrument: 'Wurley'; name: 'wurley').
"
Class {
	#name : 'TurboStk',
	#superclass : 'TurboVoice',
	#instVars : [
		'instrument'
	],
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'instance creation' }
TurboStk class >> all [

	^ self instruments keys collect: [ :each | self named: each ]
]

{ #category : 'chuck code' }
TurboStk class >> chuckClass [
	"my ChucK class: the old stkVoice function as a voice keeping its own last note and gate"

	^ '// one STK instrument: pitch only when the note changes, gates only on change.
// 0.3 is the old stkMaster gain, shared by every STK voice
class ZdStk extends Chugraph
{
    Gain amp => Gain trim => outlet;
    0.3 => trim.gain;
    StkInstrument @ inst;
    -1.0 => float lastNote;
    0 => float lastGate;

    fun ZdStk(StkInstrument i)
    {
        i @=> inst;
        inst => amp;
    }

    fun void tick(float note, float gate, float gain)
    {
        gain => amp.gain;
        if (note != lastNote)
        {
            Std.mtof(note) => inst.freq;
            note => lastNote;
        }
        if (gate == lastGate) return;
        if (gate > 0) gate => inst.noteOn;
        else 1 => inst.noteOff;
        gate => lastGate;
    }
}'
]

{ #category : 'instance creation' }
TurboStk class >> instruments [
	"voice name -> STK class, the twelve of the old TurboPhuck code"

	^ OrderedDictionary new
		  at: 'bell' put: 'TubeBell';
		  at: 'brass' put: 'Brass';
		  at: 'blow' put: 'BlowBotl';
		  at: 'clarinet' put: 'Clarinet';
		  at: 'moog' put: 'Moog';
		  at: 'stkShaker' put: 'Shakers';
		  at: 'bar' put: 'ModalBar';
		  at: 'flut' put: 'PercFlut';
		  at: 'rhodey' put: 'Rhodey';
		  at: 'mandolin' put: 'Mandolin';
		  at: 'beeThree' put: 'BeeThree';
		  at: 'sitar' put: 'Sitar';
		  yourself
]

{ #category : 'instance creation' }
TurboStk class >> named: aVoiceName [
	"one of the instruments, by its old global prefix: bell, moog, beeThree ..."

	^ self new
		  name: aVoiceName;
		  instrument: (self instruments at: aVoiceName);
		  yourself
]

{ #category : 'chuck code' }
TurboStk >> chuckType [

	^ 'ZdStk'
]

{ #category : 'chuck code' }
TurboStk >> declaration [

	^ 'ZdStk v(inst)'
]

{ #category : 'accessing' }
TurboStk >> defaultName [

	^ instrument uncapitalized
]

{ #category : 'chuck code' }
TurboStk >> globals [
	"the Moog was louder than the others in the old code"

	^ {
		  ('Note' -> 60).
		  ('Gate' -> 0).
		  ('Gain' -> (instrument = 'Moog'
			    ifTrue: [ 0.7 ]
			    ifFalse: [ 0.5 ])) }
]

{ #category : 'accessing' }
TurboStk >> instrument [

	^ instrument
]

{ #category : 'accessing' }
TurboStk >> instrument: aChuckClassName [
	"any StkInstrument: TubeBell, Moog, Sitar ..."

	instrument := aChuckClassName
]

{ #category : 'chuck code' }
TurboStk >> setupCode [

	^ String streamContents: [ :stream |
			  stream << instrument << ' inst;'.
			  instrument = 'Moog' ifTrue: [
					  stream
						  cr;
						  << '0 => inst.filterQ;';
						  cr;
						  << '1 => inst.filterSweepRate;';
						  cr;
						  << '1 => inst.lfoSpeed;' ] ]
]
