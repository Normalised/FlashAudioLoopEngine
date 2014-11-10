/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/21/2014
 * Time: 7:42 PM
 */
package com.korisnamedia.audio.sequence {
import flash.events.Event;
import flash.events.EventDispatcher;

public class Sequence extends EventDispatcher {

    public var tracks:Vector.<SequenceTrack>;
    private var clearTrack:Function;
    private var _barCount:Number;

    public function Sequence() {

        tracks = new Vector.<SequenceTrack>();
        clearTrack = function(item:SequenceTrack,i:int,v:Vector.<SequenceTrack>):void { item.clear(); }
    }

    public function addTrack(t:SequenceTrack):void {
        tracks.push(t);
    }

    public function removeTrack(t:SequenceTrack):void {
        if(tracks.indexOf(t) != -1) {
            tracks.splice(tracks.indexOf(t), 1);
        }
    }

    public function createTrack():SequenceTrack {
        var st:SequenceTrack = new SequenceTrack();
        tracks.push(st);
        return st;
    }

    public function isEmpty():Boolean {
        for (var i:int = 0; i < tracks.length; i++) {
            if(!tracks[i].events.isEmpty()) {
                return false;
            }
        }
        return true;
    }

    public function clear():void {
        tracks.forEach(clearTrack);
        dispatchEvent(new Event(Event.CHANGE));
    }

    public function serialize():Object {
        var seq:Object = {};
        for (var i:int = 0; i < tracks.length; i++) {
            var track:SequenceTrack = tracks[i];
            seq["track:" + i] = track.serialize();
        }
        return seq;
    }

    public function deserialize(seq:Object):void {
        for (var trackName:String in seq) {
            trace("Track Name : " + trackName + " : " + trackName.substring(6));
            var trackID:int = parseInt(trackName.substring(6));
            trace("Track ID " + trackID);
            if(trackID < tracks.length) {
                tracks[trackID].deserialize(seq[trackName]);
            }
        }
        dispatchEvent(new Event(Event.CHANGE));
    }

    public function set barCount(barCount:Number):void {
        trace("Bar Count : " + barCount);
        _barCount = barCount;
    }

    public function get barCount():Number {
        return _barCount;
    }
}
}
