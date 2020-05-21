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

module hunt.time.ZoneId;

import hunt.stream.DataOutput;
import hunt.Exceptions;

import std.conv;
import hunt.stream.Common;
// import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.format.TextStyle;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.ValueRange;
import hunt.time.temporal.ChronoField;
import hunt.time.Exceptions;
import hunt.time.zone.ZoneRules;
import hunt.time.zone.ZoneRulesException;
// import hunt.time.zone.ZoneRulesProvider;
import hunt.collection.HashSet;
// import hunt.time.util.Locale;
import hunt.collection;
import hunt.time.ZoneOffset;
import hunt.time.Ser;
import hunt.util.StringBuilder;
// import hunt.time.ZoneRegion;
import std.algorithm.searching;
import hunt.text.Common;
import hunt.time.Exceptions;
import hunt.Assert;
import hunt.time.Instant;
import hunt.time.util.QueryHelper;
import hunt.time.util.Common;

import hunt.util.Common;
import hunt.util.Serialize;

import std.concurrency : initOnce;

/**
 * A time-zone ID, such as {@code Europe/Paris}.
 * !(p)
 * A {@code ZoneId} is used to identify the rules used to convert between
 * an {@link Instant} and a {@link LocalDateTime}.
 * There are two distinct types of ID:
 * !(ul)
 * !(li)Fixed offsets - a fully resolved offset from UTC/Greenwich, that uses
 *  the same offset for all local date-times
 * !(li)Geographical regions - an area where a specific set of rules for finding
 *  the offset from UTC/Greenwich apply
 * </ul>
 * Most fixed offsets are represented by {@link ZoneOffset}.
 * Calling {@link #normalized()} on any {@code ZoneId} will ensure that a
 * fixed offset ID will be represented as a {@code ZoneOffset}.
 * !(p)
 * The actual rules, describing when and how the offset changes, are defined by {@link ZoneRules}.
 * This class is simply an ID used to obtain the underlying rules.
 * This approach is taken because rules are defined by governments and change
 * frequently, whereas the ID is stable.
 * !(p)
 * The distinction has other effects. Serializing the {@code ZoneId} will only send
 * the ID, whereas serializing the rules sends the entire data set.
 * Similarly, a comparison of two IDs only examines the ID, whereas
 * a comparison of two rules examines the entire data set.
 *
 * !(h3)Time-zone IDs</h3>
 * The ID is unique within the system.
 * There are three types of ID.
 * !(p)
 * The simplest type of ID is that from {@code ZoneOffset}.
 * This consists of 'Z' and IDs starting with '+' or '-'.
 * !(p)
 * The next type of ID are offset-style IDs with some form of prefix,
 * such as 'GMT+2' or 'UTC+01:00'.
 * The recognised prefixes are 'UTC', 'GMT' and 'UT'.
 * The offset is the suffix and will be normalized during creation.
 * These IDs can be normalized to a {@code ZoneOffset} using {@code normalized()}.
 * !(p)
 * The third type of ID are region-based IDs. A region-based ID must be of
 * two or more characters, and not start with 'UTC', 'GMT', 'UT' '+' or '-'.
 * Region-based IDs are defined by configuration, see {@link ZoneRulesProvider}.
 * The configuration focuses on providing the lookup from the ID to the
 * underlying {@code ZoneRules}.
 * !(p)
 * Time-zone rules are defined by governments and change frequently.
 * There are a number of organizations, known here as groups, that monitor
 * time-zone changes and collate them.
 * The default group is the IANA Time Zone Database (TZDB).
 * Other organizations include IATA (the airline industry body) and Microsoft.
 * !(p)
 * Each group defines its own format for the region ID it provides.
 * The TZDB group defines IDs such as 'Europe/London' or 'America/New_York'.
 * TZDB IDs take precedence over other groups.
 * !(p)
 * It is strongly recommended that the group name is included _in all IDs supplied by
 * groups other than TZDB to avoid conflicts. For example, IATA airline time-zone
 * region IDs are typically the same as the three letter airport code.
 * However, the airport of Utrecht has the code 'UTC', which is obviously a conflict.
 * The recommended format for region IDs from groups other than TZDB is 'group~region'.
 * Thus if IATA data were defined, Utrecht airport would be 'IATA~UTC'.
 *
 * !(h3)Serialization</h3>
 * This class can be serialized and stores the string zone ID _in the external form.
 * The {@code ZoneOffset} subclass uses a dedicated format that only stores the
 * offset from UTC/Greenwich.
 * !(p)
 * A {@code ZoneId} can be deserialized _in a Java Runtime where the ID is unknown.
 * For example, if a server-side Java Runtime has been updated with a new zone ID, but
 * the client-side Java Runtime has not been updated. In this case, the {@code ZoneId}
 * object will exist, and can be queried using {@code getId}, {@code equals},
 * {@code hashCode}, {@code toString}, {@code getDisplayName} and {@code normalized}.
 * However, any call to {@code getRules} will fail with {@code ZoneRulesException}.
 * This approach is designed to allow a {@link ZonedDateTime} to be loaded and
 * queried, but not modified, on a Java Runtime with incomplete time-zone information.
 *
 * !(p)
 * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
 * class; use of identity-sensitive operations (including reference equality
 * ({@code ==}), identity hash code, or synchronization) on instances of
 * {@code ZoneId} may have unpredictable results and should be avoided.
 * The {@code equals} method should be used for comparisons.
 *
 * @implSpec
 * This abstract class has two implementations, both of which are immutable and thread-safe.
 * One implementation models region-based IDs, the other is {@code ZoneOffset} modelling
 * offset-based IDs. This difference is visible _in serialization.
 *
 * @since 1.8
 */
abstract class ZoneId : Serializable {

    /**
     * A map of zone overrides to enable the short time-zone names to be used.
     * !(p)
     * Use of short zone IDs has been deprecated _in {@code java.util.TimeZone}.
     * This map allows the IDs to continue to be used via the
     * {@link #of(string, Map)} factory method.
     * !(p)
     * This map contains a mapping of the IDs that is _in line with TZDB 2005r and
     * later, where 'EST', 'MST' and 'HST' map to IDs which do not include daylight
     * savings.
     * !(p)
     * This maps as follows:
     * !(ul)
     * !(li)EST - -05:00</li>
     * !(li)HST - -10:00</li>
     * !(li)MST - -07:00</li>
     * !(li)ACT - Australia/Darwin</li>
     * !(li)AET - Australia/Sydney</li>
     * !(li)AGT - America/Argentina/Buenos_Aires</li>
     * !(li)ART - Africa/Cairo</li>
     * !(li)AST - America/Anchorage</li>
     * !(li)BET - America/Sao_Paulo</li>
     * !(li)BST - Asia/Dhaka</li>
     * !(li)CAT - Africa/Harare</li>
     * !(li)CNT - America/St_Johns</li>
     * !(li)CST - America/Chicago</li>
     * !(li)CTT - Asia/Shanghai</li>
     * !(li)EAT - Africa/Addis_Ababa</li>
     * !(li)ECT - Europe/Paris</li>
     * !(li)IET - America/Indiana/Indianapolis</li>
     * !(li)IST - Asia/Kolkata</li>
     * !(li)JST - Asia/Tokyo</li>
     * !(li)MIT - Pacific/Apia</li>
     * !(li)NET - Asia/Yerevan</li>
     * !(li)NST - Pacific/Auckland</li>
     * !(li)PLT - Asia/Karachi</li>
     * !(li)PNT - America/Phoenix</li>
     * !(li)PRT - America/Puerto_Rico</li>
     * !(li)PST - America/Los_Angeles</li>
     * !(li)SST - Pacific/Guadalcanal</li>
     * !(li)VST - Asia/Ho_Chi_Minh</li>
     * </ul>
     * The map is unmodifiable.
     */
    
    

    static Map!(string, string) SHORT_IDS()
    {
        __gshared Map!(string, string) inst;
        
        return initOnce!inst({
            HashMap!(string, string) _SHORT_IDS = new HashMap!(string, string);
            _SHORT_IDS.put("ACT", "Australia/Darwin");
            _SHORT_IDS.put("AET", "Australia/Sydney");
            _SHORT_IDS.put("AGT", "America/Argentina/Buenos_Aires");
            _SHORT_IDS.put("ART", "Africa/Cairo");
            _SHORT_IDS.put("AST", "America/Anchorage");
            _SHORT_IDS.put("BET", "America/Sao_Paulo");
            _SHORT_IDS.put("BST", "Asia/Dhaka");
            _SHORT_IDS.put("CAT", "Africa/Harare");
            _SHORT_IDS.put("CNT", "America/St_Johns");
            _SHORT_IDS.put("CST", "America/Chicago");
            _SHORT_IDS.put("CTT", "Asia/Shanghai");
            _SHORT_IDS.put("EAT", "Africa/Addis_Ababa");
            _SHORT_IDS.put("ECT", "Europe/Paris");
            _SHORT_IDS.put("IET", "America/Indiana/Indianapolis");
            _SHORT_IDS.put("IST", "Asia/Kolkata");
            _SHORT_IDS.put("JST", "Asia/Tokyo");
            _SHORT_IDS.put("MIT", "Pacific/Apia");
            _SHORT_IDS.put("NET", "Asia/Yerevan");
            _SHORT_IDS.put("NST", "Pacific/Auckland");
            _SHORT_IDS.put("PLT", "Asia/Karachi");
            _SHORT_IDS.put("PNT", "America/Phoenix");
            _SHORT_IDS.put("PRT", "America/Puerto_Rico");
            _SHORT_IDS.put("PST", "America/Los_Angeles");
            _SHORT_IDS.put("SST", "Pacific/Guadalcanal");
            _SHORT_IDS.put("VST", "Asia/Ho_Chi_Minh");
            _SHORT_IDS.put("EST", "-05:00");
            _SHORT_IDS.put("MST", "-07:00");
            _SHORT_IDS.put("HST", "-10:00");
            return _SHORT_IDS;
        }());
    }

    //-----------------------------------------------------------------------
 
    deprecated("Using ZoneRegion.systemDefault instead.")
    static ZoneId systemDefault() {
        throw new Exception("Using ZoneRegion.systemDefault instead.");
    }

    /**
     * Gets the set of available zone IDs.
     * !(p)
     * This set includes the string form of all available region-based IDs.
     * Offset-based zone IDs are not included _in the returned set.
     * The ID can be passed to {@link #of(string)} to create a {@code ZoneId}.
     * !(p)
     * The set of zone IDs can increase over time, although _in a typical application
     * the set of IDs is fixed. Each call to this method is thread-safe.
     *
     * @return a modifiable copy of the set of zone IDs, not null
     */
    // static Set!(string) getAvailableZoneIds() {
    //     return new HashSet!(string)(ZoneRulesProvider.getAvailableZoneIds());
    // }

    
    deprecated("Using ZoneRegion.of instead.")
    static ZoneId of(string zoneId, Map!(string, string) aliasMap) {
        throw new Exception("Using ZoneRegion.of instead.");
    }

   
    deprecated("Using ZoneRegion.of instead.")
    static ZoneId of(string zoneId) {
        throw new Exception("Using ZoneRegion.of instead.");
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

    deprecated("Using ZoneRegion.ofOffset instead.")
    static ZoneId ofOffset(string prefix, ZoneOffset offset) {
        throw new Exception("Using ZoneRegion.ofOffset instead.");
        // assert(prefix, "prefix");
        // assert(offset, "offset");
        // if (prefix.length == 0) {
        //     return offset;
        // }

        // if (!(prefix == "GMT") && !(prefix == "UTC") && !(prefix == "UT")) {
        //      throw new IllegalArgumentException("prefix should be GMT, UTC or UT, is: " ~ prefix);
        // }

        // if (offset.getTotalSeconds() != 0) {
        //     prefix = prefix ~ (offset.getId());
        // }
        // return new ZoneRegion(prefix, offset.getRules());
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
    deprecated("Using ZoneRegion.of instead.")
    static ZoneId of(string zoneId, bool checkAvailable) {
        throw new Exception("Using ZoneRegion.of instead.");
        // assert(zoneId, "zoneId");
        // if (zoneId.length <= 1 || zoneId.startsWith("+") || zoneId.startsWith("-")) {
        //     return ZoneOffset.of(zoneId);
        // } else if (zoneId.startsWith("UTC") || zoneId.startsWith("GMT")) {
        //     return ofWithPrefix(zoneId, 3, checkAvailable);
        // } else if (zoneId.startsWith("UT")) {
        //     return ofWithPrefix(zoneId, 2, checkAvailable);
        // }
        // return ZoneRegion.ofId(zoneId, checkAvailable);
    }

    /**
     * Parse once a prefix is established.
     *
     * @param zoneId  the time-zone ID, not null
     * @param prefixLength  the length of the prefix, 2 or 3
     * @return the zone ID, not null
     * @throws DateTimeException if the zone ID has an invalid format
     */
    // private static ZoneId ofWithPrefix(string zoneId, int prefixLength, bool checkAvailable) {
    //     string prefix = zoneId.substring(0, prefixLength);
    //     if (zoneId.length == prefixLength) {
    //         return ofOffset(prefix, ZoneOffset.UTC);
    //     }
    //     if (zoneId[prefixLength] != '+' && zoneId[prefixLength] != '-') {
    //         return ZoneRegion.ofId(zoneId, checkAvailable);  // drop through to ZoneRulesProvider
    //     }
    //     try {
    //         ZoneOffset offset = ZoneOffset.of(zoneId.substring(prefixLength));
    //         if (offset == ZoneOffset.UTC) {
    //             return ofOffset(prefix, offset);
    //         }
    //         return ofOffset(prefix, offset);
    //     } catch (DateTimeException ex) {
    //         throw new DateTimeException("Invalid ID for offset-based ZoneId: " ~ zoneId, ex);
    //     }
    // }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code ZoneId} from a temporal object.
     * !(p)
     * This obtains a zone based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code ZoneId}.
     * !(p)
     * A {@code TemporalAccessor} represents some form of date and time information.
     * This factory converts the arbitrary temporal object to an instance of {@code ZoneId}.
     * !(p)
     * The conversion will try to obtain the zone _in a way that favours region-based
     * zones over offset-based zones using {@link TemporalQueries#zone()}.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code ZoneId::from}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the zone ID, not null
     * @throws DateTimeException if unable to convert to a {@code ZoneId}
     */
    static ZoneId from(TemporalAccessor temporal) {
        ZoneId obj =QueryHelper.query!ZoneId(temporal,TemporalQueries.zone());
        if (obj is null) {
            throw new DateTimeException("Unable to obtain ZoneId from TemporalAccessor: " ~
                    typeid(temporal).name ~ " of type " ~ typeid(temporal).stringof);
        }
        return obj;
    }

    //-----------------------------------------------------------------------
    /**
     * Constructor only accessible within the package.
     */
    this() {
        // if (typeid(this).stringof != ZoneOffset.stringof && typeof(this).stringof != ZoneRegion.stringof) {
            // throw new AssertionError("Invalid subclass");
        // }
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the unique time-zone ID.
     * !(p)
     * This ID uniquely defines this object.
     * The format of an offset based ID is defined by {@link ZoneOffset#getId()}.
     *
     * @return the time-zone unique ID, not null
     */
    abstract string getId();

    //-----------------------------------------------------------------------
    /**
     * Gets the textual representation of the zone, such as 'British Time' or
     * '+02:00'.
     * !(p)
     * This returns the textual name used to identify the time-zone ID,
     * suitable for presentation to the user.
     * The parameters control the style of the returned text and the locale.
     * !(p)
     * If no textual mapping is found then the {@link #getId() full ID} is returned.
     *
     * @param style  the length of the text required, not null
     * @param locale  the locale to use, not null
     * @return the text value of the zone, not null
     */
    // string getDisplayName(TextStyle style, Locale locale) {
    //     return new DateTimeFormatterBuilder().appendZoneText(style).toFormatter(locale).format(toTemporal());
    // }

    /**
     * Converts this zone to a {@code TemporalAccessor}.
     * !(p)
     * A {@code ZoneId} can be fully represented as a {@code TemporalAccessor}.
     * However, the interface is not implemented by this class as most of the
     * methods on the interface have no meaning to {@code ZoneId}.
     * !(p)
     * The returned temporal has no supported fields, with the query method
     * supporting the return of the zone using {@link TemporalQueries#zoneId()}.
     *
     * @return a temporal equivalent to this zone, not null
     */
    private TemporalAccessor toTemporal() {
        return new AnonymousClass3();
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the time-zone rules for this ID allowing calculations to be performed.
     * !(p)
     * The rules provide the functionality associated with a time-zone,
     * such as finding the offset for a given instant or local date-time.
     * !(p)
     * A time-zone can be invalid if it is deserialized _in a Java Runtime which
     * does not have the same rules loaded as the Java Runtime that stored it.
     * In this case, calling this method will throw a {@code ZoneRulesException}.
     * !(p)
     * The rules are supplied by {@link ZoneRulesProvider}. An advanced provider may
     * support dynamic updates to the rules without restarting the Java Runtime.
     * If so, then the result of this method may change over time.
     * Each individual call will be still remain thread-safe.
     * !(p)
     * {@link ZoneOffset} will always return a set of rules where the offset never changes.
     *
     * @return the rules, not null
     * @throws ZoneRulesException if no rules are available for this ID
     */
    abstract ZoneRules getRules();

    /**
     * Normalizes the time-zone ID, returning a {@code ZoneOffset} where possible.
     * !(p)
     * The returns a normalized {@code ZoneId} that can be used _in place of this ID.
     * The result will have {@code ZoneRules} equivalent to those returned by this object,
     * however the ID returned by {@code getId()} may be different.
     * !(p)
     * The normalization checks if the rules of this {@code ZoneId} have a fixed offset.
     * If they do, then the {@code ZoneOffset} equal to that offset is returned.
     * Otherwise {@code this} is returned.
     *
     * @return the time-zone unique ID, not null
     */
    ZoneId normalized() {
        try {
            ZoneRules rules = getRules();
            if (rules.isFixedOffset()) {
                return rules.getOffset(Instant.EPOCH);
            }
        } catch (ZoneRulesException ex) {
            // invalid ZoneRegion is not important to this method
        }
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this time-zone ID is equal to another time-zone ID.
     * !(p)
     * The comparison is based on the ID.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other time-zone ID
     */
    override
    bool opEquals(Object obj) {
        if (this is obj) {
           return true;
        }
        if (cast(ZoneId)(obj) !is null) {
            ZoneId other = cast(ZoneId) obj;
            return getId() == (other.getId());
        }
        return false;
    }

    /**
     * A hash code for this time-zone ID.
     *
     * @return a suitable hash code
     */
    override
    size_t toHash() @trusted nothrow {
        try
        {
            return hashOf(getId());
        }
        catch(Exception e){}
        return int.init;
    }

    //-----------------------------------------------------------------------
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

    /**
     * Outputs this zone as a {@code string}, using the ID.
     *
     * @return a string representation of this time-zone ID, not null
     */
    override
    string toString() {
        return getId();
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(7);  // identifies a ZoneId (not ZoneOffset)
     *  _out.writeUTF(getId());
     * </pre>
     * !(p)
     * When read back _in, the {@code ZoneId} will be created as though using
     * {@link #of(string)}, but without any exception _in the case where the
     * ID has a valid format, but is not _in the known set of region-based IDs.
     *
     * @return the instance of {@code Ser}, not null
     */
    // this is here for serialization Javadoc
    // private Object writeReplace() {
    //     return new Ser(Ser.ZONE_REGION_TYPE, this);
    // }

    // abstract void write(DataOutput _out) /*throws IOException*/;
    
    mixin SerializationMember!(typeof(this));

}
