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
import flash.utils.ByteArray;

import org.as3commons.logging.api.ILogger;
import org.as3commons.logging.api.getLogger;

public class MicRecorder extends EventDispatcher {
    private var mic:Microphone;
    private var DELAY_LENGTH:int = 4000;
    private var _recording:Boolean;
    private var _audioBuffer:AudioLoop;
    public var writePos:int = 0;
    private var audioBufferState:Boolean;
    private var audioBufferSize:int;
    private var _waitForSync:Boolean;
    private var syncTime:int;
    private var l:Vector.<Number>;
    private var r:Vector.<Number>;
    private var tempo:Tempo;
    private var writePosToStopAt:int;

    private var _hasRecording:Boolean = false;

    private static const log:ILogger = getLogger(MicRecorder);
    private var fullRecordingLength:Number;
    public var isAvailable:Boolean;
    private var recordOffset:int = 20000;

    public static const BARS_TO_RECORD:int = 4;
    private var recordLengthInBars:int = 4;
    private var mixEngine:MixEngine;

    public function MicRecorder(tempo:Tempo, mixEngine:MixEngine) {

        this.mixEngine = mixEngine;
        this.tempo = tempo;
//        isAvailable = Microphone.isSupported;
        isAvailable = true;
        mic = Microphone.getMicrophone();
        log.info("Got Mic : " + mic);
        mic.addEventListener(StatusEvent.STATUS, this.onMicStatus);
        _recording = false;

        mic.setSilenceLevel(0, DELAY_LENGTH);
        mic.gain = 50;
        mic.rate = 44;

        _audioBuffer = new AudioLoop(tempo);
        fullRecordingLength = BARS_TO_RECORD * tempo.samplesPerBar;
        log.debug("Full recording length : " + fullRecordingLength);
        clearBuffer();
    }

    private function clearBuffer():void {
        audioBuffer.empty(fullRecordingLength + recordOffset);
        audioBuffer.setLoopStart(recordOffset);
        audioBufferSize = audioBuffer.numSamples;
        writePosToStopAt = audioBufferSize;
        l = audioBuffer.leftChannel;
        r = audioBuffer.rightChannel;
    }

    public function enable():void {
        log.debug("Enable mic " + mic);
        mic.addEventListener(SampleDataEvent.SAMPLE_DATA, micSampleDataHandler);
    }

    public function record(bufferPosition:int):void {
        log.debug("Record. Buffer pos : " + bufferPosition);
        syncTime = bufferPosition;
        writePos = 0;
        audioBufferState = audioBuffer.active;
        audioBuffer.active = false;
        writePosToStopAt = audioBufferSize;
        recordLengthInBars = BARS_TO_RECORD;
        log.debug("Write Pos to stop at : " + writePosToStopAt);
        _waitForSync = true;
        _recording = true;
    }

    public function get recordingPosition():Number {
        log.debug("Write Pos " + writePos);
        if(writePos > 0) {
            var p:Number = writePos / fullRecordingLength;
            return p;
        } else {
            return 0;
        }
    }

    private function micSampleDataHandler(event:SampleDataEvent):void {
        var data:ByteArray = event.data;
//        log.debug("Mic Sample Data " + data.bytesAvailable + ". R: " + _recording);
        if(_recording) {
            var numSamples:int = data.bytesAvailable >> 2;
            var i:int = 0;
            var p:int = 0;
            if(_waitForSync) {
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
                    _waitForSync = false;
                    if(data.bytesAvailable > 0) {
                        log.debug("ERROR : Not all data consumed");
                    }
                } else {
                    // pull all the data
                    while(data.bytesAvailable) {
                        data.readFloat();
                    }
                    log.debug("Sync Time " + syncTime);
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
                _hasRecording = true;
                log.debug("Write pos past buffer size. Recorded " + recordLengthInBars + " bars.");
                _audioBuffer.playNowWithThisLoopLength(recordLengthInBars * tempo.samplesPerBar, mixEngine.globalPositionInSamples);
                stopRecording();
            }
            writePos %= audioBufferSize;
        }
    }

    private function stopRecording():void {
        _recording = false;
        log.debug("Record time complete.");
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function onMicStatus(event:StatusEvent):void {
        log.info("Mic Status : " + event.code);

        if (event.code == "Microphone.Unmuted") {
            log.debug("Microphone access was allowed.");
            isAvailable = true;
        }
        else if (event.code == "Microphone.Muted") {
            log.debug("Microphone access was denied.");
        } else {

        }
    }

    public function stop():void {
        log.debug("Mic Recorder stop. Recording : " + _recording);
        if(_recording) {
            log.debug("Stop Recording. Wait for sync " + _waitForSync);
            if(_waitForSync) {
                _waitForSync = false;
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
                    // TODO : Change to 8 for live
                    barBoundary = 4;
                }
                writePosToStopAt = barBoundary * tempo.samplesPerBar;
                recordLengthInBars = barBoundary;
                log.debug("Bar boundary : " + barBoundary + ". Samples to stop at : " + writePosToStopAt);
            }
        }
    }

    public function get audioBuffer():AudioLoop {
        return _audioBuffer;
    }

    public function get hasRecording():Boolean {
        return _hasRecording;
    }

    public function get waitForSync():Boolean {
        return _waitForSync;
    }

    public function set waitForSync(value:Boolean):void {
        _waitForSync = value;
    }

    public function get recording():Boolean {
        return _recording;
    }

    public function set recording(value:Boolean):void {
        _recording = value;
    }

    public function clearRecording():void {
        log.info("Clear Recording");
        _recording = false;
        _hasRecording = false;
    }
}
}
