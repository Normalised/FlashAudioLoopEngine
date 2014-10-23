/**
 * Created by Martin Wood-Mitrovski
 * Date: 11/20/13
 * Time: 5:09 PM
 */
package com.korisnamedia.audio {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.net.URLRequest;
import flash.utils.ByteArray;
import flash.utils.getTimer;

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

    public function MP3Loader(id:int, offset:int, tempo:Tempo) {

        super(this);
        this.id = id;
        encoderOffset = offset;
        sample = new AudioLoop();
        this.tempo = tempo;
    }

    public function loadMp3(mp3Url:String):void {
        url = mp3Url;
        mp3.addEventListener(Event.COMPLETE, mp3Complete);
        mp3.addEventListener(IOErrorEvent.IO_ERROR, mp3Error);
        mp3.load(new URLRequest(url));
    }

    private function mp3Complete(event:Event):void {
        trace("MP3 Loaded " + url);
        loaded = true;
        trace("Extracting all audio. Total mp3 length : " + mp3.length);
        sample.fromMP3(mp3, encoderOffset, tempo);

        dispatchEvent(new Event(Event.COMPLETE));
    }

    private function mp3Error(event:IOErrorEvent):void {
        trace(event);
    }

}
}
