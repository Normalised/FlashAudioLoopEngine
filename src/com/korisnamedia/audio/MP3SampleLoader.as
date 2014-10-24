/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/18/2014
 * Time: 10:45 AM
 */
package com.korisnamedia.audio {

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.system.Capabilities;

public class MP3SampleLoader extends EventDispatcher {
    private var offsets:Object;
    private var encoderOffset:int;
    private var currentLoader:MP3Loader;
    private var channelID:int;
    private var mp3sToLoad:Array;
    private var tempo:Tempo;

    public function MP3SampleLoader(tempo:Tempo) {
        offsets = {"android":1050,"windows":1634,"ios":1050};

        encoderOffset = offsets.windows;
        var platform = Capabilities.manufacturer;
        trace("Manufacturer " + platform);
        for(var s:String in offsets) {
            if(platform.toLowerCase().indexOf(s) > -1) {
                encoderOffset = offsets[s];
                break;
            }
        }
        trace("Encoder offset " + encoderOffset);

        channelID = 0;
        this.tempo = tempo;
    }

    public function loadMP3s(mp3s:Array):void {
        mp3sToLoad = mp3s;
        if(mp3sToLoad.length) {
            loadMP3(mp3sToLoad.shift());
        }
    }

    private function loadMP3(mp3:String):void {
        currentLoader = new MP3Loader(channelID++, encoderOffset, tempo);
        currentLoader.addEventListener(Event.COMPLETE, mp3Loaded);
        currentLoader.loadMp3(mp3);
    }

    private function mp3Loaded(event:Event):void {
        trace("Channel ready " + currentLoader);
        dispatchEvent(new SampleEvent(SampleEvent.READY, currentLoader.sample));
        if(mp3sToLoad.length) {
            loadMP3(mp3sToLoad.shift());
        } else {
            dispatchEvent(new Event(Event.COMPLETE));
        }
    }
}
}
