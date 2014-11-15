/**
 * Created by Martin Wood-Mitrovski
 * Date: 13/11/2014
 * Time: 15:27
 */
package com.korisnamedia.audio {
import flash.events.Event;

public class AudioLoopEvent extends Event {
    public static const STOPPED:String = "audioLoopStopped";
    public var audioLoop:AudioLoop;

    public function AudioLoopEvent(type:String, al:AudioLoop) {
        super(type);
        audioLoop = al;
    }
}
}
