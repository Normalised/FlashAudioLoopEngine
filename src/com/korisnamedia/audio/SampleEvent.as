/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/21/2014
 * Time: 8:19 PM
 */
package com.korisnamedia.audio {
import com.korisnamedia.audio.AudioLoop;

import flash.events.Event;

public class SampleEvent extends Event {
    public static const READY:String = "sampleReady";
    public var sample:AudioLoop;
    public function SampleEvent(type:String, s:AudioLoop) {
        super(type);
        this.sample = s;
    }
}
}
