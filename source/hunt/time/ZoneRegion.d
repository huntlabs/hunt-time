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

module hunt.time.ZoneRegion;

import hunt.collection.HashMap;
import hunt.collection.Map;
import hunt.Exceptions;
import hunt.stream.Common;
import hunt.stream.DataInput;
import hunt.stream.DataOutput;

import hunt.text.Common;

import hunt.time.Exceptions;
import hunt.time.zone.ZoneRules;
import hunt.time.zone.ZoneRulesException;
import hunt.time.zone.ZoneRulesProvider;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.Ser;
import hunt.time.util.Common;

import hunt.util.Common;
import hunt.util.Serialize;

import std.string;

/**
 * A geographical region where the same time-zone rules apply.
 * !(p)
 * Time-zone information is categorized as a set of rules defining when and
 * how the offset from UTC/Greenwich changes. These rules are accessed using
 * identifiers based on geographical regions, such as countries or states.
 * The most common region classification is the Time Zone Database (TZDB),
 * which defines regions such as 'Europe/Paris' and 'Asia/Tokyo'.
 * !(p)
 * The region identifier, modeled by this class, is distinct from the
 * underlying rules, modeled by {@link ZoneRules}.
 * The rules are defined by governments and change frequently.
 * By contrast, the region identifier is well-defined and long-lived.
 * This separation also allows rules to be shared between regions if appropriate.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
final class ZoneRegion : ZoneId , Serializable {

    /**
     * The time-zone ID, not null.
     */
    private  string id;
    /**
     * The time-zone rules, null if zone ID was loaded leniently.
     */
    private  ZoneRules rules;

    /**
     * Checks that the given string is a legal ZondId name.
     *
     * @param zoneId  the time-zone ID, not null
     * @throws DateTimeException if the ID format is invalid
     */
    private static void checkName(string zoneId) {
        auto n = zoneId.length;
        if (n < 2) {
           throw new DateTimeException("Invalid ID for region-based ZoneId, invalid format: " ~ zoneId);
        }
        for (int i = 0; i < n; i++) {
            char c = zoneId[i];
            if (c >= 'a' && c <= 'z') continue;
            if (c >= 'A' && c <= 'Z') continue;
            if (c == '/' && i != 0) continue;
            if (c >= '0' && c <= '9' && i != 0) continue;
            if (c == '~' && i != 0) continue;
            if (c == '.' && i != 0) continue;
            if (c == '_' && i != 0) continue;
            if (c == '+' && i != 0) continue;
            if (c == '-' && i != 0) continue;
            throw new DateTimeException("Invalid ID for region-based ZoneId, invalid format: " ~ zoneId);
        }
    }

    //-------------------------------------------------------------------------
    /**
     * Constructor.
     *
     * @param id  the time-zone ID, not null
     * @param rules  the rules, null for lazy lookup
     */
    this(string id, ZoneRules rules) {
        this.id = id;
        this.rules = rules;
    }

    //-----------------------------------------------------------------------
    override
    public string getId() {
        return id;
    }

    override
    public ZoneRules getRules() {
        // additional query for group provider when null allows for possibility
        // that the provider was updated after the ZoneId was created
        return (rules !is null ? rules : ZoneRulesProvider.getRules(id, false));
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(7);  // identifies a ZoneId (not ZoneOffset)
     *  _out.writeUTF(zoneId);
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.ZONE_REGION_TYPE, this);
    }

    /**
     * Defend against malicious streams.
     *
     * @param s the stream to read
     * @throws InvalidObjectException always
     */
     ///@gxc
    // private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
    //     throw new InvalidObjectException("Deserialization via serialization delegate");
    // }

    // override
    // void write(DataOutput _out) /*throws IOException*/ {
    //     _out.writeByte(Ser.ZONE_REGION_TYPE);
    //     writeExternal(_out);
    // }

    // void writeExternal(DataOutput _out) /*throws IOException*/ {
    //     _out.writeUTF(id);
    // }

    // static ZoneId readExternal(DataInput _in) /*throws IOException*/ {
    //     string id = _in.readUTF();
    //     return ZoneId.of(id, false);
    // }

    
    /**
     * Gets the system default time-zone.
     * !(p)
     * This queries {@link TimeZone#getDefault()} to find the default time-zone
     * and converts it to a {@code ZoneId}. If the system default time-zone is changed,
     * then the result of this method will also change.
     *
     * @return the zone ID, not null
     * @throws DateTimeException if the converted zone ID has an invalid format
     * @throws ZoneRulesException if the converted zone region ID cannot be found
     */
    public static ZoneId systemDefault() {
        // return TimeZone.getDefault().toZoneId();
        import hunt.system.TimeZone;
        return ZoneRegion.of(getSystemTimeZoneId(),true);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code ZoneId} using its ID using a map
     * of aliases to supplement the standard zone IDs.
     * !(p)
     * Many users of time-zones use short abbreviations, such as PST for
     * 'Pacific Standard Time' and PDT for 'Pacific Daylight Time'.
     * These abbreviations are not unique, and so cannot be used as IDs.
     * This method allows a map of string to time-zone to be setup and reused
     * within an application.
     *
     * @param zoneId  the time-zone ID, not null
     * @param aliasMap  a map of alias zone IDs (typically abbreviations) to real zone IDs, not null
     * @return the zone ID, not null
     * @throws DateTimeException if the zone ID has an invalid format
     * @throws ZoneRulesException if the zone ID is a region ID that cannot be found
     */
    public static ZoneId of(string zoneId, Map!(string, string) aliasMap) {
        assert(zoneId, "zoneId");
        assert(aliasMap, "aliasMap");
        string id = aliasMap.get(zoneId) is null ? aliasMap.get(zoneId) : zoneId;
        return of(id);
    }

    /**
     * Obtains an instance of {@code ZoneId} from an ID ensuring that the
     * ID is valid and available for use.
     * !(p)
     * This method parses the ID producing a {@code ZoneId} or {@code ZoneOffset}.
     * A {@code ZoneOffset} is returned if the ID is 'Z', or starts with '+' or '-'.
     * The result will always be a valid ID for which {@link ZoneRules} can be obtained.
     * !(p)
     * Parsing matches the zone ID step by step as follows.
     * !(ul)
     * !(li)If the zone ID equals 'Z', the result is {@code ZoneOffset.UTC}.
     * !(li)If the zone ID consists of a single letter, the zone ID is invalid
     *  and {@code DateTimeException} is thrown.
     * !(li)If the zone ID starts with '+' or '-', the ID is parsed as a
     *  {@code ZoneOffset} using {@link ZoneOffset#of(string)}.
     * !(li)If the zone ID equals 'GMT', 'UTC' or 'UT' then the result is a {@code ZoneId}
     *  with the same ID and rules equivalent to {@code ZoneOffset.UTC}.
     * !(li)If the zone ID starts with 'UTC+', 'UTC-', 'GMT+', 'GMT-', 'UT+' or 'UT-'
     *  then the ID is a prefixed offset-based ID. The ID is split _in two, with
     *  a two or three letter prefix and a suffix starting with the sign.
     *  The suffix is parsed as a {@link ZoneOffset#of(string) ZoneOffset}.
     *  The result will be a {@code ZoneId} with the specified UTC/GMT/UT prefix
     *  and the normalized offset ID as per {@link ZoneOffset#getId()}.
     *  The rules of the returned {@code ZoneId} will be equivalent to the
     *  parsed {@code ZoneOffset}.
     * !(li)All other IDs are parsed as region-based zone IDs. Region IDs must
     *  match the regular expression !(code)[A-Za-z][A-Za-z0-9~/._+-]+</code>
     *  otherwise a {@code DateTimeException} is thrown. If the zone ID is not
     *  _in the configured set of IDs, {@code ZoneRulesException} is thrown.
     *  The detailed format of the region ID depends on the group supplying the data.
     *  The default set of data is supplied by the IANA Time Zone Database (TZDB).
     *  This has region IDs of the form '{area}/{city}', such as 'Europe/Paris' or 'America/New_York'.
     *  This is compatible with most IDs from {@link java.util.TimeZone}.
     * </ul>
     *
     * @param zoneId  the time-zone ID, not null
     * @return the zone ID, not null
     * @throws DateTimeException if the zone ID has an invalid format
     * @throws ZoneRulesException if the zone ID is a region ID that cannot be found
     */
    public static ZoneId of(string zoneId) {
        return of(zoneId, true);
    }

    /**
     * Parses the ID, taking a flag to indicate whether {@code ZoneRulesException}
     * should be thrown or not, used _in deserialization.
     *
     * @param zoneId  the time-zone ID, not null
     * @param checkAvailable  whether to check if the zone ID is available
     * @return the zone ID, not null
     * @throws DateTimeException if the ID format is invalid
     * @throws ZoneRulesException if checking availability and the ID cannot be found
     */
    static ZoneId of(string zoneId, bool checkAvailable) {
        assert(zoneId, "zoneId");
        if (zoneId.length <= 1 || zoneId.startsWith("+") || zoneId.startsWith("-")) {
            return ZoneOffset.of(zoneId);
        } else if (zoneId.startsWith("UTC") || zoneId.startsWith("GMT")) {
            return ofWithPrefix(zoneId, 3, checkAvailable);
        } else if (zoneId.startsWith("UT")) {
            return ofWithPrefix(zoneId, 2, checkAvailable);
        }
        return ZoneRegion.ofId(zoneId, checkAvailable);
    }

    /**
     * Obtains an instance of {@code ZoneId} from an identifier.
     *
     * @param zoneId  the time-zone ID, not null
     * @param checkAvailable  whether to check if the zone ID is available
     * @return the zone ID, not null
     * @throws DateTimeException if the ID format is invalid
     * @throws ZoneRulesException if checking availability and the ID cannot be found
     */
    static ZoneRegion ofId(string zoneId, bool checkAvailable) {
        assert(zoneId, "zoneId");
        checkName(zoneId);
        ZoneRules rules = null;
        try {
            // always attempt load for better behavior after deserialization
            rules = ZoneRulesProvider.getRules(zoneId, true);
        } catch (ZoneRulesException ex) {
            if (checkAvailable) {
                throw ex;
            }
        }
        return new ZoneRegion(zoneId, rules);
    }

    /**
     * Obtains an instance of {@code ZoneId} wrapping an offset.
     * !(p)
     * If the prefix is "GMT", "UTC", or "UT" a {@code ZoneId}
     * with the prefix and the non-zero offset is returned.
     * If the prefix is empty {@code ""} the {@code ZoneOffset} is returned.
     *
     * @param prefix  the time-zone ID, not null
     * @param offset  the offset, not null
     * @return the zone ID, not null
     * @throws IllegalArgumentException if the prefix is not one of
     *     "GMT", "UTC", or "UT", or ""
     */
    public static ZoneId ofOffset(string prefix, ZoneOffset offset) {
        assert(prefix, "prefix");
        assert(offset, "offset");
        if (prefix.length == 0) {
            return offset;
        }

        if (!(prefix == "GMT") && !(prefix == "UTC") && !(prefix == "UT")) {
             throw new IllegalArgumentException("prefix should be GMT, UTC or UT, is: " ~ prefix);
        }

        if (offset.getTotalSeconds() != 0) {
            prefix = prefix ~ (offset.getId());
        }
        return new ZoneRegion(prefix, offset.getRules());
    }

    
    /**
     * Parse once a prefix is established.
     *
     * @param zoneId  the time-zone ID, not null
     * @param prefixLength  the length of the prefix, 2 or 3
     * @return the zone ID, not null
     * @throws DateTimeException if the zone ID has an invalid format
     */
    private static ZoneId ofWithPrefix(string zoneId, int prefixLength, bool checkAvailable) {
        string prefix = zoneId.substring(0, prefixLength);
        if (zoneId.length == prefixLength) {
            return ofOffset(prefix, ZoneOffset.UTC);
        }
        if (zoneId[prefixLength] != '+' && zoneId[prefixLength] != '-') {
            return ZoneRegion.ofId(zoneId, checkAvailable);  // drop through to ZoneRulesProvider
        }
        try {
            ZoneOffset offset = ZoneOffset.of(zoneId.substring(prefixLength));
            if (offset == ZoneOffset.UTC) {
                return ofOffset(prefix, offset);
            }
            return ofOffset(prefix, offset);
        } catch (DateTimeException ex) {
            throw new DateTimeException("Invalid ID for offset-based ZoneId: " ~ zoneId, ex);
        }
    }

        mixin SerializationMember!(typeof(this));
}
