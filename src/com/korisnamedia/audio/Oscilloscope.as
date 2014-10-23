/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/17/2014
 * Time: 4:01 PM
 */
package com.korisnamedia.audio {
import flash.display.Sprite;
import flash.utils.ByteArray;

public class Oscilloscope extends Sprite {
    private var _width:int;
    private var _height:int;

    public function Oscilloscope(w:int, h:int) {
        _width = w;
        _height = h;
    }

    // Render mono data, i.e. 4 bytes per sample
    public function render(data:ByteArray):void {
        graphics.clear();
        graphics.lineStyle(0, 0x000000);
        graphics.moveTo(0, 0);
        var nPitch:Number = _width / data.length;
        while(data.bytesAvailable)
            graphics.lineTo(data.position * nPitch, data.readFloat() * _height * 0.5);
        }
    }
}
