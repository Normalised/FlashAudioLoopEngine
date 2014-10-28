/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/17/2014
 * Time: 9:05 AM
 */
package com.korisnamedia.audio {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.utils.getTimer;

public class MixEngine extends EventDispatcher {

    public var channels:Array;
    public var enabled:Vector.<int>;

    private var left:Vector.<Number>;
    private var right:Vector.<Number>;
    private var bufferSize:int = 4096;
    public const out:Sound = new Sound();
    private var zeros:Array;
    private var numChannels:uint;
    private var soundChannel:SoundChannel;

    // Latency in milliseconds
    public var latency:Number = 250;

    public var lastUpdateTime:int;

    public var playing:Boolean = false;
    private var position:int;

    private var _tempo:Tempo;

    public function MixEngine() {
        super(this);
        channels = [];
        enabled = new Vector.<int>();
        left = new Vector.<Number>(4096,true);
        right = new Vector.<Number>(4096,true);
        zeros = [];
        for (var i:int = 0; i < bufferSize; i++) {
            zeros[i] = 0;
        }
    }

    public function addSample(s:AudioLoop) {
        channels.push(s);
        enabled.push(false);
        numChannels = channels.length;
    }

    public function start():void {
        if(playing) return;
        trace("Start mix engine with " + numChannels + " channels");
        playing = true;
        lastUpdateTime = getTimer();
        position = 0;
        out.addEventListener(SampleDataEvent.SAMPLE_DATA, fillBuffer);
        soundChannel = out.play();
    }

    public function stop():void {
        playing = false;
        soundChannel.stop();
        position = 0;
        for (var i:int = 0; i < channels.length; i++) {
            var loop:AudioLoop = channels[i];
            loop.jumpToStart();
        }
    }

    public function fillBuffer(event:SampleDataEvent):void {

        if(soundChannel) {
            latency = (event.position / 44.1) - soundChannel.position;
        }
        var t:int = getTimer();
        // Clear buffer
        for (var a:int = 0; a < bufferSize; a++) {
            left[a] = 0;
            right[a] = 0;
        }
        // Mix samples into buffer
        for (var i:int = 0; i < numChannels; i++) {
            if(enabled[i]) {
                channels[i].write(left, right, bufferSize);
            }
        }
        var t1:int = getTimer();
        // Write mixed audio into sample data byte array
        for (var j:int = 0; j < bufferSize; j++) {
            event.data.writeFloat(left[j]);
            event.data.writeFloat(right[j]);
        }
        position += bufferSize;

        lastUpdateTime = getTimer();
//        trace("Latency " + latency + ". Mix Time " + (lastUpdateTime - t));
        trace("T1 " + (t1 - t));
    }

    /**
     * Latency adjusted bar count
     * @return
     */
    public function getLatencyAdjustedSequencePosition():Number {
        return (position - latencyInSamples) / tempo.samplesPerBar;
    }

    /**
     * Current bar
     * @return
     */
    public function getSequencePosition():Number {
        return position / tempo.samplesPerBar;
    }

    public function toggleTrack(trackID:int):Boolean {
        channelSwitch(trackID,!enabled[trackID]);
        return enabled[trackID];
    }

    public function channelSwitch(index:int, on:Boolean):void {
        enabled[index] = (on && channels[index].ready) ? 1 : 0;
        if(enabled[index]) {
            channels[index].syncTo(position, true);
        }
    }

    public function get latencyInSamples():int {
        return latency * 44.1;
    }

    public function get tempo():Tempo {
        return _tempo;
    }

    public function set tempo(value:Tempo):void {
        _tempo = value;
    }
}
}
