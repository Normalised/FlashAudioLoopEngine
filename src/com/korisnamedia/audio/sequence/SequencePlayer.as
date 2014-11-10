/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/29/2014
 * Time: 10:24 AM
 */
package com.korisnamedia.audio.sequence {
import com.korisnamedia.audio.AudioLoop;
import com.korisnamedia.audio.MixEngine;

import flash.events.TimerEvent;

import flash.utils.Timer;

public class SequencePlayer {

    private var _sequence:Sequence;

    private var lastTime:Number = 0;
    private var _mixEngine:MixEngine;
    private var updateTimer:Timer;

    public function SequencePlayer(mixEngine:MixEngine) {
        _mixEngine = mixEngine;
        updateTimer = new Timer(40);
        updateTimer.addEventListener(TimerEvent.TIMER, update);
    }

    public function play():void {
        resetTrackStates();
        updateTimer.start();
    }

    private function resetTrackStates():void {
        for (var i:int = 0; i < _sequence.tracks.length; i++) {
            var startEvent:SequenceEvent = _sequence.tracks[i].getEventAt(0);
            var c:AudioLoop = _mixEngine.channels[i];
            if(startEvent.data.state) {
                c.start(0,true);
            } else {
                c.active = false;
                c.stop();
            }

        }
    }

    public function stop():void {
        updateTimer.stop();
    }

    public function update(te:TimerEvent):void {

        var time:Number = _mixEngine.sequencePosition;
        time = Math.ceil(time);
        if(time != lastTime) {
            for (var i:int = 0; i < _sequence.tracks.length; i++) {
                var track:SequenceTrack = _sequence.tracks[i];
                var event:SequenceEvent = track.getEventAt(time);
                if(event) {
                    trace("Event at " + time + " on " + i);
                    _mixEngine.toggleTrack(i);
                }
            }
        }
        lastTime = time;
    }

    public function get sequence():Sequence {
        return _sequence;
    }

    public function set sequence(value:Sequence):void {
        _sequence = value;
    }
}
}
