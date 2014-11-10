/**
 * Created by Martin Wood-Mitrovski
 * Date: 05/11/2014
 * Time: 00:58
 */
package com.korisnamedia.audio {
import flash.events.Event;

public class BooleanEvent extends Event {
    public var value:Boolean;
    public function BooleanEvent(type:String, val:Boolean) {

        super(type);
        this.value = val;
    }
}
}
