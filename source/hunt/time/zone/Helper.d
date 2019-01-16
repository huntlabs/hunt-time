/*
 * hunt-time: A time library for D programming language.
 *
 * Copyright (C) 2015-2018 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.time.zone.Helper;

import hunt.time.zone.ZoneRulesProvider;
// import hunt.time.zone.TzdbZoneRulesProvider;

import hunt.collection.Set;
import hunt.collection.HashSet;

class ZoneRulesHelper {
    private __gshared Set!(string) ZONE_IDS;

    /**
     * Gets the set of available zone IDs.
     * !(p)
     * These IDs are the string form of a {@link ZoneId}.
     *
     * @return the unmodifiable set of zone IDs, not null
     */
    public static Set!(string) getAvailableZoneIds() {
        if(ZONE_IDS is null) {
            ZONE_IDS = new HashSet!(string)();
            foreach(data; ZoneRulesProvider.ZONES.keySet()) {
                ZONE_IDS.add(data);
            }
            
        }
        return ZONE_IDS;
    }    
}