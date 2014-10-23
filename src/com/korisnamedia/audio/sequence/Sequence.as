/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/21/2014
 * Time: 7:42 PM
 */
package com.korisnamedia.audio.sequence {
public class Sequence {

    public var tracks:Vector.<SequenceTrack>;
    private var clearTrack:Function;

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
            if(tracks[i].events.length > 0) {
                return false;
            }
        }
        return true;
    }

    public function clear():void {
        tracks.forEach(clearTrack);
    }
}
}
