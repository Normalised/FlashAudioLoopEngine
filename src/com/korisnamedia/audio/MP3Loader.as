/**
 * Created by Martin Wood-Mitrovski
 * Date: 11/20/13
 * Time: 5:09 PM
 */
package com.korisnamedia.audio {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import org.as3commons.logging.api.ILogger;

import org.as3commons.logging.api.getLogger;

public class MP3Loader extends EventDispatcher {

    private var url:String;
    public var id:int;

//    private const ENCODER_OFFSET:Number = 1079.0; // LAME 3.98.2 + flash.media.Sound Delay

    // DESKTOP
//    private const ENCODER_OFFSET:Number = 1634.0;
    // AIR ANDROID

    public const mp3:Sound = new Sound(); // Use for decoding

    public var loaded:Boolean = false;
    public var sample:AudioLoop;
    private var encoderOffset:int;
    private var tempo:Tempo;

    private static const log:ILogger = getLogger(MP3Loader);

    public function MP3Loader(id:int, offset:int, tempo:Tempo) {

        super(this);
        encoderOffset = offset;
        this.id = id;
        this.tempo = tempo;
        sample = new AudioLoop(tempo);
    }

    public function loadMp3(mp3Url:String):void {
        url = mp3Url;
        mp3.addEventListener(Event.COMPLETE, mp3Complete);
        mp3.addEventListener(IOErrorEvent.IO_ERROR, mp3Error);
        mp3.addEventListener(ProgressEvent.PROGRESS, loadProgress);
        mp3.load(new URLRequest(url));
    }

    private function loadProgress(event:ProgressEvent):void {
        dispatchEvent(event.clone());
    }

    private function mp3Complete(event:Event):void {
        log.debug("MP3 Loaded " + url);
        loaded = true;
        log.debug("Extracting all audio. Total mp3 length : " + mp3.length);
        sample.fromMP3(mp3, encoderOffset);

        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function mp3Error(event:IOErrorEvent):void {
        log.error(event);
    }

}
}
