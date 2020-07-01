module hunt.time.format.LocalizedPrinterParser;

import hunt.time.chrono.Chronology;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.format.DateTimeFormatter;
import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.FormatStyle;
import hunt.time.temporal.TemporalField;
import hunt.time.util.Common;
// import hunt.time.util.Locale;
import hunt.util.StringBuilder;

import hunt.collection.HashMap;
import hunt.collection.Map;
import hunt.Exceptions;
import hunt.util.Locale;

import std.concurrency : initOnce;

//-----------------------------------------------------------------------
/**
* Prints or parses a localized pattern.
*/
final class LocalizedPrinterParser : DateTimePrinterParser
{
    /** Cache of formatters. */
    static Map!(string, DateTimeFormatter) FORMATTER_CACHE() {
        __gshared Map!(string, DateTimeFormatter) inst;
        return initOnce!(inst)(
                new HashMap!(string, DateTimeFormatter)(16, 0.75f /* , 2 */ ));
    }

    private FormatStyle dateStyle;
    private FormatStyle timeStyle;

    /**
     * Constructor.
     *
     * @param dateStyle  the date style to use, may be null
     * @param timeStyle  the time style to use, may be null
     */
    this(FormatStyle dateStyle, FormatStyle timeStyle)
    {
        // validated by caller
        this.dateStyle = dateStyle;
        this.timeStyle = timeStyle;
    }

    override bool format(DateTimePrintContext context, StringBuilder buf)
    {
        Chronology chrono = Chronology.from(context.getTemporal());
        return formatter(context.getLocale(), chrono).toPrinterParser(false)
            .format(context, buf);
    }

    override int parse(DateTimeParseContext context, string text, int position)
    {
        Chronology chrono = context.getEffectiveChronology();
        return formatter(context.getLocale(), chrono).toPrinterParser(false)
            .parse(context, text, position);
    }

    /**
     * Gets the formatter to use.
     * !(p)
     * The formatter will be the most appropriate to use for the date and time style _in the locale.
     * For example, some locales will use the month name while others will use the number.
     *
     * @param locale  the locale to use, not null
     * @param chrono  the chronology to use, not null
     * @return the formatter, not null
     * @throws IllegalArgumentException if the formatter cannot be found
     */
    private DateTimeFormatter formatter(Locale locale, Chronology chrono)
    {
        string key = chrono.getId() ~ '|' ~ locale.toString() ~ '|' ~ dateStyle.name() ~ timeStyle.name();
        DateTimeFormatter formatter = FORMATTER_CACHE.get(key);
        if (formatter is null) {
            string pattern = getLocalizedDateTimePattern(dateStyle,
                    timeStyle, chrono, locale);
            formatter = new DateTimeFormatterBuilder().appendPattern(pattern)
                .toFormatter(locale);
            DateTimeFormatter old = FORMATTER_CACHE.putIfAbsent(key, formatter);
            if (old !is null) {
                formatter = old;
            }
        }
        return formatter;
        // implementationMissing(false);
        // return null;
    }

    
    /**
     * Gets the formatting pattern for date and time styles for a locale and chronology.
     * The locale and chronology are used to lookup the locale specific format
     * for the requested dateStyle and/or timeStyle.
     * !(p)
     * If the locale contains the "rg" (region override)
     * <a href="../../util/Locale.html#def_locale_extension">Unicode extensions</a>,
     * the formatting pattern is overridden with the one appropriate for the region.
     *
     * @param dateStyle  the FormatStyle for the date, null for time-only pattern
     * @param timeStyle  the FormatStyle for the time, null for date-only pattern
     * @param chrono  the Chronology, non-null
     * @param locale  the locale, non-null
     * @return the locale and Chronology specific formatting pattern
     * @throws IllegalArgumentException if both dateStyle and timeStyle are null
     */
    static string getLocalizedDateTimePattern(FormatStyle dateStyle,
            FormatStyle timeStyle, Chronology chrono, Locale locale) {
        // assert(locale, "locale");
        // assert(chrono, "chrono");
        // if (dateStyle is null && timeStyle is null) {
        //     throw new IllegalArgumentException("Either dateStyle or timeStyle must be non-null");
        // }
        // LocaleProviderAdapter adapter = LocaleProviderAdapter.getAdapter(JavaTimeDateTimePatternProvider.class, locale);
        // JavaTimeDateTimePatternProvider provider = adapter.getJavaTimeDateTimePatternProvider();
        // string pattern = provider.getJavaTimeDateTimePattern(convertStyle(timeStyle),
        //                  convertStyle(dateStyle), chrono.getCalendarType(),
        //                  CalendarDataUtility.findRegionOverride(locale));
        // return pattern;
        implementationMissing(false);
        return null;
    }

    override string toString()
    {
        return "Localized(" ~ (dateStyle !is null ? dateStyle.name()
                : "") ~ "," ~ (timeStyle !is null ? timeStyle.name() : "") ~ ")";
    }
}