/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/18/2014
 * Time: 10:45 AM
 */
package com.korisnamedia.audio {

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.ProgressEvent;
import flash.system.Capabilities;

import org.as3commons.logging.api.ILogger;

import org.as3commons.logging.api.getLogger;

public class MP3SampleLoader extends EventDispatcher {
    private var offsets:Object;
    private var encoderOffset:int;
    private var currentLoader:MP3Loader;
    private var channelID:int;
    private var mp3sToLoad:Array;
    private var tempo:Tempo;
    private var mp3Count:uint;
    private var loadPercentPerChannel:Number;

    private static const log:ILogger = getLogger(MP3SampleLoader);
    private var mp3Dir:String;
    public function MP3SampleLoader(tempo:Tempo) {
//        offsets = {"android":1050,"windows":1634,"ios":1050};

        channelID = 0;
        this.tempo = tempo;
    }

    public function loadMP3s(dir:String, mp3s:Array):void {
        mp3Dir = dir;
        mp3sToLoad = mp3s;
        mp3Count = mp3sToLoad.length;
        loadPercentPerChannel = 100 / mp3Count;
        if(mp3sToLoad.length) {
            loadMP3(mp3sToLoad.shift());
        }
    }

    private function loadMP3(mp3:String):void {
        currentLoader = new MP3Loader(channelID++, encoderOffset, tempo);
        currentLoader.addEventListener(Event.COMPLETE, mp3Loaded);
        currentLoader.addEventListener(ProgressEvent.PROGRESS, loadProgress);
        currentLoader.loadMp3(mp3Dir + "/" + mp3);
    }

    private function loadProgress(event:ProgressEvent):void {

        var base:Number = channelID * loadPercentPerChannel;
        var pc:Number = (event.bytesLoaded * loadPercentPerChannel) / event.bytesTotal;
        dispatchEvent(new LoadProgressEvent(base + pc));
    }

    private function mp3Loaded(event:Event):void {
        log.debug("Channel ready " + currentLoader);
        dispatchEvent(new SampleEvent(SampleEvent.READY, currentLoader.sample));
        if(mp3sToLoad.length) {
            loadMP3(mp3sToLoad.shift());
        } else {
            dispatchEvent(new Event(Event.COMPLETE));
        }
    }
}
}
