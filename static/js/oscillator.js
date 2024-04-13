const noteNames = [
    ["A"],
    ["A#", "Bb"],
    ["B"],
    ["C"],
    ["C#", "Db"],
    ["D"],
    ["D#", "Eb"],
    ["E"],
    ["F"],
    ["F#", "Gb"],
    ["G"],
    ["G#", "Ab"]
]

var notes = [];     // all notes, names, frequencies
var keyboard = {};  // mapping of keys to notes
var keys = {};      // currently pressed keys
var voices = {};    // active voices
var octave = 4;     // current octave


// var scale = {
//     "attack": valueArray("exponential", 16, 5000),
//     "decay": valueArray("exponential", 16, 5000),
//     "sustain": valueArray("linear", 16, 100),
//     "release": valueArray("exponential", 16, 5000),
//     "volume": valueArray("exponential", 16, 100),
// }


var scale = {
    "attack": valueArray("exponential", 128, 5000),
    "decay": valueArray("exponential", 128, 5000),
    "sustain": valueArray("linear", 128, 100),
    "release": valueArray("exponential", 128, 5000),
    "volume": valueArray("exponential", 100, 100),
}

// a Note is a frequency with note name and octave
function Note(frequency, octave, names) {
    this.frequency = frequency;
    this.octave = octave;
    this.names = names;
}

// voice is a 
function Voice() {
    let selectedRadio = document.querySelector('input[name="waveform"]:checked');
    this.wave = selectedRadio ? selectedRadio.value : 'sine';
    this.v = document.getElementById('volume').value;
    this.a = scale["attack"][document.getElementById('attack').value];
    this.d = scale["decay"][document.getElementById('decay').value];
    this.s = scale["sustain"][document.getElementById('sustain').value];
    this.r = scale["release"][document.getElementById('release').value];
    this.oscillator = context.createOscillator();
    this.oscillator.type = this.wave;
    this.gainNode = context.createGain();
}

function getVoice() {
    return new Voice()
}

function setTemperament(aEqualsHz) {
    if (config.profile) console.time("setTemperament") // profile
    var a = aEqualsHz || 440;
    a = a / Math.pow(2, octave + 1)
    console.log(`setting temperament based on A4=${a} Hz`)
    var octaveName = 3 - octave // for note name (A4, A3, A2, etc.)
    var octaveRange = 10 // number of octaves to calculate

    for (var i = 0; i < octaveRange; i++) {
        for (var j = 0; j < 12; j++) {
            hz = a * Math.pow(2, j/12);
            var newNote = new Note(hz, octaveName, noteNames[j]);
            notes.push(newNote)
        }
        a = a * 2;
        octaveName += 1;
    }
    if (config.profile) console.timeEnd("setTemperament") // profile
    return notes;
}

// chromatic like a bass
function mapKeyboardToNotes(octave) {
    if (config.profile) console.time("mapKeyboardToNotes") // profile
    var notesInScale = 12 // assume 12TET
    var distanceBetweenStrings = 5; // 5 half steps is a "fourth" apart

    // keyboard rows interpreted as bass guitar strings "e, a, d, g"
    var g = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"];
    var d = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]"];
    var a = ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"];
    var e = ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"];
    var strings = [e, a, d, g];

    // uppercase of the same should be an octave up
    var G = ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+"];
    var D = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}"];
    var A = ["A", "S", "D", "F", "G", "H", "J", "K", "L", ":", "\""];
    var E = ["Z", "X", "C", "V", "B", "N", "M", "<", ">", "?"];
    var STRINGS = [E, A, D, G];

    // temperament is based off the A4 note, and anchored at the "a" of asdf
    // so we need to be able to start at the "string" below it
    var startingNoteIndex = notesInScale - distanceBetweenStrings;
    startingNoteIndex += octave * notesInScale;
    if (config.debug) console.log(`octave:${octave}\nstartingNoteIndex: ${startingNoteIndex}`)
    
    var key = {}; // k/v pairs of keyboard/note
    // each "string"
    for (var i = 0; i < strings.length; i++) {
        currentNoteIndex = startingNoteIndex + (i * distanceBetweenStrings);
        // each "fret" assigns a key to a note
        for (var j = 0; j < strings[i].length; j++) {
            key[strings[i][j]] = notes[currentNoteIndex + j]
        }
    }

    // each "STRING"
    startingNoteIndex += notesInScale;
    for (var i = 0; i < STRINGS.length; i++) {
        currentNoteIndex = startingNoteIndex + (i * distanceBetweenStrings);
        // each "fret" assigns a key to a note
        for (var j = 0; j < STRINGS[i].length; j++) {
            key[STRINGS[i][j]] = notes[currentNoteIndex + j]
        }
    }        

    if (config.profile) console.timeEnd("mapKeyboardToNotes") // profile
    return key
}

function octaveUp() {
    var octaveMax = 8;
    octave = parseInt(document.getElementById('octave').innerText);
    if (octave < octaveMax) {
        octave += 1;
        document.getElementById('octave').innerText = octave;
        keyboard = mapKeyboardToNotes(octave);
    } else {
        console.log(`Octave cannot exceed ${octaveMax}`)
    }
}

function octaveDown() {
    var octaveMin = 0;
    octave = parseInt(document.getElementById('octave').innerText);
    if (octave > octaveMin) {
        octave -= 1;
        document.getElementById('octave').innerText = octave;
        keyboard = mapKeyboardToNotes(octave);
    } else {
        console.log(`Octave cannot be less than ${octaveMin}`)
    }
}

function noteStart(event) {
    // if key is not already down
    if (!keys[event.key]) {
        if (config.profile) console.time("noteStart") // profile
        keys[event.key] = true;
        if (config.debug) {
            console.log(`${event.key} ⬇️`);
        }
        // and the key is mapped to a note
        if (keyboard.hasOwnProperty(event.key) && !voices.hasOwnProperty(event.key)) {
            // change note display
            var noteName;
            if (keyboard[event.key].names.length > 1 && config.noteNameStyle == "flats") {
                noteName = keyboard[event.key].names[1];
            } else {
                noteName = keyboard[event.key].names[0];
            }
            displayNote = `${noteName}${keyboard[event.key].octave}`
            document.getElementById("playing").innerHTML = displayNote;
            
            // get voice, start oscillator, and add to dict of active voices
            var v = getVoice();
            if (config.debug) {
                console.log(`${displayNote}
V: ${v.v}% system max
W: ${v.wave}
F: ${keyboard[event.key].frequency}Hz
A: ${v.a}ms
D: ${v.d}ms
S: ${v.s}% volume
R: ${v.r}ms
`)
            }
            v.oscillator.frequency.value = keyboard[event.key].frequency;
            v.oscillator.connect(v.gainNode);
            v.gainNode.connect(context.destination);
            v.gainNode.gain.setValueAtTime(0, context.currentTime);
            v.oscillator.start();

            // attack
            aSec = v.a / 1000
            vol = v.v / 100
            v.gainNode.gain.linearRampToValueAtTime(vol, context.currentTime + aSec);

            // decay / sustain
            dSec = v.d / 1000
            sustain = v.s / 100
            v.gainNode.gain.linearRampToValueAtTime(vol * sustain, context.currentTime + aSec + dSec)

            voices[event.key] = v;
        }
        if (config.profile) console.timeEnd("noteStart") // profile
    }
}

function noteStop(event) {
    if (keys[event.key]) {
        if (config.profile) console.time("noteStop") // profile
        keys[event.key] = false;
        if (config.debug) {
            console.log(`${event.key} ⬆️`);
        }
        if (voices.hasOwnProperty(event.key)) {
            var v = voices[event.key];
            // release
            rSec = (v.r / 1000) + aSec
            v.gainNode.gain.linearRampToValueAtTime(0, context.currentTime + rSec);
            v.oscillator.stop(context.currentTime + rSec);
            delete voices[event.key];
        }
        if (config.profile) console.timeEnd("noteStop") // profile
    }
}

// returns an array from 0 to max
// for use in slider scaling
function valueArray(curve, steps, max) {
    let sequence = [];
    let minInterval = 1;

    switch (curve) {
        case "exponential":
            let calculatedSteps = steps - 2; // for initial 0 and max
            for(let i = 0; i < calculatedSteps; i++) {
                let factor = Math.pow(max/1, 1/(calculatedSteps));
                value = Math.round(1 * Math.pow(factor, i));
                
                // increment by one if calculated value is less or equal to prior value
                if (i > 0 && value <= sequence[i - 1]) {
                    console.log(`sequence[i-1]: ${sequence[i-1]}`)
                    value = sequence[i-1] + minInterval;
                    console.log(`value (updated): ${value}`)
                }
                console.log(`value (updated): ${value}`)
                sequence.push(value);
            }
            sequence.unshift(0);
            sequence.push(max);
            // length print to console
            console.log(`Created 'exponential' curve sequence (len:${sequence.length}):\n${sequence}`)
            console.log(`sequence: `)
            return sequence;

        default: // linear
            for(let i = 0; i <= steps; i++) {
                sequence.push(i * max / steps);
            }
            return sequence.map(Math.round);
    }
}