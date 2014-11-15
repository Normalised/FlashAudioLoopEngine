/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/17/2014
 * Time: 9:05 AM
 */
package com.korisnamedia.audio {
import flash.events.EventDispatcher;
import flash.events.SampleDataEvent;
import flash.events.TimerEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.utils.Timer;
import flash.utils.getTimer;

import org.as3commons.logging.api.ILogger;
import org.as3commons.logging.api.getLogger;

public class MixEngine extends EventDispatcher {

    public var channels:Array;

    private var left:Vector.<Number>;
    private var right:Vector.<Number>;
    private static const bufferSize:int = 4096;
    public const out:Sound = new Sound();
    private var zeros:Array;
    private var numChannels:uint;
    private var soundChannel:SoundChannel;

    // Latency in milliseconds
    public var latency:Number = 250;

    public var lastUpdateTime:int;


    public var position:int;

    private var _tempo:Tempo;
    public static const PLAY_STATE:String = "PlayStateEvent";
    private var inverseSampleRateKHz:Number;
    public var sequencePosition:Number;
    private var updateTimer:Timer;
    public var gain:Number = 1.0;
    public var latencyAdjustSequencePosition:Number;
    private var preRolling:Boolean;

    public var playing:Boolean = false;
    public var mixTime:int = 0;
    public var writeTime:int = 0;

    private static const log:ILogger = getLogger(MixEngine);
    private var stopFlag:Boolean = false;

    public function MixEngine() {
        super(this);

        inverseSampleRateKHz = 1 / 44.1;
        channels = [];
        left = new Vector.<Number>(4096,true);
        right = new Vector.<Number>(4096,true);
        zeros = [];
        for (var i:int = 0; i < bufferSize; i++) {
            zeros[i] = 0;
        }

        updateTimer = new Timer(25);
        updateTimer.addEventListener(TimerEvent.TIMER, updateTime);
        out.addEventListener(SampleDataEvent.SAMPLE_DATA, fillBuffer);
    }

    private function updateTime(event:TimerEvent):void {
        // How many samples since last update
        var dt:Number = (getTimer() - lastUpdateTime) * 44.1;
        sequencePosition = (position + dt) * tempo.samplesPerBarInverse;
        latencyAdjustSequencePosition = (position - latencyInSamples + dt) * tempo.samplesPerBarInverse;
        if(stopFlag) {
            stop();
        }
    }

    public function addSample(s:AudioLoop):int {
        channels.push(s);
        numChannels = channels.length;
        return numChannels - 1;
    }

    // Pre-Roll the engine ready for recording.
    public function preRoll():void {
        log.debug("PreRoll MixEngine");
        // Clear the buffer
        for (var a:int = 0; a < bufferSize; a++) {
            left[a] = 0;
            right[a] = 0;
        }
        preRolling = true;
        sequencePosition = -1;
        latencyAdjustSequencePosition = -1;
        // Start with negative position
        position = -(tempo.samplesPerBar);
        go();
    }

    public function start():void {
        if(playing) return;
        log.debug("Start mix engine with " + numChannels + " channels");
        playing = true;
        lastUpdateTime = getTimer();
        position = 0;
        sequencePosition = 0;
        latencyAdjustSequencePosition = 0;
        go();
    }

    private function go():void {
        stopFlag = false;
        updateTimer.start();
        soundChannel = out.play();

        dispatchEvent(new BooleanEvent(MixEngine.PLAY_STATE, true));
    }

    public function stop():void {
        log.debug("Stop Engine");
        playing = false;

        soundChannel.stop();
        position = 0;
        for (var i:int = 0; i < channels.length; i++) {
            var loop:AudioLoop = channels[i];
            loop.jumpToStart();
        }
        updateTimer.stop();
        dispatchEvent(new BooleanEvent(MixEngine.PLAY_STATE, false));
    }

    public function fillBuffer(event:SampleDataEvent):void {

        if(soundChannel) {
            latency = (event.position * inverseSampleRateKHz) - soundChannel.position;
        }
        var bufferIndex:int = 0;
        var bufferClearIndex:int = 0;
        var channelIndex:int = 0;
        var i:int = 0;
        if(preRolling) {
            if(position + bufferSize > 0) {
                log.debug("Buffer fill crosses zero");
                // Move buffer index to zero position point
                var bufferOffset:int = Math.abs(position);
                // Mix samples into buffer
                for (; channelIndex < numChannels; channelIndex++) {

                    var c:AudioLoop = channels[channelIndex];
                    if(c.active) {
                        c.writePartial(left, right, bufferOffset, bufferSize - bufferOffset);
                        c.start(position + bufferSize, false);
                    }
                }
                // Write mixed audio into sample data byte array
                for (; bufferIndex < bufferSize; bufferIndex++) {
                    event.data.writeFloat(left[bufferIndex] * gain);
                    event.data.writeFloat(right[bufferIndex] * gain);
                }
                position += bufferSize;
                lastUpdateTime = getTimer();
                preRolling = false;
                playing = true;
                log.debug("Switch to playing. Position : " + position);
                return;
            } else {
                // Write zeroes to the buffer until position hits zero
                for (bufferIndex = 0; bufferIndex < bufferSize; bufferIndex++) {
                    event.data.writeFloat(0);
                    event.data.writeFloat(0);
                }
                position += bufferSize;
                lastUpdateTime = getTimer();
                return;
            }
        }
        var t:int = getTimer();
        // Clear buffer
        for (; bufferClearIndex < bufferSize; bufferClearIndex++) {
            left[bufferClearIndex] = 0;
            right[bufferClearIndex] = 0;
        }
        // Mix samples into buffer
        var c:AudioLoop;
        var ac:int = 0;
        var lastActive:AudioLoop;
        for (; channelIndex < numChannels; channelIndex++) {
            c = channels[channelIndex];
            if(c.active) {
                ac++;
                c.write(left, right, bufferSize);
                lastActive = c;
            }
        }
        var t1:int = getTimer();
        // Write mixed audio into sample data byte array
        for (; bufferIndex < bufferSize; bufferIndex++) {
            event.data.writeFloat(left[bufferIndex] * gain);
            event.data.writeFloat(right[bufferIndex] * gain);
        }
        position += bufferSize;
        lastUpdateTime = getTimer();

        mixTime = t1 - t;
        writeTime = lastUpdateTime - t1;
//        trace("Latency " + latency + ". Mix Time " + (lastUpdateTime - t));
//        trace("T1 " + (t1 - t));
        if(ac == 0) {
            // No active channels
        } else if(ac == 1 && lastActive.ending) {
            // 1 active channel thats ending
            stopFlag = true;
        }
    }

    public function toggleTrack(index:int):Boolean {
        var s:AudioLoop = channels[index];
        if(!s.ready) {
            log.debug("Channel " + index + " not ready");
            return false;
        }

        if(activeTrackCount == 1 && s.active) {
            log.debug("Turning off last track");
        }
        return s.toggle(position);
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

    public function get activeTrackCount():int {
        var tc:int = 0;
        for (var i:int = 0; i < channels.length; i++) {
            var a:AudioLoop = channels[i];
            tc += a.active ? 1 : 0;
        }
        return tc;
    }
}
}
