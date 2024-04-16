const defaultA = 440;

var microphoneAccess = null;
var context;
var config = {
    "debug": true,
    "profile": true,
    "flats": true,
    "defaultWave": "triangle"
    // "noteNameStyle": "flats", // sharps or flats
    // "defaultA": 440
}

// // store config into state
// if (localStorage.getItem("config")) {
//     config = JSON.parse(localStorage.getItem("config"));
// } else {
//     localStorage.setItem("config", JSON.stringify(config));
// }

document.addEventListener('DOMContentLoaded', function() {
    permission();
    context = new (window.AudioContext || window.webkitAudioContext)();
    notes = setTemperament(defaultA);
    keyboard = mapKeyboardToNotes(octave);

    // settings
    var flats = document.getElementById("flats")
    flats.checked = config.flats;
    flats.addEventListener("change", function() {
        console.log("flats checkbox changed to " + this.checked);
        config.noteNameStyle = this.checked ? "flats" : "sharps";
    });
    var debug = document.getElementById("debug")
    debug.checked = config.debug;
    debug.addEventListener("change", function() {
        console.log("debug checkbox changed to " + this.checked);
        config.debug = this.checked;
    });
    var profile = document.getElementById("profile")
    profile.checked = config.profile;
    document.getElementById("profile").addEventListener("change", function() {
        console.log("profile checkbox changed to " + this.checked);
        config.profile = this.checked;
    });
    
    // key listeners
    document.addEventListener('keydown', function(event) {
        switch (event.key) {
            case "-":
            case "_":
                if (config.debug) console.log("octave down");
                octaveDown();
                break;
            case "=":
            case "+":
                if (config.debug) console.log("octave up");
                octaveUp();
                break;
            case "Escape":
                if (config.debug) console.log("resetting octave");
                noteStopAll();
                break;
            default:
                noteStart(event);
        }
    });
    document.addEventListener('keyup', function(event) {
        noteStop(event)
    });

    // input
    document.querySelectorAll('#input button').forEach(function(button) {
        button.addEventListener('click', function() {
            // Remove the 'selected' class from all buttons
            document.querySelectorAll('#input button').forEach(function(btn) {
                btn.classList.remove('selected');
            });
    
            // Add the 'selected' class to the clicked button
            button.classList.add('selected');
    
            if (config.debug) {
                console.log("input source changed to " + button.id);
            }
        });
    });
    // Set default selected button for source
    let defaultSource = document.getElementById("qwerty");
    defaultSource.classList.add('selected');
    
    // octave
    var octaveUpButton = document.getElementById("octaveUp");
    octaveUpButton.addEventListener("click", octaveUp);
    var octaveDownButton = document.getElementById("octaveDown");
    octaveDownButton.addEventListener("click", octaveDown);

    // sliders
    sliders = ["attack", "decay", "sustain", "release"];
    setupSliders(sliders);

    // wave
    document.querySelectorAll('#wave button').forEach(function(button) {
        button.addEventListener('click', function() {
            // Remove the 'selected' class from all buttons
            document.querySelectorAll('#wave button').forEach(function(btn) {
                btn.classList.remove('selected');
            });
    
            // Add the 'selected' class to the clicked button
            button.classList.add('selected');
    
            if (config.debug) {
                console.log("waveform changed to " + button.id);
            }
        });
    });
    // Set default selected button for wave
    let defaultButton = document.getElementById(config.defaultWave);
    defaultButton.classList.add('selected');
});

// sets up ADSR sliders
function setupSliders(sliders) {
    // loop through sliders
    sliders.forEach(function(sliderName) {
        console.log(`setting up slider for ${sliderName}`)
        let initPos = 64

        // Select the slider and the display element
        // let elementText = sliderName;
        let slider = document.getElementById(sliderName);
        // let initPos = slider.value;
        let displayText = `${sliderName}Display`;
        let display = document.getElementById(displayText);
        
        // default slider position value
        slider.value = initPos;
        // default value for oscillator/display
        display.textContent = scale[sliderName][initPos];
    
        // Listen for the input event on the slider
        slider.addEventListener('input', function(event) {
            let sliderName = event.target.id;
            // Slider position may only have a small number of units
            // 128 possible midi values, or 100 percent for a volume unit
            // this number should be small enough to traverse in a couple of
            // seconds by holding arrow keys until they repeat 
            let pos = event.target.value;
    
            // Each slider position will map to an oscillator value
            // from a precalculated array. This is shown to user.
            display.textContent = scale[sliderName][pos];
            if (config.debug) {
                console.log(`${sliderName}=${pos} (${scale[sliderName][pos]})`);
            }
        });
    });
}

function permission() {
    if (navigator.permissions) {
        navigator.permissions.query({name: 'microphone'})
        .then(function(permissionStatus) {
            console.log('Permission status:', permissionStatus.state);
            if (permissionStatus.state == "granted") {
                microphoneAccess = true;
            }
            permissionStatus.onchange = function() {
                console.log('Permission status changed to ', this.state);
            };
        });
    }
}

function requestInput() {
    navigator.mediaDevices.getUserMedia({ audio: true })
    .then(function(stream) {
        console.log("Input access granted.");
        return stream
        // You have access to the microphone here
    })
    .catch(function(err) {
        console.log("Input access denied.");
        alert("⚠️ Some functions may not work properly without an input device. Enable microphone access.")
        return null
    });
}
