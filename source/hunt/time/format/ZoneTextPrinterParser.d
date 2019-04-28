module hunt.time.format.ZoneTextPrinterParser;

import hunt.time.Instant;
import hunt.time.LocalDate;
import hunt.time.LocalDateTime;
import hunt.time.LocalTime;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.PrefixTree;
import hunt.time.format.TextStyle;
import hunt.time.format.ZoneIdPrinterParser;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.util.Common;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.zone.ZoneRulesProvider;

import hunt.Exceptions;
import hunt.collection.HashMap;
import hunt.collection.HashSet;
import hunt.collection.Map;
import hunt.collection.Set;
import hunt.Integer;
import hunt.text.StringBuilder;
import hunt.util.Locale;

//-----------------------------------------------------------------------
/**
* Prints or parses a zone ID.
*/
static final class ZoneTextPrinterParser : ZoneIdPrinterParser
{

    /** The text style to output. */
    private TextStyle textStyle;

    /** The preferred zoneid map */
    private Set!(string) preferredZones;

    /**  Display _in generic time-zone format. True _in case of pattern letter 'v' */
    private bool isGeneric;

    this(TextStyle textStyle, Set!(ZoneId) preferredZones, bool isGeneric)
    {
        cachedTree = new HashMap!(Locale, MapEntry!(Integer, PrefixTree))();
        cachedTreeCI = new HashMap!(Locale, MapEntry!(Integer, PrefixTree))();
        super(TemporalQueries.zone(), "ZoneText(" ~ textStyle.toString ~ ")");
        this.textStyle = textStyle;
        this.isGeneric = isGeneric;
        if (preferredZones !is null && preferredZones.size() != 0)
        {
            this.preferredZones = new HashSet!(string)();
            foreach (ZoneId id; preferredZones)
            {
                this.preferredZones.add(id.getId());
            }
        }
    }

    private enum int STD = 0;
    private enum int DST = 1;
    private enum int GENERIC = 2;
    // __gshared Map!(string, Map!(Locale, string[])) cache;

    // shared static this()
    // {
    //     cache = new HashMap!(string, Map!(Locale, string[]))();
        mixin(MakeGlobalVar!(Map!(string, Map!(Locale, string[])))("cache",`new HashMap!(string, Map!(Locale, string[]))()`));
    // }

    private string getDisplayName(string id, int type, Locale locale)
    {
        if (textStyle == TextStyle.NARROW)
        {
            return null;
        }
        string[] names;
        Map!(Locale, string[]) _ref = cache.get(id);
        Map!(Locale, string[]) perLocale = null;
        if (_ref is null || (perLocale = _ref) is null
                || (names = perLocale.get(locale)) is null)
        {
            // names = TimeZoneNameUtility.retrieveDisplayNames(id, locale);
            // if (names is null) {
            //     return null;
            // }
            // auto tmp = names[0 .. 7];
            // names = tmp;
            // names[5] =
            //     TimeZoneNameUtility.retrieveGenericDisplayName(id, TimeZone.LONG, locale);
            // if (names[5] is null) {
            //     names[5] = names[0]; // use the id
            // }
            // names[6] =
            //     TimeZoneNameUtility.retrieveGenericDisplayName(id, TimeZone.SHORT, locale);
            // if (names[6] is null) {
            //     names[6] = names[0];
            // }
            // if (perLocale is null) {
            //     perLocale = new HashMap!(Locale, string[])();
            // }
            // perLocale.put(locale, names);
            // cache.put(id, perLocale);
            implementationMissing();

        }
        switch (type)
        {
        case STD:
            return names[textStyle.zoneNameStyleIndex() + 1];
        case DST:
            return names[textStyle.zoneNameStyleIndex() + 3];
        default:
            break;
        }
        return names[textStyle.zoneNameStyleIndex() + 5];
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        ZoneId zone = context.getValue(TemporalQueries.zoneId());
        if (zone is null)
        {
            return false;
        }
        string zname = zone.getId();
        if (!(cast(ZoneOffset)(zone) !is null))
        {
            TemporalAccessor dt = context.getTemporal();
            int type = GENERIC;
            if (!isGeneric)
            {
                if (dt.isSupported(ChronoField.INSTANT_SECONDS))
                {
                    type = zone.getRules().isDaylightSavings(Instant.from(dt)) ? DST : STD;
                }
                else if (dt.isSupported(ChronoField.EPOCH_DAY)
                        && dt.isSupported(ChronoField.NANO_OF_DAY))
                {
                    LocalDate date = LocalDate.ofEpochDay(
                            dt.getLong(ChronoField.EPOCH_DAY));
                    LocalTime time = LocalTime.ofNanoOfDay(
                            dt.getLong(ChronoField.NANO_OF_DAY));
                    LocalDateTime ldt = date.atTime_s(time);
                    if (zone.getRules().getTransition(ldt) is null)
                    {
                        type = zone.getRules().isDaylightSavings(ldt.atZone(zone)
                                .toInstant()) ? DST : STD;
                    }
                }
            }
            string name = getDisplayName(zname, type, context.getLocale());
            if (name !is null)
            {
                zname = name;
            }
        }
        buf.append(zname);
        return true;
    }

    // cache per instance for now
    private Map!(Locale, MapEntry!(Integer, PrefixTree)) cachedTree;
    private Map!(Locale, MapEntry!(Integer, PrefixTree)) cachedTreeCI;

    override protected PrefixTree getTree(DateTimeParseContext context)
    {
        if (textStyle == TextStyle.NARROW)
        {
            return super.getTree(context);
        }
        Locale locale = context.getLocale();
        bool isCaseSensitive = context.isCaseSensitive();
        Set!(string) regionIds = ZoneRulesProvider.getAvailableZoneIds();
        int regionIdsSize = regionIds.size();

        Map!(Locale, MapEntry!(Integer, PrefixTree)) cached = isCaseSensitive ? cachedTree
            : cachedTreeCI;

        MapEntry!(Integer, PrefixTree) entry = null;
        PrefixTree tree = null;
        string[][] zoneStrings = null;
        if ((entry = cached.get(locale)) is null
                || (entry.getKey() != regionIdsSize || (tree = entry.getValue() /* .get() */ ) is null))
        {
            tree = PrefixTree.newTree(context);
            // zoneStrings = TimeZoneNameUtility.getZoneStrings(locale);
            // foreach(string[] names ; zoneStrings) {
            //     string zid = names[0];
            //     if (!regionIds.contains(zid)) {
            //         continue;
            //     }
            //     tree.add(zid, zid);    // don't convert zid -> metazone
            //     zid = ZoneName.toZid(zid, locale);
            //     int i = textStyle == TextStyle.FULL ? 1 : 2;
            //     for (; i < names.length; i += 2) {
            //         tree.add(names[i], zid);
            //     }
            // }

            // // if we have a set of preferred zones, need a copy and
            // // add the preferred zones again to overwrite
            // if (preferredZones !is null) {
            //     foreach(string[] names ; zoneStrings) {
            //         string zid = names[0];
            //         if (!preferredZones.contains(zid) || !regionIds.contains(zid)) {
            //             continue;
            //         }
            //         int i = textStyle == TextStyle.FULL ? 1 : 2;
            //         for (; i < names.length; i += 2) {
            //             tree.add(names[i], zid);
            //        }
            //     }
            // }
            // cached.put(locale, new SimpleImmutableEntry!(Integer, PrefixTree)(new Integer(regionIdsSize), tree));
            

        }

        implementationMissing(false);
        return tree;
    }
}