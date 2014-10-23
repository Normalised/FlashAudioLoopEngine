/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/21/2014
 * Time: 7:42 PM
 */
package com.korisnamedia.audio.sequence {
import flash.events.Event;
import flash.events.EventDispatcher;

public class SequenceTrack extends EventDispatcher {

    public var events:Vector.<SequenceEvent>;

    private var lastEvent:SequenceEvent;
    public function SequenceTrack() {
        super(this);
        events = new Vector.<SequenceEvent>();
    }

    public function addEvent(event:SequenceEvent):void {
        // An off event can have a time before the previous on event
        // if thats the case then remove the on event
        var lastEvent:SequenceEvent = null;
        if(events.length) {
            lastEvent = events[events.length - 1];
        }
        if(lastEvent && lastEvent.data.state && event.time < lastEvent.time) {
            trace("Replace end state " + event.data.state);
            events.pop();
        } else {
            // If the last event state is the same as this one, ignore it
            if(events.length && (events[events.length - 1].data.state == event.data.state)) {
                trace("Ignore state " + event.data.state + " : " + events[events.length - 1].data.state);
            } else {
                if(lastEvent && (event.time == lastEvent.time)) {
                    trace("Time is the same, replacing state");
                    lastEvent.data.state = event.data.state;
                    if(events.length > 1) {
                        if(events[events.length -2].data.state == lastEvent.data.state) {
                            events.pop();
                        }
                    }
                } else {
                    events.push(event);
                }
            }
        }

        dispatchEvent(new Event(Event.CHANGE));
    }

    public function clear():void {
        events = new Vector.<SequenceEvent>();
        dispatchEvent(new Event(Event.CHANGE));
    }
}
}
