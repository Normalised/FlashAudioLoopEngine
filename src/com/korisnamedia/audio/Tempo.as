/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/22/2014
 * Time: 3:08 PM
 */
package com.korisnamedia.audio {
public class Tempo {

    private var _bpm:Number;
    public var beatsPerBar:Number = 4;
    public var samplesPerBeat:Number;
    public var samplesPerBar:Number;
    public var timePerBeat:Number;
    public var timePerBar:Number;
    public var samplesPerBarInverse:Number;

    public function Tempo(bpm:Number) {
        _bpm = bpm;
        updateValues();
    }

    public function get bpm():Number {
        return _bpm;
    }

    public function set bpm(value:Number):void {
        _bpm = value;
        updateValues();
    }

    private function updateValues():void {
        timePerBeat = (60 / _bpm) * 1000;
        timePerBar = timePerBeat * beatsPerBar;
        samplesPerBeat = timePerBeat * 44.1;
        samplesPerBar = samplesPerBeat * beatsPerBar;
        samplesPerBarInverse = 1 / samplesPerBar;
        trace("Tempo. TPBt : " + timePerBeat + ". SPBt : " + samplesPerBeat);
    }

    public function secondsToBars(seconds:Number):Number {
        return (seconds * 1000) / timePerBar;
    }
}
}
