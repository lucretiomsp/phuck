"
Every Pharo object that becomes a named variable in ChucK has to answer the same three questions when code is printed:

What is its variable name (synth1)?
What is its ChucK type (SinOsc)?
How do auto-generated names get numbered?

CkObject answers all three in one place:

It takes the defaults from the class name (strip Ck).
It numbers names with per-class counters, reset in tests.
named: lets you override a name.
The name is only computed the first time it's printed.
"
Class {
	#name : 'CkObject',
	#superclass : 'Object',
	#instVars : [
		'name'
	],
	#classVars : [
		'Counters'
	],
	#category : 'PhuckLang',
	#package : 'PhuckLang'
}
