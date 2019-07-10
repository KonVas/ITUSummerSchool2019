//Retrieved from https://sccode.org/1-58C

(
s.waitForBoot({
	var intro, introFasterAttack, fastarpeggio, arpeggio, percussion, flute, lead1, bass, score;
	var parser = TheoryNoteParser.new;

	SynthDef(\fatsaw, {
		| out=0, freq = 440, amp=0.1, gate=1, attack=0.01, decay=0.3, sustain=0.5, release=1, filterSpeed=100, filterFreqStart=300, filterFreqEnd=400, resonance=1, hfFilterFreq=1, hfFilterResonance=1 |
		var sig, env, filtFreq;
		env = EnvGen.ar(Env.adsr(attack, decay, sustain, release), gate, levelScale:0.5, doneAction:Done.freeSelf);
		sig = env*Splay.ar(LFSaw.ar(freq*[0.98,0.99,1.0,1.01,1.02],[LFNoise0.kr(2), LFNoise0.kr(1.9), LFNoise0.kr(2.1)]) + SinOsc.ar(freq*[0.98,0.99,1.0,1.01,1.02],[LFNoise0.kr(2), LFNoise0.kr(1.9), LFNoise0.kr(2.1)]));
		filtFreq = LFSaw.kr(filterSpeed,iphase:1).range(filterFreqStart,filterFreqEnd);
		sig = RLPF.ar(sig, filtFreq, resonance);
		sig = RHPF.ar(sig, hfFilterFreq, hfFilterResonance);
		2.do({
			sig = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], 1);
		});
		Out.ar(out, amp*sig.tanh);
	}).add;

	SynthDef(\organ, {
		| out = 0, freq = 440, amp=0.1, gate=1, attack=0.01, decay=0.3, sustain=0.5, release=1 |
		var sig, env;
		sig = 0.5*Klang.ar(`[[freq/8, freq/4, freq/2, freq, freq*2, freq*4, freq*8],[0.7, 0.7, 0.7, 1, 1, 0.6, 0.4],[0,0.1,0.2,0.3,0.4,0.5,0.6]]);
		sig = RLPF.ar(sig, 5000, 1);
		env = EnvGen.ar(Env.adsr(attack,decay, sustain, release), gate, doneAction:Done.freeSelf);
		sig = env*sig;
		4.do({
			sig = AllpassN.ar(sig, 0.050, [0.050.rand, 0.050.rand], 1);
		});
		Out.ar(out, amp*sig.tanh);
	}).add;

	SynthDef(\kick, {
		|out = 0, pan = 0, amp = 0.3, filterFreq=100|
		var body, bodyFreq, bodyAmp;
		var pop, popFreq, popAmp;
		var click, clickAmp;
		var snd;

		// body starts midrange, quickly drops down to low freqs, and trails off
		bodyFreq = EnvGen.ar(Env(0.7*[261, 120, 51], [0.035, 0.08], curve: \exp));
		bodyAmp = EnvGen.ar(Env.linen(0.005, 0.1, 0.3), doneAction: 2);
		body = LFTri.ar(bodyFreq) * bodyAmp;
		// pop sweeps over the midrange
		popFreq = XLine.kr(750, 261, 0.02);
		popAmp = EnvGen.ar(Env.linen(0.001, 0.02, 0.001)) * 0.15;
		pop = LFTri.ar(popFreq) * popAmp;
		// click is spectrally rich, covering the high-freq range
		// you can use Formant, FM, noise, whatever
		clickAmp = EnvGen.ar(Env.perc(0.001, 0.01)) * 0.15;
		click = LPF.ar(Formant.ar(910, 4760, 2110), 3140) * clickAmp;

		snd = body + pop + click;
		snd = RLPF.ar(snd, filterFreq);
		snd = snd.tanh;

		Out.ar(out, Pan2.ar(snd, pan, amp));
	}).add;

	s.sync;

	~tempoFactor = 0.18;

	intro = Pbind(
		\instrument, \fatsaw,
		\amp, 1.2,
		\attack, 3,
		\decay, 0.1,
		\sustain, 1,
		\release, 5,
		\filterSpeed, Pfunc({~tempoFactor*0.5}),
		\filterFreqStart, 50,
		\filterFreqEnd, 800,
		\midinote, Pseq(["e3 g3 b3"].collect({|el| parser.asMidi(el)}), 1),
		\dur, Pseq([6],1));
	//intro.play;

	introFasterAttack = Pbind(
		\instrument, \fatsaw,
		\amp, 0.5,
		\attack, 0.01,
		\decay, 0.3,
		\sustain, 1,
		\release, 2,
		\filterSpeed, Pfunc({1/(~tempoFactor*6*4);}),
		\filterFreqStart, 50,
		\filterFreqEnd, 3000,
		\midinote, Pseq(["e3 g3 b3"].collect({|el| parser.asMidi(el)}), 1),
		\dur, 4);

	fastarpeggio = Pbind(
		\instrument, \organ,
		\amp, Pseq([0.6,0.15,0.2,0.25,0.3,0.25,0.2,0.15]*0.1, inf),
		\attack, 0.1,
		\decay, 0.1,
		\sustain, 0.3,
		\release, 1,
		\dur, Pfunc({~tempoFactor/2}),
		\midinote, Pseq(parser.asMidi("c5 e5 g5 b5 c6 b5 g5 e5"), 6)
	);
	//fastarpeggio.play;

	percussion = Pbind(
		\instrument, \kick,
		\amp, Pseq([0.9,0.8], inf),
		\filterFreq, Pseq([Pseq([1000], 4), Pseq([2000], 4)], inf),
		\dur, Pseq([~tempoFactor], inf),
		\filterSpeed, 0.1,
		\filterFreqStart, 50,
		\filterFreqEnd, 300,
		\midinote, Pseq(parser.asMidi("c3 c3") ++ [Rest(), Rest()], 60),
	);
	//percussion.play;

	arpeggio = Pbind(
		\instrument, \fatsaw,
		\amp, 0.6,
		\attack, 0.01,
		\decay, 0.3,
		\sustain, 0.1,
		\release, 0.4,
		\time, Ptime(inf),
		\resonance, Pfunc({ |ev| ev['time'].linexp(0,10,1,0.2); }),
		\midinote, Pseq(parser.asMidi("c2 e2 g2 b2 c3 b2 g2 e2"), 14+4+4+6),
		\dur, Pfunc({~tempoFactor}));
	//arpeggio.play;

	flute = Pbind(
		\instrument, \fatsaw,
		\amp, 0.4,
		\attack, 3,
		\decay, 0.3,
		\sustain, 3,
		\release, 4,
		\filterSpeed, Pfunc({~tempoFactor}),
		\filterFreqStart, 200,
		\filterFreqEnd, 6000,
		\midinote, Pseq(["g4 b4 g5 b5"].collect({|el| parser.asMidi(el); }), 1),
		\dur, Pfunc({~tempoFactor*5});
	);

	lead1 = Pbind(
		\instrument, \fatsaw,
		\amp, 0.2,
		\attack, 0.01,
		\decay, 0.3,
		\sustain, 1,
		\release, 1,
		\resonance, 0.2,
		\filterSpeed, Pfunc({~tempoFactor}),
		\filterFreqStart, 3000,
		\filterFreqEnd, 4000,
		\hfFilterFreq, 10,
		\midinote, Pseq(["b1 b2 b3", "g2 g3 g4"].collect({|el| parser.asMidi(el)}), 1),
		\dur, Pfunc({~tempoFactor*4}),
	);

	//lead1.play;

	bass = Pbind(
		\instrument, \fatsaw,
		\amp, Pseq([0.3, 0.2, 0.2, 0.18, 0.2, 0.18, 0.2, 0.18]*2,inf),
		\attack, 0.01,
		\decay, 0.5,
		\sustain, Pseq([1,0.7,1,0.7],inf),
		\release, 8,
		\filterSpeed, 0.1,
		\filterFreqStart, 2000,
		\filterFreqEnd, 3000,
		\resonance, 0.8,
		\hfFilterFreq, 5,
		\midinote, Pseq(["c1 c2 c3", "d1 d2 d3 ", "e1 e2 e3", "d1 d2 d3"].collect({|el| parser.asMidi(el)}), 2),
		\dur, Pseq([~tempoFactor*24, ~tempoFactor*8, ~tempoFactor*24, ~tempoFactor*8],inf)
	);
	//bass.play;

	score = Ptpar([
		0.0, intro,
		0.0, fastarpeggio,
		~tempoFactor*8*3, percussion,
		~tempoFactor*8*3, arpeggio,
		~tempoFactor*8*9, introFasterAttack,
		~tempoFactor*8*10, flute,
		~tempoFactor*8*13, lead1,
		~tempoFactor*8*14, bass
	]);
	score.play;
});
)