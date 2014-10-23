/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/21/2014
 * Time: 7:44 PM
 */
package com.korisnamedia.audio.sequence {
public class SequenceEvent {

    public var time:Number = 0;
    public var data:Object;

    public function SequenceEvent(t:Number, d:Object) {
        time = t;
        data = d;
    }
}
}
