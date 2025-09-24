
var audioCtx:AudioContext;
var source : MediaElementAudioSourceNode;
var source2 : MediaElementAudioSourceNode;
var audioElement = document.createElement('audio');
var audioElement2 = document.createElement('audio');
audioElement.style['position'] = 'fixed';
audioElement.controls = false;
audioElement.src = "./audio.mp3";
audioElement.crossOrigin = 'anonymous';
document.body.insertBefore(audioElement, document.body.firstElementChild);
audioElement2.style['position'] = 'fixed';
audioElement2.controls = false;
audioElement2.src = "./audio2.mp3";
audioElement2.crossOrigin = 'anonymous';
document.body.insertBefore(audioElement2, document.body.firstElementChild);

var analyser:AnalyserNode;
var bufferLength:number;
var dataArray:Uint8Array;
var filter:BiquadFilterNode;
var analyserLowPass:AnalyserNode;



function init(){
    audioCtx = new AudioContext();
    if(audioCtx.state!="running"){
        console.log("ctx is not running!");
        console.log("ctx state "+ audioCtx.state)
        audioCtx.resume().then(() => {
            console.log('AudioContext resumed successfully!');
            source = new MediaElementAudioSourceNode(audioCtx, {
                mediaElement: audioElement,
            });
            if(source){
                console.log("source channel count"+source.numberOfOutputs);
            }
        
            source.disconnect();
            source.connect(audioCtx.destination);
            // Now you can play audio
        }).catch(error => {
            console.error('Error resuming AudioContext:', error);
        });
    }
    audioCtx.addEventListener('statechange', () => {
        console.log('AudioContext state:', audioCtx.state);
    });
    source = new MediaElementAudioSourceNode(audioCtx, {
        mediaElement: audioElement,
    });
    source2 = new MediaElementAudioSourceNode(audioCtx, {
        mediaElement: audioElement2,
    });
    if(source){
        console.log("source channel count"+source.numberOfOutputs);
    }
    if(source2){
        console.log("source channel count"+source2.numberOfOutputs);
    }
    analyser = audioCtx.createAnalyser();
    analyser.fftSize = 64; // Set FFT size (power of 2, e.g., 32, 64, ..., 32768)
    analyserLowPass = audioCtx.createAnalyser();
    analyserLowPass.fftSize = 2048;
    bufferLength = analyser.fftSize;
    dataArray = new Uint8Array(bufferLength); // For byte data
    filter = audioCtx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(100, audioCtx.currentTime); // e.g., low-pass filter at 10
    filter.gain.setValueAtTime(2, audioCtx.currentTime);
    filter.Q.setValueAtTime(6.,  audioCtx.currentTime);
    source.connect(filter).connect(analyserLowPass);
    source.connect(analyser).connect(audioCtx.destination);
    source2.connect(filter).connect(analyserLowPass);
    source2.connect(analyser).connect(audioCtx.destination);
}



export class AudioController{
    initialized:boolean;
    constructor(){
        this.initialized = false;
    }

    playAudio(index:number) {
        if(!audioCtx){
            console.log("Init ctx");
            init();
        }
        this.initialized = true;
        audioElement.pause();
        // this.audio2Element.pause();
        var curAudio = index==0?audioElement : audioElement2;
        curAudio.play();
    }

    pauseAudio(){
        console.log("AUDIO PAUSED");
        audioElement.pause();
        //this.audio2Element.pause();
    }
    
    getAmplitude() : number {
        analyser.getByteTimeDomainData(dataArray); // Fills dataArray with waveform data
    
        // Calculate average amplitude (e.g., RMS)
        let sumSquares = 0;
        for (let i = 0; i < bufferLength; i++) {
            const value = (dataArray[i] - 128) / 128; // Normalize to -1 to 1 range
            sumSquares += value * value;
        }
        const rms = Math.sqrt(sumSquares / bufferLength);
        //console.log("amp "+rms);
        return rms;
    }

    getLowPassAmp() : number{
        analyserLowPass.getByteTimeDomainData(dataArray); // Fills dataArray with waveform data
    
        // Calculate average amplitude (e.g., RMS)
        let sumSquares = 0;
        for (let i = 0; i < bufferLength; i++) {
            const value = (dataArray[i] - 128) / 128; // Normalize to -1 to 1 range
            sumSquares += value * value;
        }
        const rms = Math.sqrt(sumSquares / bufferLength);
        //console.log("amp LP "+rms);
        return rms;
    }
};