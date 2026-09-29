"
I am the Pharo-side facade to a *ChucK* virtual machine running in _libphuck_.

I own a Phuck handle and hide the raw LibPhuck calls: VM setup and parameters, starting and stopping audio, compiling code into shreds, setting and reading globals, events and console output.

Use PhuckVM default for the single realtime VM (*ChucK*''s audio layer allows only one per process). Offline instances, driven block by block with render:, can be created for tests.

Rules inherited from the shim:
- nothing calls back into Pharo: events and console are polled;
- setters apply at the next audio block;
- getters are asynchronous: request, wait until ready, read, free.

After an image restart my handle is null: I recreate the VM on first use. Call release to stop audio and free the VM.
"
Class {
	#name : 'PhuckVM',
	#superclass : 'PhuckBaseObject',
	#category : 'PhuckFFI-Base',
	#package : 'PhuckFFI',
	#tag : 'Base'
}
