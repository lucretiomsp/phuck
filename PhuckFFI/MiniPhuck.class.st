"
Lightweight engine a la TurboPhausto to be used with Coypu for programming music on-the-fly
"
Class {
	#name : 'MiniPhuck',
	#superclass : 'Object',
	#category : 'PhuckFFI-Core',
	#package : 'PhuckFFI',
	#tag : 'Core'
}

{ #category : 'accessing' }
MiniPhuck class >> code [

	^ '// define globals
0 => global float bellGate;      0.5 => global float bellNote;
0 => global float brassGate;     0.5 => global float brassNote;
0 => global float blowGate;      0.5 => global float blowNote;
0 => global float clarinetGate;  0.5 => global float clarinetNote;
0 => global float moogGate;      0.5 => global float moogNote;
0 => global float shakeGate;     0.5 => global float shakeNote;
0 => global float barGate;       0.5 => global float barNote;

// mixer, so seven voices don''t clip
Gain master => dac;
0.3 => master.gain;

// define instruments
TubeBell bell => master;
Brass brass => master;
BlowBotl blow => master;
Clarinet clarinet => master;
Moog moog => master;
Shakers shake => master;
ModalBar bar => master;

 
fun void voice(StkInstrument inst, float note, float gate)
{
    Std.mtof(note) => inst.freq;
    gate => inst.noteOn;
}

while (samp => now)
{
    voice(bell,     bellNote,     bellGate);
    voice(brass,    brassNote,    brassGate);
    voice(blow,     blowNote,     blowGate);
    voice(clarinet, clarinetNote, clarinetGate);
    voice(moog,     moogNote,     moogGate);
    voice(shake,    shakeNote,    shakeGate);
    voice(bar,      barNote,      barGate);
}'
]

{ #category : 'as yet unclassified' }
MiniPhuck class >> justTubeBell [

^ '0 => global float bellGate;
0.5 => global float bellNote;


/* Play a sine wave at 440Hz for 1 week */
TubeBell bell => dac;
// 1.0 => bell.noteOn;


while (samp => now)
    {
        Std.mtof(bellNote ) => bell.freq;
        bellGate => bell.noteOn;
       
}'
]
