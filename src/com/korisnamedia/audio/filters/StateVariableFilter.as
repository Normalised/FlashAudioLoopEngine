/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/17/2014
 * Time: 4:46 PM
 */
package com.korisnamedia.audio.filters {
public class StateVariableFilter implements IFilter{
    private var f1:Number;
    private var q1:Number = 1;

//Input/Output
//    I - input sample
//    L - lowpass output sample
//    B - bandpass output sample
//    H - highpass output sample
//    N - notch output sample
//    F1 - Frequency control parameter
//    Q1 - Q control parameter
//    D1 - delay associated with bandpass output
//    D2 - delay associated with low-pass output

    public var filterType:int = 0;

    public static const LOW:int = 0;
    public static const HIGH:int = 1;
    public static const BAND:int = 2;
    public static const NOTCH:int = 3;

    private var D1:Number = 0;
    private var D2:Number = 0;
    public function StateVariableFilter() {
        cutoff = 8000;
    }

    public function set cutoff(f:Number):void {
        f1 = (2 * Math.PI * f) / 44100;
    }

    public function set q(qval:Number):void {
        q1 = 1 / qval;
    }

    public function process(I:Number):Number {
        // loop
        var L:Number = D2 + f1 * D1;
        var H:Number = I - L - q1 * D1;
        var B:Number = f1 * H + D1;
        var N:Number = H + L;

        // store delays
        D1 = B;
        D2 = L;

        // outputs
        switch(filterType) {
            case LOW:return L;
            case HIGH:return H;
            case BAND:return B;
            case NOTCH:return N;
        }
        return L;
    }

    public function processBlock(source:Vector.<Number>, dest:Vector.<Number>, startPos:int, sourcePos:int, loopLength:int, sampleCount:int):void {
        var sampleIndex:int = 0;
        var c:Array = [0,0,0,0];
        for(var i:int = startPos;i<sampleCount;i++) {
            sampleIndex = (sourcePos + i) % loopLength;

            var L:Number = D2 + f1 * D1;
            var H:Number = source[sampleIndex] - L - q1 * D1;
            var B:Number = f1 * H + D1;
            var N:Number = H + L;
            c = [L,H,B,N];

            // store delays
            D1 = B;
            D2 = L;

            dest[i] += c[filterType];
        }
    }
}
}
