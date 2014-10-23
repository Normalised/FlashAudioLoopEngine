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
    public var sampleData:Vector.<Number>;

    // Default 2 seconds recording
    public var recordTimeInSamples:int = 88200;
    private var recording:Boolean;
    private var _scope:Oscilloscope;

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

    public function set scope(s:Oscilloscope):void {
        _scope = s;
    }

    public function record():void {
        trace("Record");
        sampleData = new Vector.<Number>();
        recording = true;
    }

    private function micSampleDataHandler(event:SampleDataEvent):void {
        var pos:int = event.data.position;
        if(recording) {
            while (event.data.bytesAvailable) {
                sampleData.push(event.data.readFloat());
            }
            if (sampleData.length >= recordTimeInSamples) {
                stopRecording();
            }
        }
        if(_scope) {
            event.data.position = pos;
            _scope.render(event.data);
        }
    }

    private function stopRecording():void {
        recording = false;
        trace("Record time complete. Samples : " + sampleData.length);
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
}
}
