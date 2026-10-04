# phuck
![Phuck](phuck-logo.png)


Run [ChucK](https://chuck.stanford.edu/) inside Pharo: compile shreds, set and get globals, listen to events, drive audio. A C shim (libphuck) and uFFI bindings to run the ChucK VM, compile code, and exchange globals and events from Pharo.

**FFI bindings generated using [Pharo-CIG](https://github.com/pharo-cig/pharo-cig)**

##Installation with Metacello
```smalltalk
Metacello new
	baseline: 'Phuck';
	repository: 'github://lucretiomsp/Phuck:main/src';
	load.
```

## Simplest usage
```smalltalk
"Boot ChucK and open the sound card"
ck := PhuckVM uniqueInstance.

"Start a sine with a global frequency"
shred:= ck run: 'global float freq; 320 => freq;
TriOsc s => dac; 0.2 => s.gain;
while (true) { freq => s.freq; 10::ms => now; }'.

"Change the frequency live (Integer is fine: freq is declared float)"
ck setValue: 330 parameter: 'freq'.
ck setValue: 440 parameter: 'freq'.

"Swap the code, same shred object"
shred replace: 'global float freq; 220 => freq;
SqrOsc t => dac; 0.2 => t.gain;
while (true) { freq => t.freq; 10::ms => now; }'.

ck setValue: 110 parameter: 'freq'.

"Print from ChucK, then read the console"
ck run: '<<< "hello from ChucK" >>>;'.
ck output.

"A compile error leaves the running shred untouched"
shred replace: 'not chuck'.
ck removeShred: 2.
"Stop"
shred remove.
ck releaseVM.
```
