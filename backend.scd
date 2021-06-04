// Note: DO NOT run the file more than once. It will cause reduplicate callbacks
// Select all and run.

// NetAddr.langPort;
s.boot;

// The max number of simultaneous sustaining sounds for each effect
~size = 10;
// Indication of whether specific keys are down
~tremoloOn = 0;
~slideOn = 0;
~vibratoOn = 0;
~sustainOn = 0;
~addSound = 0;

// Array of sustaining sounds
~tremoloSounds = Array.new(~size);
~slideSounds = Array.new(~size);
~vibratoSounds = Array.new(~size);
~sustainSounds = Array.new(~size);

/*~addingDone = Condition.new(true);
~releasingDone = Condition.new(true);*/

// Used to avoid memory releasing in the creation of sounds
~node = nil;

// Used for slide effects
~lastFreq = 440;

// Release all sustaining sounds and clear the arrays
~releaseSoundsF = {
	/*"releasing".postln;
	~releasingDone.test = false;*/

	[~tremoloSounds, ~slideSounds,~vibratoSounds, ~sustainSounds].do({
		arg sounds, i;
		sounds.do({
			arg sound, i;
			"% releaesed\n".postf(sound);
			sound.release;
		});
		~size.do({
			if(sounds[0] != nil, {
				"% removed\n".postf(sounds[0]);
				sounds.removeAt(0);

			});
		});
	});
	/*~releasingDone.test = true;
	~releasingDone.signal;
	"releasing done".postln;*/
};

// Add a sound to a sustaining sounds array
~addSoundF = {
	arg sounds, sound;
	var lastSound;
	/*"adding".postln;
	~addingDone.test = false;*/
	lastSound = sounds.at(~size - 1);

	// If the array is full, replace the last sound
	if(lastSound != nil, {
		"% releaesed\n".postf(lastSound);
		lastSound.release;
		// sounds.postln;
		sounds[~size - 1] = sound;
		// sounds.postln;
	}, {
		sounds.add(sound);
	});
	"% added\n".postf(sound);
	/*~addingDone.test = true;
	~addingDone.signal;
	"adding done".postln;*/
};

// Slide from ~lastFreq to freq
(
SynthDef.new("slide", { arg freq, dur, out = 0, level = 0.02;
	var env, sound;
	env = Env.triangle(level:level, dur:dur);
	sound = EnvGen.kr(env, doneAction:Done.freeSelf) * SinOsc.ar(Line.kr(~lastFreq, freq, dur));
	Out.ar(out, sound!2);
}).add;
);
// Synth("slide", ["freq", 440, "dur", 1]);

// Slide from ~lastFreq to freq and sustain
(
SynthDef("slideSustain", {arg freq, releaseTime, gate = 1, out = 0, level = 0.02;
	var env, sound;
	env = Env.asr(sustainLevel: level, releaseTime: releaseTime);
	sound = EnvGen.kr(env, gate, doneAction:Done.freeSelf) * SinOsc.ar(Line.kr(~lastFreq, freq, 1));
	Out.ar(out, sound!2);
}).add;
);
/*x = Synth("slideSustain", ["freq", 500, "releaseTime", 1]);
x.release;*/

// A simple note without effects
(
SynthDef.new("base", { arg freq, dur, out = 0, level = 0.02;
	var env, sound;
	env = Env.triangle(level:level, dur:dur);
	sound = EnvGen.kr(env, doneAction:Done.freeSelf) * SinOsc.ar(freq);
	Out.ar(out, sound!2);
}).add;
);
// Synth("base", ["freq", 440, "dur", 1]);

// A sustaining simple note without effects
(
SynthDef("baseSustain", {arg freq, releaseTime, gate = 1, out = 0, level = 0.02;
	var env, sound;
	env = Env.asr(sustainLevel: level, releaseTime: releaseTime);
	sound = EnvGen.kr(env, gate, doneAction:Done.freeSelf) * SinOsc.ar(freq);
	Out.ar(out, sound!2);
}).add;
);
/*x = Synth("baseSustain", ["freq", 440, "releaseTime", 1]);
x.release;*/

// A sound vibrating the frequency
(
SynthDef.new("vibrato", { arg freq, dur, out = 0, level = 0.02;
	var env, sound;
	env = Env.triangle(level:level, dur:dur);
	sound = EnvGen.kr(env, doneAction:Done.freeSelf) * SinOsc.ar(Vibrato.kr(freq, 5, 0.01));
	Out.ar(out, sound!2);
}).add;
);
// Synth("vibrato", ["freq", 400, "dur", 1]);

// A sustaining sound vibrating the frequency
(
SynthDef("vibratoSustain", {arg freq, releaseTime, gate = 1, out = 0, level = 0.02;
	var env, sound;
	env = Env.asr(sustainLevel: level, releaseTime: releaseTime);
	sound = EnvGen.kr(env, gate, doneAction:Done.freeSelf) * SinOsc.ar(Vibrato.kr(freq, 5, 0.01));
	Out.ar(out, sound!2);
}).add;
);
/*x = Synth("vibratoSustain", ["freq", 440, "releaseTime", 1]);
x.release;*/

// A sound vibrating the amplitude
(
SynthDef.new("tremolo", { arg freq, dur, out = 0, level = 0.02;
	var env, sound;
	env = Env.triangle(level:level, dur:dur);
	sound = EnvGen.kr(env, doneAction:Done.freeSelf) * SinOsc.ar(freq, 0, SinOsc.ar(4));
	Out.ar(out, sound!2);
}).add;
);
// Synth("tremolo", ["freq", 440, "dur", 1]);

// A sustaining sound vibrating the amplitude
(
SynthDef("tremoloSustain", {arg freq, releaseTime, gate = 1, out = 0, level = 0.02;
	var env, sound;
	env = Env.asr(sustainLevel: level, releaseTime: releaseTime);
	sound = EnvGen.kr(env, gate, doneAction:Done.freeSelf) * SinOsc.ar(freq, 0, SinOsc.ar(4));
	Out.ar(out, sound!2);
}).add;
);
/*x = Synth("tremoloSustain", ["freq", 440, "releaseTime", 1]);
x.release;*/

// Route a sound based on all the keys status
(
~mouseF = {
	arg msg, time, addr;
	var freq, dur, sound;
    if (msg[0] == '/mouse') {

		// Map x from 0-300 to midi code 0-127.
		// Convert midi to frequency.
		freq = (msg[1] / 300 * 127).midicps;
		~lastFreq = freq;
		// Map y from 0-200 to duration 0s - 2s;
		dur = (msg[2] / 200 * 2);
		// No keys are pressed
		if(~slideOn + ~vibratoOn + ~tremoloOn + ~sustainOn == 0, {
			Synth("base", ["freq", freq, "dur", dur]);
		});
		// Route priority: slide, vibrato, tremolo, which are exclusive.
		// Sustain can work with the above three effects, and work itself.
		// Without A (add key) pressed and with Space (sustain key) pressed,only the first sound for each effect, will be sustained.
		if(~slideOn == 1, {
			if (~sustainOn == 1, {
			if(~slideSounds[0] == nil, {
				~node = Synth("slideSustain", ["freq", freq, "releaseTime", dur]);
				~addSoundF.value(~slideSounds, ~node);
			}, {
				if(~addSound == 1, {
					~node = Synth("slideSustain", ["freq", freq, "releaseTime", dur]);
					~addSoundF.value(~slideSounds, ~node);
				}, {
					Synth("slide", ["freq", freq, "dur", dur]);
				});
			});}, {
				Synth("slide", ["freq", freq, "dur", dur]);
			});
		}, {
			if(~vibratoOn == 1, {
				if(~sustainOn == 1, {
					if(~vibratoSounds[0] == nil, {
						~node = Synth("vibratoSustain", ["freq", freq, "releaseTime", dur]);
						~addSoundF.value(~vibratoSounds, ~node);
					}, {
						if(~addSound == 1, {
							~node = Synth("vibratoSustain", ["freq", freq, "releaseTime", dur]);
							~addSoundF.value(~vibratoSounds, ~node);
						}, {
							Synth("vibrato", ["freq", freq, "dur", dur]);
						});
					});
				}, {
					Synth("vibrato", ["freq", freq, "dur", dur]);
				});
			}, {
				if(~tremoloOn == 1, {
					if(~sustainOn == 1, {
						if(~tremoloSounds[0] == nil, {
							~node = Synth("tremoloSustain", ["freq", freq, "releaseTime", dur]);
							~addSoundF.value(~tremoloSounds, ~node);
						}, {
							if(~addSound == 1, {
								~node = Synth("tremoloSustain", ["freq", freq, "releaseTime", dur]);
								~addSoundF.value(~tremoloSounds, ~node);
							}, {
							Synth("tremolo", ["freq", freq, "dur", dur]);
							});
						});
					}, {
						Synth("tremolo", ["freq", freq, "dur", dur]);
					});
				}, {
					if(~sustainOn == 1, {
						if(~sustainSounds[0] == nil, {
							~node = Synth("baseSustain", ["freq", freq, "releaseTime", dur]);
							/*Routine {
								~releasingDone.wait;
								~addingDone.wait;
								~addSoundF.value(~sustainSounds, ~node);
							}.play;*/
							~addSoundF.value(~sustainSounds, ~node);
						}, {
							if(~addSound == 1, {
								~node = Synth("baseSustain", ["freq", freq, "releaseTime", dur]);
								/*Routine {
									~releasingDone.wait;
									~addingDone.wait;
									~addSoundF.value(~sustainSounds, ~node);
								}.play;*/
								~addSoundF.value(~sustainSounds, ~node);
							}, {
								Synth("base", ["freq", freq, "dur", dur]);
							});
						});
					});
				});
			});
		});
		"tremolo: %, slide: %, vibrato: %, sustain: %, addSound: %\n".postf(~tremoloOn,~slideOn,~vibratoOn,~sustainOn,~addSound);
    };
};
// Add the function as a callback of OSC receiving function
thisProcess.addOSCRecvFunc(~mouseF);
);
// thisProcess.removeOSCRecvFunc(~mouseF);

// Update the status of keys in real-time
(
~keyboardF = { |msg, time, addr|
    if(msg[0] == '/keyboard') {
		if(msg[2] == 's', {
			~slideOn = msg[1];
		});
		if(msg[2] == 't', {
			~tremoloOn = msg[1];
		});
		if(msg[2] == 'r', {
			~vibratoOn = msg[1];
		});
		if(msg[2] == 'Space', {
			~sustainOn = msg[1];
			if(~sustainOn == 0,
				{
					/*Routine {
						~addingDone.wait;
						~releasingDone.wait;
						~releaseSoundsF.value;
					}.play;*/
					~releaseSoundsF.value;
				}
			);
		});
		if(msg[2] == 'a', {
			~addSound = msg[1];
		});
    }
};
// Add the function as a callback of OSC receiving function
thisProcess.addOSCRecvFunc(~keyboardF);
);
// thisProcess.removeOSCRecvFunc(~keyboardF);

// Reset all the status
(
~resetF = { |msg, time, addr|
    if(msg[0] == '/reset') {
		~tremoloSounds = Array.new(~size);
		~slideSounds = Array.new(~size);
		~vibratoSounds = Array.new(~size);
		~sustainSounds = Array.new(~size);

		~addingDone = Condition.new(false);
		~releasingDone = Condition.new(false);

		~node = nil;
		s.freeAll;
    }
};
// Add the function as a callback of OSC receiving function
thisProcess.addOSCRecvFunc(~resetF);
);
// thisProcess.removeOSCRecvFunc(~resetF);