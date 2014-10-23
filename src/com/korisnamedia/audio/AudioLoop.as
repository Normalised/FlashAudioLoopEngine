/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/17/2014
 * Time: 8:30 AM
 */
package com.korisnamedia.audio {
import com.korisnamedia.audio.filters.IFilter;

import flash.media.Sound;
import flash.profiler.showRedrawRegions;
import flash.utils.ByteArray;
import flash.utils.getTimer;

public class AudioLoop {

    private var _loopEnd:int;
    private var _loopStart:int = 0;
    private var _loopLength:int;

    // Where in the loop to read from. Between 0 and _loopLength
    private var readPosition:int = 0;

    public var leftChannel:Vector.<Number>;
    public var rightChannel:Vector.<Number>;

    private var numSamples:int = 0;

    private var minimumLoopLength:int = 64;

    private var _loopLengthInMilliseconds:Number = 1;

    private var _bars:int = 1;

    public var waitForQuantizedSync:Boolean =false;
    private var samplesPerBar:Number;

    public var ready:Boolean = false;

    public var filters:Vector.<IFilter>;
    private var tempo:Tempo;

    public function AudioLoop() {
        filters = new Vector.<IFilter>();
    }

    public function empty(size:int):void {
        numSamples = size;
        extractSamples();
    }

    public function copy(left:Vector.<Number>, right:Vector.<Number> = null, offset:int = 0):void {
        trace("Copy audio : " + left.length);
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

    public function fromMP3(mp3:Sound, offset:int, tempo:Tempo):void {
        this.tempo = tempo;
        var t:int = getTimer();
        var samplesTotal:int = Math.floor(mp3.length * 44.1);
        trace("Num samples : " + samplesTotal);
        var buffer:ByteArray = new ByteArray();
        mp3.extract(buffer, samplesTotal, offset);
        var t2:int = getTimer();
        trace("Extract took " + (t2 - t));

        trace("Audio buffer samples available : " + (buffer.bytesAvailable / 8));

        buffer.position = 0;
        numSamples = buffer.bytesAvailable / 8;
        extractSamples(buffer);
    }

    private function extractSamples(buffer:ByteArray = null):void {
        leftChannel = new Vector.<Number>(numSamples, true);
        rightChannel = new Vector.<Number>(numSamples, true);

        trace("Num samples : " + numSamples);
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
            trace("Set loop end from BPM");
            var numBeats:Number = Math.floor(numSamples / tempo.samplesPerBeat);
            _bars = Math.floor(numBeats / 4);
            samplesPerBar = tempo.samplesPerBeat * 4;
            _loopEnd = _bars * samplesPerBar;
            trace("Num beats : " + numBeats + ". Bars : " + bars + ". Loop end : " + _loopEnd);
        }
        updateLoopLength();
        ready = true;
    }

    private function checkLoopStart():void {
        _loopLength = _loopEnd - _loopStart;
        if(_loopStart > (_loopEnd - minimumLoopLength)) {
            _loopStart = _loopEnd - minimumLoopLength;
        }
        if(_loopStart < 0) {
            _loopStart = 0;
        }
        updateLoopLength();
    }

    private function updateLoopLength():void {
        _loopLength = _loopEnd - _loopStart;
        samplesPerBar = _loopLength / _bars;
        _loopLengthInMilliseconds = _loopLength / 44.1;
        trace("Loop start is " + (_loopStart) + ". Length is " + ((_loopEnd - _loopStart)));
    }

    private function checkLoopEnd():void {
        _loopLength = _loopEnd - _loopStart;
        if(_loopEnd < _loopStart + minimumLoopLength) {
            _loopEnd = _loopStart + minimumLoopLength;
        }
        if(numSamples) {
            if(_loopEnd > numSamples) {
                _loopEnd = numSamples;
            }
        } else {
            trace("Num samples not set yet");
        }
        updateLoopLength();
    }

    public function get loopStart():int {
        return _loopStart;
    }

    public function set loopStart(start:int):void {
        _loopStart = start;
        checkLoopStart();
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

    public function set loopLength(loopLength:int):void {
        if(loopLength < minimumLoopLength) {
            loopLength = minimumLoopLength;
        }
        if(_loopStart + loopLength <= (numSamples - _loopStart)) {
            _loopEnd = _loopStart + loopLength;
        } else {
            _loopEnd = numSamples - _loopStart;
        }
        updateLoopLength();
    }

    /**
     * Dest is vector of interleaved samples
     * @param dest
     * @param sampleCount
     */
    public function write(left:Vector.<Number>, right:Vector.<Number>,sampleCount:int):void {

        var startPos:int = 0;
        // If we're waiting to sync on a bar
        if(waitForQuantizedSync) {
            if(readPosition == 0) {
                waitForQuantizedSync = false;
            } else {
                // Check if there is a boundary between readPosition and (readPosition + sampleCount)
                var placeInBar:int = readPosition % samplesPerBar;
                var endPlaceInBar:int = (readPosition + sampleCount) % samplesPerBar;
                trace("Wait for quantized sync " + placeInBar + " : " + endPlaceInBar);

                if(endPlaceInBar < placeInBar) {
                    // If the end pos has wrapped around a bar boundary then we do a partial fill
                    // and turn off waitingForQuantizedSync
                    startPos = samplesPerBar - placeInBar;
                    waitForQuantizedSync = false;
                } else {
                    startPos = sampleCount;
                }
            }
        }

        // Fill buffer as normal
        var sampleIndex:int = 0;
        var i:int = startPos;
        if(filters.length) {
            filters[0].processBlock(leftChannel, left, startPos, readPosition + _loopStart, _loopLength, sampleCount);
            filters[1].processBlock(rightChannel, right, startPos, readPosition + _loopStart, _loopLength, sampleCount);
        } else {
            for(i;i<sampleCount;i++) {
                sampleIndex = (readPosition + i + _loopStart) % _loopLength;
                left[i] += leftChannel[sampleIndex];
                right[i] += rightChannel[sampleIndex];
            }
        }
        readPosition = (readPosition + sampleCount) % _loopLength;
    }

    public function get loopLengthInMilliseconds():Number {
        return _loopLengthInMilliseconds;
    }
    // Position in milliseconds
    public function get position():Number {
        return readPosition / 44.1;
    }

    public function jumpToStart():void {
        readPosition = 0;
    }

    /**
     * Sync the read position to the supplied position, wrapping as needed
     * @param sampleReadPosition
     */
    public function syncTo(sampleReadPosition:int, waitForQ:Boolean = false):void {
        readPosition = sampleReadPosition % _loopLength;
        trace("syncTo. SRP : " + sampleReadPosition + ". RP: " + readPosition);
        waitForQuantizedSync = waitForQ;
    }

    public function get bars():int {
        return _bars;
    }

    public function set bars(value:int):void {
        _bars = value;
        samplesPerBar = _loopLength / _bars;
    }
}
}
