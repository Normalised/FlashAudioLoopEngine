/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/17/2014
 * Time: 2:18 PM
 */
package com.korisnamedia.audio {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.SampleDataEvent;
import flash.events.StatusEvent;
import flash.media.Microphone;
import flash.utils.describeType;

import org.as3commons.logging.api.ILogger;
import org.as3commons.logging.api.getLogger;

public class MicRecorder extends EventDispatcher {
    private var mic:Microphone;
    private var DELAY_LENGTH:int = 4000;
    public var recording:Boolean;
    private var _audioBuffer:AudioLoop;
    public var writePos:int = 0;
    private var audioBufferState:Boolean;
    private var audioBufferSize:int;
    private var waitForSync:Boolean;
    private var syncTime:int;
    private var l:Vector.<Number>;
    private var r:Vector.<Number>;
    private var tempo:Tempo;
    private var writePosToStopAt:int;

    private static const log:ILogger = getLogger(MicRecorder);

    public function MicRecorder(tempo:Tempo) {

        this.tempo = tempo;
        mic = Microphone.getMicrophone();
        mic.addEventListener(StatusEvent.STATUS, this.onMicStatus);
        recording = false;

        mic.setSilenceLevel(0, DELAY_LENGTH);
        mic.gain = 50;
        mic.rate = 44;
    }

    public function enable():void {
        mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
    }

    public function record(bufferPosition:int):void {
        log.debug("Record. Buffer pos : " + bufferPosition);
        syncTime = bufferPosition;
        writePos = 0;
        audioBufferState = audioBuffer.active;
        audioBuffer.active = false;
        writePosToStopAt = audioBufferSize;
        log.debug("Write Pos to stop at : " + writePosToStopAt);
        waitForSync = true;
        recording = true;
    }

    private function micSampleDataHandler(event:SampleDataEvent):void {
        var data = event.data;
        if(recording) {
            var numSamples:int = data.bytesAvailable / 4;
            var i:int = 0;
            var p:int = 0;
            if(waitForSync) {
                if(syncTime + numSamples > 0) {
                    log.debug("Crossing sync boundary : " + syncTime + " : " + numSamples);
                    // pull the sync data
                    var st:int = Math.abs(syncTime);
                    for(i=0;i<st;i++) {
                        data.readFloat();
                    }
                    // write the rest
                    for(;i<numSamples;i++) {
                        r[p] = l[p] = data.readFloat();
                        p++;
                    }
                    writePos = p;
                    waitForSync = false;
                    if(data.bytesAvailable > 0) {
                        log.debug("ERROR : Not all data consumed");
                    }
                } else {
                    // pull all the data
                    while(data.bytesAvailable) {
                        data.readFloat();
                    }
                }
                syncTime += numSamples;
                return;
            }

            for(i;i<numSamples;i++) {
                p = (writePos + i) % audioBufferSize;
                r[p] = l[p] = data.readFloat();
            }
            writePos += numSamples;

            if (writePos >= writePosToStopAt) {
                log.debug("Write pos past buffer size");
                _audioBuffer.loopLength = writePosToStopAt;
                _audioBuffer.active = true;
                stopRecording();
            }
            writePos %= audioBufferSize;
        }
    }

    private function stopRecording():void {
        recording = false;
        log.debug("Record time complete.");
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function onMicStatus(event:StatusEvent):void {
        if (event.code == "Microphone.Unmuted") {
            log.debug("Microphone access was allowed.");
        }
        else if (event.code == "Microphone.Muted") {
            log.debug("Microphone access was denied.");
        }
    }

    public function stop():void {
        log.debug("Mic Recorder stop. Recording : " + recording);
        if(recording) {
            log.debug("Stop Recording. Wait for sync " + waitForSync);
            if(waitForSync) {
                waitForSync = false;
                stopRecording();
            } else {
                log.debug("Stop at next boundary");
                // stop recording at next boundary
                var beatPos:Number = writePos / tempo.samplesPerBeat;
                log.debug("Beat Pos : " + beatPos);
                var barBoundary:int = 1;
                // Suitable bar boundaries 1, 2, 4 and 8
                // i.e. 4, 8, 16 and 32 beats
                if(beatPos < 4) {
                    barBoundary = 1;
                } else if(beatPos < 8) {
                    barBoundary = 2;
                } else if(beatPos < 16) {
                    barBoundary = 4;
                } else {
                    barBoundary = 8;
                }
                writePosToStopAt = barBoundary * tempo.samplesPerBar;
                log.debug("Bar boundary : " + barBoundary + ". Samples to stop at : " + writePosToStopAt);
            }
        }
    }

    public function set audioBuffer(audioBuffer:AudioLoop):void {
        _audioBuffer = audioBuffer;
        audioBufferSize = audioBuffer.numSamples;
        writePosToStopAt = audioBufferSize;
        l = audioBuffer.leftChannel;
        r = audioBuffer.rightChannel;

    }

    public function get audioBuffer():AudioLoop {
        return _audioBuffer;
    }
}
}
