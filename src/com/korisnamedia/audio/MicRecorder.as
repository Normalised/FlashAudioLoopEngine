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

public class MicRecorder extends EventDispatcher {
    private var mic:Microphone;
    private var DELAY_LENGTH:int = 4000;
    public var recording:Boolean;
    private var _audioBuffer:AudioLoop;
    public var writePos:int = 0;
    private var audioBufferState:Boolean;
    private var audioBufferSize:int;
    private var writeOffset:int = 0;
    private var waitForSync:Boolean;
    private var syncTime:int;
    private var l:Vector.<Number>;
    private var r:Vector.<Number>;
    private var latency:int = 4000 * 5;

    public function MicRecorder() {
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
        trace("Record " + bufferPosition);
        syncTime = bufferPosition - latency;
        writePos = 0;
        audioBufferState = audioBuffer.active;
        audioBuffer.active = false;
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
                    trace("Crossing sync boundary : " + syncTime + " : " + numSamples);
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
                        trace("ERROR : Not all data consumed");
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

            if (writePos >= audioBufferSize) {
                trace("Write pos past buffer size");
                _audioBuffer.active = true;
                stopRecording();
            }
            writePos %= audioBufferSize;
        }
    }

    private function stopRecording():void {
        recording = false;
        trace("Record time complete. Samples");
//        mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function onMicStatus(event:StatusEvent):void {
        if (event.code == "Microphone.Unmuted") {
            trace("Microphone access was allowed.");
        }
        else if (event.code == "Microphone.Muted") {
            trace("Microphone access was denied.");
        }
    }

    public function stop():void {
        trace("Stop Recording");
        stopRecording();
    }

    public function set audioBuffer(audioBuffer:AudioLoop):void {
        _audioBuffer = audioBuffer;
        audioBufferSize = audioBuffer.numSamples;
        l = audioBuffer.leftChannel;
        r = audioBuffer.rightChannel;

    }

    public function get audioBuffer():AudioLoop {
        return _audioBuffer;
    }
}
}
