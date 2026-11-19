"
I play the loops of a folder in sync with performanceBPM. Each file plays at the bpm in its name: amen|170.wav, else the first number in 60..250, else at its native speed. Note 60 is in sync.

```language=Pharo
	breaks := ZdLoopPlayer folder: 'TurboSamples/breaks'.
	breaks play; gate: 1.
	breaks slice: 4.
	breaks reverse: true.
	breaks wholeLoop; reverse: false.
	breaks gate: 0; stop.
```
See ZdPlayer.
"
Class {
	#name : 'ZdLoopPlayer',
	#superclass : 'ZdPlayer',
	#category : 'PhuckFFI-TurboPhuck',
	#package : 'PhuckFFI',
	#tag : 'TurboPhuck'
}

{ #category : 'chuck code' }
ZdLoopPlayer class >> chuckClass [
	"the ChucK class I run, it uses ZdFiles"
	^ '// ===================== LOOP PLAYER =====================
// one folder of loops played in sync with bpm, each file at the bpm of its name
// (amen|170.wav, else the first number in 60..250). Note 60 = in sync.
// reverse: plays backwards, turning around at the playhead
// position: offset from the start point along the playback direction, 0..1 of the file
// slice: start step in 16ths of the loop, fractions allowed, wraps; negative = whole loop
// length: loop length in bars for the 16th grid, 0 = from the file bpm
class ZdLoopPlayer extends Chugraph
{
    SndBuf buf => ADSR env => Gain out => outlet;
    env.set(1::ms, 380::ms, 1.0, 120::ms);
    0.4 => buf.gain;

    string dir;
    string files[0];
    float bpms[0];
    -1 => int lastIndex;
    0 => int lastGate;
    0 => int lastReverse;
    0.0 => float lastPosition;
    -1.0 => float lastSlice;
    0.0 => float lastLength;
    174.0 => float tempo;

    fun ZdLoopPlayer(string folder)
    {
        ZdFiles.slash(folder) => dir;
        ZdFiles.audio(folder) @=> files;
        bpms.size(files.size());
        for (0 => int i; i < files.size(); i++)
        {
            bpmOf(files[i]) => bpms[i];
            if (bpms[i] <= 0)
                cherr <= "[ZdLoopPlayer] no bpm in " <= files[i] <= ", plays at native speed" <= IO.nl();
        }
    }

    fun void tick(float note, float gate, float gain, float index, float bpm,
                  float reverse, float position, float slice, float length)
    {
        gain => buf.gain;
        if (files.size() == 0) return;

        // a bogus bpm (an int read as float gives 0) keeps the last one
        if (bpm > 0) bpm => tempo;
        (reverse != 0) => int back;
        Math.max(0.0, length) => length;
        ZdFiles.wrap(index, files.size()) => int i;

        (i != lastIndex) => int newFile;
        (back != lastReverse) => int turned;
        (position != lastPosition || slice != lastSlice || length != lastLength) => int moved;
        i => lastIndex;  back => lastReverse;
        position => lastPosition;  slice => lastSlice;  length => lastLength;

        if (newFile) dir + files[i] => buf.read;

        // bpm sync times transposition, negative when reversed
        1.0 => float ratio;
        if (bpms[i] > 0) tempo / bpms[i] => ratio;
        ratio * Math.pow(2.0, (note - 60) / 12.0) => ratio;
        (back ? -ratio : ratio) => buf.rate;

        // while playing, a new file or start point moves the playhead; stopped, it parks
        if (lastGate && (newFile || moved)) startFrame() => buf.pos;
        if (!lastGate && (newFile || turned)) park();

        (gate > 0) => int on;
        if (on == lastGate) return;
        if (on) { startFrame() => buf.pos; env.keyOn(); }
        else    env.keyOff();
        on => lastGate;
    }

    // file frames in one 16th: from the length if set, else from the file bpm, else 1 bar
    fun float stepFrames()
    {
        buf.samples() => int n;
        if (lastLength > 0) return n / (16.0 * lastLength);
        if (bpms[lastIndex] > 0)
            return (15.0 / bpms[lastIndex]) * (n / (buf.length() / second));
        return n / 16.0;
    }

    // start of the 16th (its end when reversed, whole file when slicing is off),
    // moved by the position along the playback direction
    fun int startFrame()
    {
        buf.samples() => int n;
        0.0 => float from;
        n $ float => float to;
        if (lastSlice >= 0)
        {
            stepFrames() => float step;
            Math.max(1.0, Math.round(n / step)) => float steps;
            lastSlice - steps * Math.floor(lastSlice / steps) => float k;
            k * step => from;
            (k + 1) * step => to;
        }
        (lastReverse ? to - lastPosition * n : from + lastPosition * n) => float p;
        return Math.max(0.0, Math.min(n - 1.0, p)) $ int;
    }

    // playhead where nothing plays in the current direction
    fun void park()
    {
        (lastReverse ? 0 : buf.samples()) => buf.pos;
    }

    // pipe tag first (myBassLoop|128.wav), else first number in 60..250, else 0
    fun static float bpmOf(string fileName)
    {
        fileName => string base;
        fileName.rfind(".") => int dot;
        if (dot > 0) fileName.substring(0, dot) => base;
        base.rfind("|") => int pipe;
        if (pipe >= 0 && pipe < base.length() - 1)
        {
            base.substring(pipe + 1).toFloat() => float b;
            if (b > 0) return b;
        }
        0 => int num;
        0 => int inRun;
        for (0 => int i; i <= base.length(); i++)
        {
            -1 => int c;
            if (i < base.length()) base.charAt(i) => c;
            if (c >= 48 && c <= 57) { num * 10 + (c - 48) => num; 1 => inRun; }
            else
            {
                if (inRun && num >= 60 && num <= 250) return num $ float;
                0 => num;
                0 => inRun;
            }
        }
        return 0.0;
    }
}
'
]

{ #category : 'parameters' }
ZdLoopPlayer >> bpm: aNumber [
	"sets performanceBPM, shared with every loop and TurboPhuck"

	self vm setValue: aNumber parameter: 'performanceBPM'
]

{ #category : 'chuck code' }
ZdLoopPlayer >> globals [

	^ super globals , {
		  ('Reverse' -> 0).
		  ('Position' -> 0).
		  ('Slice' -> -1).
		  ('Length' -> 0) }
]

{ #category : 'parameters' }
ZdLoopPlayer >> length: bars [
	"loop length in bars for the 16th grid, 0 works it out from the file bpm"

	self set: 'Length' to: bars
]

{ #category : 'parameters' }
ZdLoopPlayer >> position: aFraction [
	"offset from the start point along the playback direction, 0..1 of the file"

	self set: 'Position' to: aFraction
]

{ #category : 'parameters' }
ZdLoopPlayer >> reverse: aBooleanOrNumber [
	"true or 1 plays backwards; while playing, turns around at the playhead"

	self set: 'Reverse' to: (aBooleanOrNumber isNumber
			 ifTrue: [ aBooleanOrNumber ]
			 ifFalse: [
					 aBooleanOrNumber
						 ifTrue: [ 1 ]
						 ifFalse: [ 0 ] ])
]

{ #category : 'chuck code' }
ZdLoopPlayer >> sharedGlobals [
	"the tempo every loop follows, set by Performance>>bpm: and TurboPhuck>>bpm:"

	^ #( 'performanceBPM' )
]

{ #category : 'parameters' }
ZdLoopPlayer >> slice: aNumber [
	"start in 16ths of the loop, fractions allowed, wraps"

	self set: 'Slice' to: aNumber
]

{ #category : 'chuck code' }
ZdLoopPlayer >> tickArguments [
	"tick takes the bpm right after the index"

	| names |
	names := super tickArguments.
	^ (names first: 4) , #( 'performanceBPM' ) , (names allButFirst: 4)
]

{ #category : 'parameters' }
ZdLoopPlayer >> wholeLoop [
	"no slicing: start at the beginning of the file (its end when reversed)"

	self slice: -1
]
