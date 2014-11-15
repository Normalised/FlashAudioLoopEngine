/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/17/2014
 * Time: 8:30 AM
 */
package com.korisnamedia.audio {
import com.korisnamedia.audio.filters.IFilter;

import flash.events.EventDispatcher;

import flash.media.Sound;
import flash.profiler.showRedrawRegions;
import flash.utils.ByteArray;
import flash.utils.getTimer;

import org.as3commons.logging.api.ILogger;
import org.as3commons.logging.api.getLogger;

public class AudioLoop extends EventDispatcher {

    private var _loopEnd:int = 0;
    private var _loopStart:int = 0;
    private var _loopLength:int = 0;

    // Where in the loop to read from. Between 0 and _loopLength
    public var readPosition:int = 0;

    public var leftChannel:Vector.<Number>;
    public var rightChannel:Vector.<Number>;

    public var numSamples:int = 0;

    private var minimumLoopLength:int = 64;

    private var _loopLengthInMilliseconds:Number = 1;

    private var _bars:int = 1;

    // 0 : No state change due
    // 1 : Waiting for quantized sync to start playback
    // 2 : Waiting for quantized sync to stop playback
    public var pendingStateChange:int = 0;
    public static const STARTING:int = 1;
    public static const STOPPING:int = 2;

    private var waitForQuantizedSync:Boolean = false;
    private var _fillToSyncBoundary:Boolean = false;
    private var samplesPerBar:Number;

    public var ready:Boolean = false;

    public var filters:Vector.<IFilter>;
    private var tempo:Tempo;
    public var active:Boolean = false;

    public var loopLengthInMsInverse:Number;
    private var inverseSampleRateKHz:Number;

    public var gain:Number = 1.0;
    private static const log:ILogger = getLogger(AudioLoop);
    public var ending:Boolean = false;

    public function AudioLoop(tempo:Tempo) {
        this.tempo = tempo;
        filters = new Vector.<IFilter>();
        inverseSampleRateKHz = 1 / 44.1;
    }

    /**
     * Create an empty loop
     * @param size  number of bars
     */
    public function empty(numSamples:int):void {
        this.numSamples = numSamples;
        extractSamples();
    }

    public function copy(left:Vector.<Number>, right:Vector.<Number> = null, offset:int = 0):void {
        log.debug("Copy audio : " + left.length);
        if(right && right.length > left.length) {
            numSamples = left.length - offset;
        } else {
            numSamples = left.length - offset;
        }
        leftChannel = new Vector.<Number>(numSamples,true);
        rightChannel = new Vector.<Number>(numSamples,true);
        for (var i:int = 0; i < numSamples; i++) {
            leftChannel[i] = left[i + offset];
            if(right) {
                rightChannel[i] = right[i + offset];
            } else {
                rightChannel[i] = left[i + offset];
            }
        }
        loopEnd = numSamples;
        updateLoopLength();
        ready = true;
    }

    public function replace(audio:Vector.<Number>):void {
        var writePos:int = _loopStart;
        for (var i:int = 0; i < audio.length; i++) {
            writePos = _loopStart + i;
            rightChannel[writePos] = leftChannel[writePos] = audio[i];
        }
        _loopEnd = _loopStart + audio.length;
        var numBeats:Number = Math.floor(audio.length / tempo.samplesPerBeat);
        _bars = Math.floor(numBeats / 4);
        log.debug("Replaced audio with " + numBeats + " beats := " + _bars + " bars.");
        updateLoopLength();
    }

    public function fromMP3(mp3:Sound, offset:int):void {
        var t:int = getTimer();
        var samplesTotal:int = Math.floor(mp3.length * 44.1);
        log.debug("Num samples : " + samplesTotal);
        var buffer:ByteArray = new ByteArray();
        mp3.extract(buffer, samplesTotal, offset);
        var t2:int = getTimer();
        log.debug("Extract took " + (t2 - t));

        log.debug("Audio buffer samples available : " + (buffer.bytesAvailable / 8));

        buffer.position = 0;
        numSamples = buffer.bytesAvailable / 8;
        extractSamples(buffer);
    }

    private function extractSamples(buffer:ByteArray = null):void {
        leftChannel = new Vector.<Number>(numSamples, true);
        rightChannel = new Vector.<Number>(numSamples, true);

        log.debug("Num samples : " + numSamples);
        for (var i:int = 0; i < numSamples; i++) {
            if(buffer) {
                leftChannel[i] = buffer.readFloat();
                rightChannel[i] = buffer.readFloat();
            } else {
                leftChannel[i] = 0;
                rightChannel[i] = 0;
            }
        }

        if(!_loopEnd) {
            log.debug("Set loop end from BPM");
            var numBeats:Number = Math.floor(numSamples / tempo.samplesPerBeat);
            _bars = Math.floor(numBeats / 4);
            samplesPerBar = tempo.samplesPerBeat * 4;
            _loopEnd = _bars * samplesPerBar;
            log.debug("Num beats : " + numBeats + ". Bars : " + bars + ". Loop end : " + _loopEnd);
        }
        updateLoopLength();
        ready = true;
    }

    private function checkLoopStart():void {
        _loopLength = _loopEnd - _loopStart;
        log.debug("Check loop start. Start : " + _loopStart + ". End : " + _loopEnd + ". Length " + _loopLength);
        if(_loopStart > (_loopEnd - minimumLoopLength)) {
            _loopStart = _loopEnd - minimumLoopLength;
            log.debug("Moved start to end - min length : " + _loopStart);
        }
        if(_loopStart < 0) {
            log.debug("Start < 0. Set to 0");
            _loopStart = 0;
        }
        updateLoopLength();
    }

    private function updateLoopLength():void {
        _loopLength = _loopEnd - _loopStart;
        samplesPerBar = _loopLength / _bars;
        _loopLengthInMilliseconds = _loopLength / 44.1;
        loopLengthInMsInverse = 1 / _loopLengthInMilliseconds;
        log.debug("Loop start is " + (_loopStart) + ". Length is " + ((_loopEnd - _loopStart)));
    }

    private function checkLoopEnd():void {
        _loopLength = _loopEnd - _loopStart;
        if(_loopEnd < _loopStart + minimumLoopLength) {
            _loopEnd = _loopStart + minimumLoopLength;
        }
        if(numSamples) {
            if(_loopEnd > numSamples) {
                log.debug("Loop end > numSamples. end : " + _loopEnd + ". numSamples : " + numSamples);
                _loopEnd = numSamples;
            }
        } else {
            log.debug("Num samples not set yet");
        }
        updateLoopLength();
    }

    public function get loopStart():int {
        return _loopStart;
    }

    public function setLoopStart(start:int, moveEnd:Boolean = true):void {

        var ds:int = (start - _loopStart);
        _loopStart = start;

        checkLoopStart();
        if(moveEnd) {
            _loopEnd += ds;
            checkLoopEnd();
        }
    }

    public function get loopEnd():Number {
        return _loopEnd;
    }

    public function set loopEnd(le:Number):void {
        _loopEnd = le;
        checkLoopEnd();
    }

    public function moveLoopEnd(amount:int):void {
        _loopEnd += amount;
        checkLoopEnd();
    }

    public function moveLoopStart(amount:int):void {
        _loopStart += amount;
        checkLoopStart();
    }

    /**
     * Loop points normalised between 0 and 1.
     * @return
     */
    public function getLoopPoints():Object {
        var l:Object = {start:(_loopStart / numSamples),end:(_loopEnd / numSamples), length:_loopLength };
        return l;
    }

    /**
     * @param loopLength    Loop length in samples
     */
    public function set loopLength(loopLength:int):void {
        if(loopLength < minimumLoopLength) {
            loopLength = minimumLoopLength;
        }
        if(_loopStart + loopLength <= numSamples) {
            _loopEnd = _loopStart + loopLength;
        } else {
            _loopEnd = numSamples - _loopStart;
        }
        updateLoopLength();
    }

    /**
     * Partial buffer fill, starting in the dest buffer at offset
     * @param left
     * @param right
     * @param offset
     * @param sampleCount
     */
    public function writePartial(left:Vector.<Number>,right:Vector.<Number>, offset:int, sampleCount:int):void {
        var readOffset:int = readPosition + _loopStart;
        var sampleIndex:int = 0;
        for(var i:int=0;i<sampleCount;i++) {
            sampleIndex = (readOffset + i) % _loopLength;
            left[i + offset] += leftChannel[sampleIndex];
            right[i + offset] += rightChannel[sampleIndex];
        }
        readPosition = (readPosition + sampleCount) % _loopLength;
    }
    /**
     * Dest is vector of interleaved samples
     * @param dest
     * @param sampleCount
     */
    public function write(left:Vector.<Number>, right:Vector.<Number>,sampleCount:int):void {

        var startPos:int = 0;
        var endPos:int = sampleCount;
        var placeInBar:int;
        var endPlaceInBar:int;
        ending = false;

        // If we're waiting to start when we hit a bar boundary
        if(waitForQuantizedSync) {
            if(readPosition == 0) {
                waitForQuantizedSync = false;
                pendingStateChange = 0;
            } else {
                // Check if there is a boundary between readPosition and (readPosition + sampleCount)
                placeInBar = readPosition % samplesPerBar;
                endPlaceInBar = (readPosition + sampleCount) % samplesPerBar;
                //trace("Wait for quantized sync " + placeInBar + " : " + endPlaceInBar);

                if(endPlaceInBar < placeInBar) {
                    // If the end pos has wrapped around a bar boundary then we do a partial fill
                    // and turn off waitingForQuantizedSync
                    startPos = samplesPerBar - placeInBar;
                    waitForQuantizedSync = false;
                    pendingStateChange = 0;
                } else {
                    // Jump to the end
                    startPos = sampleCount;
                }
            }
        } else if(_fillToSyncBoundary) {
            // fill only to end of a bar then stop
            placeInBar = readPosition % samplesPerBar;
            endPlaceInBar = (readPosition + sampleCount) % samplesPerBar;
//            trace("Wait for quantized sync " + placeInBar + " : " + endPlaceInBar);

            if(endPlaceInBar < placeInBar) {
                // If the end pos has wrapped around a bar boundary then we do a partial fill
                // and turn off waitingForQuantizedSync
                endPos = samplesPerBar - placeInBar;
                _fillToSyncBoundary = false;
                active = false;
                pendingStateChange = 0;
                ending = true;
            }
        }

        // Fill buffer as normal
        var sampleIndex:int = 0;
        var i:int = startPos;
        //  processFilters();
        var offset:int = readPosition + _loopStart;
        for(i;i<endPos;i++) {
            sampleIndex = (offset + i) % _loopLength;
            left[i] += leftChannel[sampleIndex];
            right[i] += rightChannel[sampleIndex];
        }
        readPosition = (readPosition + sampleCount) % _loopLength;
    }

    private function processFilters():void {
//        if(filters.length) {
//            filters[0].processBlock(leftChannel, left, startPos, readPosition + _loopStart, _loopLength, sampleCount);
//            filters[1].processBlock(rightChannel, right, startPos, readPosition + _loopStart, _loopLength, sampleCount);
//        } else {
    }

    public function get loopLengthInMilliseconds():Number {
        return _loopLengthInMilliseconds;
    }
    // Position in milliseconds
    public function get position():Number {
        return readPosition * inverseSampleRateKHz;
    }

    public function jumpToStart():void {
        readPosition = 0;
    }

    /**
     * Sync the read position to the supplied position, wrapping as needed
     * @param sampleReadPosition
     */
    public function start(sampleReadPosition:int, waitForQ:Boolean = false):void {
        if(_fillToSyncBoundary) {
            log.debug("Cancel stop");
            // Cancel the stop
            _fillToSyncBoundary = false;
        }
        readPosition = sampleReadPosition % _loopLength;
        log.debug("start. SRP : " + sampleReadPosition + ". RP: " + readPosition);
        waitForQuantizedSync = waitForQ;
        active = true;
        pendingStateChange = waitForQuantizedSync ? STARTING : 0;
    }

    public function stop():void {
        log.debug("Fill to sync boundary. WaitForQ : " + waitForQuantizedSync);
        if(waitForQuantizedSync) {
            // Previous start trigger should be cancelled
            waitForQuantizedSync = false;
            pendingStateChange = 0;
            active = false;
        } else if(active) {
            _fillToSyncBoundary = true;
            pendingStateChange = STOPPING;
        }
    }

    public function get bars():int {
        return _bars;
    }

    public function set bars(value:int):void {
        _bars = value;
        if(!_loopLength) {
            log.debug("ERROR : Loop Length isnt set")
        } else {
            samplesPerBar = _loopLength / _bars;
        }
    }

    public function toggle(syncPos:int = 0):Boolean {
        if(active) {
            if(pendingStateChange == AudioLoop.STOPPING) {
                // Start, no need to sync
                start(syncPos,false);
                return true;
            } else if(pendingStateChange == AudioLoop.STARTING) {
                // Stop
                stop();
                return false;
            } else {
                stop();
                return false;
            }
        } else {
//            trace("InActive Channel Switch. PSC : " + c.pendingStateChange);
            start(syncPos, true);
            return true;
        }
    }

    public function mute():void {
        gain = 0;
    }

    public function unmute():void {
        gain = 1;
    }

}
}
