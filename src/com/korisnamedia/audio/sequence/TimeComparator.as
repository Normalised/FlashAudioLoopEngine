/**
 * Created by Martin Wood-Mitrovski
 * Date: 10/29/2014
 * Time: 10:41 AM
 */
package com.korisnamedia.audio.sequence {
import org.as3coreaddendum.system.IComparator;

public class TimeComparator implements IComparator {
    public function TimeComparator() {
    }

    public function compare(o1:*, o2:*):int {
        if(o1 < o2) return -1;
        if(o2 < o1) return 1;
        return 0;
    }
}
}
