/**
 * Created by Martin Wood-Mitrovski
 * Date: 05/11/2014
 * Time: 00:26
 */
package com.korisnamedia.audio {
import flash.events.Event;

public class LoadProgressEvent extends Event {
    public static const PROGRESS:String = "LoadProgressEvent";
    public var progress:Number;
    public function LoadProgressEvent(number:Number) {
        super(PROGRESS);
        this.progress = number;
    }

    override public function clone():Event {
        return new LoadProgressEvent(progress);
    }
 }
}
