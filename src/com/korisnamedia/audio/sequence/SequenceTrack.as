/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/21/2014
 * Time: 7:42 PM
 */
package com.korisnamedia.audio.sequence {
import flash.events.Event;
import flash.events.EventDispatcher;

import org.as3collections.IIterator;
import org.as3collections.IListMapIterator;

import org.as3collections.maps.SortedArrayListMap;

public class SequenceTrack extends EventDispatcher {

    public var events:SortedArrayListMap;

    public function SequenceTrack() {
        super(this);
//        events = new Vector.<SequenceEvent>();
        events = new SortedArrayListMap();
        events.comparator = new TimeComparator();
    }

    public function addEvent(event:SequenceEvent):void {
        // An off event can have a time before the previous on event
        // if thats the case then remove the on event

        events.put(event.time, event);
        dispatchEvent(new Event(Event.CHANGE));
    }

    public function clear():void {
        events.clear();
        dispatchEvent(new Event(Event.CHANGE));
    }

    public function getEventAt(time:Number):SequenceEvent {
        if(events.containsKey(time)) {
            return events.getValue(time);
        } else {
            return null;
        }

    }

    public function serialize():Array {
        var sq:Array = [];
        var events:IListMapIterator = events.listMapIterator();
        while (events.hasNext()) {
            var event:SequenceEvent = events.next();
            var t:Number = event.time;
            sq.push({time: t, state: event.data.state});
        }
        return sq;
    }

    public function deserialize(data:Array):void {
        trace("Deserialize : " + data);
        events.clear();
        for (var i:int = 0; i < data.length; i++) {
            var object:Object = data[i];
            var se:SequenceEvent = new SequenceEvent(object.time,{state:object.state});
            events.put(object.time,se);
        }
        dispatchEvent(new Event(Event.CHANGE));
    }
}
}
