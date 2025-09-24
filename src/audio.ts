export class AudioController{
    audioCtx:AudioContext;
    analyser:AnalyserNode;
    bufferLength:number;
    dataArray:Uint8Array;
    audioElement:HTMLAudioElement;
    audio2Element:HTMLAudioElement;
    filter:BiquadFilterNode;
    analyserLowPass:AnalyserNode;
    source : MediaElementAudioSourceNode;
    source2 : MediaElementAudioSourceNode;
    constructor(){
        this.audioElement = document.createElement('audio');
        this.audioElement.style['position'] = 'fixed';
        this.audioElement.controls = true;
        this.audioElement.src = "./audio.mp3";
        this.audioElement.crossOrigin = 'anonymous';

        this.audio2Element = document.createElement('audio');
        this.audio2Element.controls = false;
        this.audio2Element.src = "./audio2.mp3";
        this.audio2Element.crossOrigin = 'anonymous';

        this.audioCtx = new AudioContext();
        this.analyser = this.audioCtx.createAnalyser();
        this.analyser.fftSize = 2048; // Set FFT size (power of 2, e.g., 32, 64, ..., 32768)
        this.analyserLowPass = this.audioCtx.createAnalyser();
        this.analyserLowPass.fftSize = 2048;
        this.bufferLength = this.analyser.fftSize;
        this.dataArray = new Uint8Array(this.bufferLength); // For byte data
        this.filter = this.audioCtx.createBiquadFilter();
        this.filter.type = 'lowpass';
        this.filter.frequency.setValueAtTime(250, this.audioCtx.currentTime); // e.g., low-pass filter at 1000 Hz
        this.filter.gain.setValueAtTime(2, this.audioCtx.currentTime);
        this.filter.Q.setValueAtTime(8.,  this.audioCtx.currentTime);

        
        this.source = new MediaElementAudioSourceNode(this.audioCtx, {
            mediaElement: this.audioElement,
          });
        this.source2 = new MediaElementAudioSourceNode(this.audioCtx, {
            mediaElement: this.audio2Element,
          });
        this.source.connect(this.analyser);
        this.source2.connect(this.analyser);
        this.analyser.connect(this.audioCtx.destination); // Connect to output if you want to hear it
        this.source.connect(this.filter);
        this.source2.connect(this.filter);
        this.filter.connect(this.analyserLowPass);
    }

    playAudio(index:number) {
        this.audioElement.pause();
        this.audio2Element.pause();
        alert("Playing audio ...");
        var curAudio = index==0?this.audioElement : this.audio2Element;
        curAudio.play();
    }

    pauseAudio(){
        console.log("AUDIO PAUSED");
        this.audioElement.pause();
        this.audio2Element.pause();
    }
    
    getAmplitude() : number {
        this.analyser.getByteTimeDomainData(this.dataArray); // Fills dataArray with waveform data
    
        // Calculate average amplitude (e.g., RMS)
        let sumSquares = 0;
        for (let i = 0; i < this.bufferLength; i++) {
            const value = (this.dataArray[i] - 128) / 128; // Normalize to -1 to 1 range
            sumSquares += value * value;
        }
        const rms = Math.sqrt(sumSquares / this.bufferLength);
        return rms;
    }

    getLowPassAmp() : number{
        this.analyserLowPass.getByteTimeDomainData(this.dataArray); // Fills dataArray with waveform data
    
        // Calculate average amplitude (e.g., RMS)
        let sumSquares = 0;
        for (let i = 0; i < this.bufferLength; i++) {
            const value = (this.dataArray[i] - 128) / 128; // Normalize to -1 to 1 range
            sumSquares += value * value;
        }
        const rms = Math.sqrt(sumSquares / this.bufferLength);
        return rms;
    }
};