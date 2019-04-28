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

module hunt.time.format.DateTimeFormatterBuilder;

import hunt.time.format.NumberPrinterParser;
import hunt.time.format.OffsetIdPrinterParser;

import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.ChronoLocalDateTime;
import hunt.time.chrono.Chronology;
import hunt.time.chrono.IsoChronology;

import hunt.time.format.CharLiteralPrinterParser;
import hunt.time.format.ChronoPrinterParser;
import hunt.time.format.CompositePrinterParser;
import hunt.time.format.DateTimeFormatter;
import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimeTextProvider;
import hunt.time.format.DecimalStyle;
import hunt.time.format.InstantPrinterParser;
import hunt.time.format.FractionPrinterParser;
import hunt.time.format.FormatStyle;
import hunt.time.format.LocalizedOffsetIdPrinterParser;
import hunt.time.format.LocalizedPrinterParser;
import hunt.time.format.NumberPrinterParser;
import hunt.time.format.PadPrinterParserDecorator;
import hunt.time.format.ReducedPrinterParser;
import hunt.time.format.ResolverStyle;
import hunt.time.format.SettingsParser;
import hunt.time.format.SignStyle;
import hunt.time.format.StringLiteralPrinterParser;
import hunt.time.format.TextPrinterParser;
import hunt.time.format.TextStyle;
import hunt.time.format.WeekBasedFieldPrinterParser;
import hunt.time.format.ZoneIdPrinterParser;
import hunt.time.format.ZoneTextPrinterParser;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.TemporalQueries;

import hunt.time.util.Common;
import hunt.time.util.QueryHelper;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;

import hunt.collection.ArrayList;
import hunt.collection.HashMap;
import hunt.collection.Iterator;
import hunt.collection.List;
import hunt.collection.LinkedHashMap;
import hunt.collection.Map;
import hunt.collection.Set;
import hunt.Exceptions;
import hunt.Long;
import hunt.text.Common;
import hunt.text.StringBuilder;
import hunt.util.Common;
import hunt.util.Comparator;
import hunt.util.Locale;

import std.conv;
import std.concurrency : initOnce;
import hunt.time.temporal.IsoFields;


/**
 * Builder to create date-time formatters.
 * !(p)
 * This allows a {@code DateTimeFormatter} to be created.
 * All date-time formatters are created ultimately using this builder.
 * !(p)
 * The basic elements of date-time can all be added:
 * !(ul)
 * !(li)Value - a numeric value</li>
 * !(li)Fraction - a fractional value including the decimal place. Always use this when
 * outputting fractions to ensure that the fraction is parsed correctly</li>
 * !(li)Text - the textual equivalent for the value</li>
 * !(li)OffsetId/Offset - the {@linkplain ZoneOffset zone offset}</li>
 * !(li)ZoneId - the {@linkplain ZoneId time-zone} id</li>
 * !(li)ZoneText - the name of the time-zone</li>
 * !(li)ChronologyId - the {@linkplain Chronology chronology} id</li>
 * !(li)ChronologyText - the name of the chronology</li>
 * !(li)Literal - a text literal</li>
 * !(li)Nested and Optional - formats can be nested or made optional</li>
 * </ul>
 * In addition, any of the elements may be decorated by padding, either with spaces or any other character.
 * !(p)
 * Finally, a shorthand pattern, mostly compatible with {@code java.text.SimpleDateFormat SimpleDateFormat}
 * can be used, see {@link #appendPattern(string)}.
 * In practice, this simply parses the pattern and calls other methods on the builder.
 *
 * @implSpec
 * This class is a mutable builder intended for use from a single thread.
 *
 * @since 1.8
 */
public final class DateTimeFormatterBuilder {

// dfmt off
    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses a date without an
     * offset, such as '2011-12-03'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended local date format.
     * The format consists of:
     * !(ul)
     * !(li)Four digits or more for the {@link ChronoField#YEAR year}.
     * Years _in the range 0000 to 9999 will be pre-padded by zero to ensure four digits.
     * Years outside that range will have a prefixed positive or negative symbol.
     * !(li)A dash
     * !(li)Two digits for the {@link ChronoField#MONTH_OF_YEAR month-of-year}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)A dash
     * !(li)Two digits for the {@link ChronoField#DAY_OF_MONTH day-of-month}.
     *  This is pre-padded by zero to ensure two digits.
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_LOCAL_DATE() {
        __gshared DateTimeFormatter _ISO_LOCAL_DATE ;
        return initOnce!(_ISO_LOCAL_DATE)({
            return new DateTimeFormatterBuilder()
                .appendValue(ChronoField.YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
                .appendLiteral('-')
                .appendValue(ChronoField.MONTH_OF_YEAR, 2)
                .appendLiteral('-')
                .appendValue(ChronoField.DAY_OF_MONTH, 2)
                .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }
  
    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses a date with an
     * offset, such as '2011-12-03+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset date format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE}
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_OFFSET_DATE() {
        __gshared DateTimeFormatter _ISO_OFFSET_DATE ;
        return initOnce!(_ISO_OFFSET_DATE)({
            return new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .append(ISO_LOCAL_DATE())
            .appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }
 
    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses a date with the
     * offset if available, such as '2011-12-03' or '2011-12-03+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended date format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE}
     * !(li)If the offset is not available then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_DATE() {
        __gshared DateTimeFormatter _ISO_DATE ;
        return initOnce!(_ISO_DATE)({
            return new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .append(ISO_LOCAL_DATE())
            .optionalStart()
            .appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }    
    

    //-----------------------------------------------------------------------
    /**
     * The ISO time formatter that formats or parses a time without an
     * offset, such as '10:15' or '10:15:30'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended local time format.
     * The format consists of:
     * !(ul)
     * !(li)Two digits for the {@link ChronoField#HOUR_OF_DAY hour-of-day}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)A colon
     * !(li)Two digits for the {@link ChronoField#MINUTE_OF_HOUR minute-of-hour}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)If the second-of-minute is not available then the format is complete.
     * !(li)A colon
     * !(li)Two digits for the {@link ChronoField#SECOND_OF_MINUTE second-of-minute}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)If the nano-of-second is zero or not available then the format is complete.
     * !(li)A decimal point
     * !(li)One to nine digits for the {@link ChronoField#NANO_OF_SECOND nano-of-second}.
     *  As many digits will be output as required.
     * </ul>
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_LOCAL_TIME() {
        __gshared DateTimeFormatter _ISO_LOCAL_TIME ;
        return initOnce!(_ISO_LOCAL_TIME)({
            return new DateTimeFormatterBuilder()
            .appendValue(ChronoField.HOUR_OF_DAY, 2)
            .appendLiteral(':')
            .appendValue(ChronoField.MINUTE_OF_HOUR, 2)
            .optionalStart()
            .appendLiteral(':')
            .appendValue(ChronoField.SECOND_OF_MINUTE, 2)
            .optionalStart()
            .appendFraction(ChronoField.NANO_OF_SECOND, 0, 9, true)
            .toFormatter(ResolverStyle.STRICT, null);
        }());
    }
    
    //-----------------------------------------------------------------------
    /**
     * The ISO time formatter that formats or parses a time with an
     * offset, such as '10:15+01:00' or '10:15:30+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset time format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_TIME}
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_OFFSET_TIME() {
        __gshared DateTimeFormatter _ISO_OFFSET_TIME ;
        return initOnce!(_ISO_OFFSET_TIME)({
            return new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .append(ISO_LOCAL_TIME())
            .appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, null);
        }());
    }
    

    //-----------------------------------------------------------------------
    /**
     * The ISO time formatter that formats or parses a time, with the
     * offset if available, such as '10:15', '10:15:30' or '10:15:30+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset time format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_TIME}
     * !(li)If the offset is not available then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_TIME() {
        __gshared DateTimeFormatter _ISO_TIME ;
        return initOnce!(_ISO_TIME)({
            return new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .append(ISO_LOCAL_TIME())
            .optionalStart()
            .appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, null);
        }());
    }
    
    //-----------------------------------------------------------------------
    /**
     * The ISO date-time formatter that formats or parses a date-time without
     * an offset, such as '2011-12-03T10:15:30'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset date-time format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE}
     * !(li)The letter 'T'. Parsing is case insensitive.
     * !(li)The {@link #ISO_LOCAL_TIME}
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_LOCAL_DATE_TIME() {
        __gshared DateTimeFormatter _ISO_LOCAL_DATE_TIME ;
        return initOnce!(_ISO_LOCAL_DATE_TIME)({
            return new DateTimeFormatterBuilder()
                .parseCaseInsensitive()
                .append(ISO_LOCAL_DATE())
                .appendLiteral('T')
                .append(ISO_LOCAL_DATE())
                .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }
 

    //-----------------------------------------------------------------------
    /**
     * The ISO date-time formatter that formats or parses a date-time with an
     * offset, such as '2011-12-03T10:15:30+01:00'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended offset date-time format.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE_TIME}
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  The offset parsing is lenient, which allows the minutes and seconds to be optional.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_OFFSET_DATE_TIME() {
        __gshared DateTimeFormatter _ISO_OFFSET_DATE_TIME ;
        return initOnce!(_ISO_OFFSET_DATE_TIME)({
            return new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .append(ISO_LOCAL_DATE_TIME())
            .parseLenient()
            .appendOffsetId()
            .parseStrict()
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }


    //-----------------------------------------------------------------------
    /**
     * The ISO-like date-time formatter that formats or parses a date-time with
     * offset and zone, such as '2011-12-03T10:15:30+01:00[Europe/Paris]'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * a format that extends the ISO-8601 extended offset date-time format
     * to add the time-zone.
     * The section _in square brackets is not part of the ISO-8601 standard.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_OFFSET_DATE_TIME}
     * !(li)If the zone ID is not available or is a {@code ZoneOffset} then the format is complete.
     * !(li)An open square bracket '['.
     * !(li)The {@link ZoneId#getId() zone ID}. This is not part of the ISO-8601 standard.
     *  Parsing is case sensitive.
     * !(li)A close square bracket ']'.
     * </ul>
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_ZONED_DATE_TIME() {
        __gshared DateTimeFormatter _ISO_ZONED_DATE_TIME ;
        return initOnce!(_ISO_ZONED_DATE_TIME)({
            return new DateTimeFormatterBuilder()
            .append(ISO_OFFSET_DATE_TIME())
            .optionalStart()
            .appendLiteral('[')
            .parseCaseSensitive()
            .appendZoneRegionId()
            .appendLiteral(']')
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }

    //-----------------------------------------------------------------------
    /**
     * The ISO-like date-time formatter that formats or parses a date-time with
     * the offset and zone if available, such as '2011-12-03T10:15:30',
     * '2011-12-03T10:15:30+01:00' or '2011-12-03T10:15:30+01:00[Europe/Paris]'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended local or offset date-time format, as well as the
     * extended non-ISO form specifying the time-zone.
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_LOCAL_DATE_TIME}
     * !(li)If the offset is not available to format or parse then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     * !(li)If the zone ID is not available or is a {@code ZoneOffset} then the format is complete.
     * !(li)An open square bracket '['.
     * !(li)The {@link ZoneId#getId() zone ID}. This is not part of the ISO-8601 standard.
     *  Parsing is case sensitive.
     * !(li)A close square bracket ']'.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_DATE_TIME() {
        __gshared DateTimeFormatter _ISO_DATE_TIME ;
        return initOnce!(_ISO_DATE_TIME)({
            return new DateTimeFormatterBuilder()
            .append(ISO_LOCAL_DATE_TIME())
            .optionalStart()
            .appendOffsetId()
            .optionalStart()
            .appendLiteral('[')
            .parseCaseSensitive()
            .appendZoneRegionId()
            .appendLiteral(']')
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }


    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses the ordinal date
     * without an offset, such as '2012-337'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended ordinal date format.
     * The format consists of:
     * !(ul)
     * !(li)Four digits or more for the {@link ChronoField#YEAR year}.
     * Years _in the range 0000 to 9999 will be pre-padded by zero to ensure four digits.
     * Years outside that range will have a prefixed positive or negative symbol.
     * !(li)A dash
     * !(li)Three digits for the {@link ChronoField#DAY_OF_YEAR day-of-year}.
     *  This is pre-padded by zero to ensure three digits.
     * !(li)If the offset is not available to format or parse then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_ORDINAL_DATE() {
        __gshared DateTimeFormatter _ISO_ORDINAL_DATE ;
        return initOnce!(_ISO_ORDINAL_DATE)({
            return new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .appendValue(ChronoField.YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
            .appendLiteral('-')
            .appendValue(ChronoField.DAY_OF_YEAR, 3)
            .optionalStart()
            .appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }

    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses the week-based date
     * without an offset, such as '2012-W48-6'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 extended week-based date format.
     * The format consists of:
     * !(ul)
     * !(li)Four digits or more for the {@link IsoFields#WEEK_BASED_YEAR week-based-year}.
     * Years _in the range 0000 to 9999 will be pre-padded by zero to ensure four digits.
     * Years outside that range will have a prefixed positive or negative symbol.
     * !(li)A dash
     * !(li)The letter 'W'. Parsing is case insensitive.
     * !(li)Two digits for the {@link IsoFields#WEEK_OF_WEEK_BASED_YEAR week-of-week-based-year}.
     *  This is pre-padded by zero to ensure three digits.
     * !(li)A dash
     * !(li)One digit for the {@link ChronoField#DAY_OF_WEEK day-of-week}.
     *  The value run from Monday (1) to Sunday (7).
     * !(li)If the offset is not available to format or parse then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID}. If the offset has seconds then
     *  they will be handled even though this is not part of the ISO-8601 standard.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_WEEK_DATE() {
        __gshared DateTimeFormatter _ISO_WEEK_DATE ;
        return initOnce!(_ISO_WEEK_DATE)({
            return new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .appendValue(IsoFields.WEEK_BASED_YEAR, 4, 10, SignStyle.EXCEEDS_PAD)
            .appendLiteral("-W")
            .appendValue(IsoFields.WEEK_OF_WEEK_BASED_YEAR, 2)
            .appendLiteral('-')
            .appendValue(ChronoField.DAY_OF_WEEK, 1)
            .optionalStart()
            .appendOffsetId()
            .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }


    //-----------------------------------------------------------------------
    /**
     * The ISO instant formatter that formats or parses an instant _in UTC,
     * such as '2011-12-03T10:15:30Z'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 instant format.
     * When formatting, the instant will always be suffixed by 'Z' to indicate UTC.
     * The second-of-minute is always output.
     * The nano-of-second outputs zero, three, six or nine digits as necessary.
     * When parsing, the behaviour of {@link DateTimeFormatterBuilder#appendOffsetId()}
     * will be used to parse the offset, converting the instant to UTC as necessary.
     * The time to at least the seconds field is required.
     * Fractional seconds from zero to nine are parsed.
     * The localized decimal style is not used.
     * !(p)
     * This is a special case formatter intended to allow a human readable form
     * of an {@link hunt.time.Instant}. The {@code Instant} class is designed to
     * only represent a point _in time and internally stores a value _in nanoseconds
     * from a fixed epoch of 1970-01-01Z. As such, an {@code Instant} cannot be
     * formatted as a date or time without providing some form of time-zone.
     * This formatter allows the {@code Instant} to be formatted, by providing
     * a suitable conversion using {@code ZoneOffset.UTC}.
     * !(p)
     * The format consists of:
     * !(ul)
     * !(li)The {@link #ISO_OFFSET_DATE_TIME} where the instant is converted from
     *  {@link ChronoField#INSTANT_SECONDS} and {@link ChronoField#NANO_OF_SECOND}
     *  using the {@code UTC} offset. Parsing is case insensitive.
     * </ul>
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter ISO_INSTANT() {
        __gshared DateTimeFormatter _ISO_INSTANT ;
        return initOnce!(_ISO_INSTANT)({
            return new DateTimeFormatterBuilder()
                .parseCaseInsensitive()
                .appendInstant()
                .toFormatter(ResolverStyle.STRICT, null);
        }());
    }

    //-----------------------------------------------------------------------
    /**
     * The ISO date formatter that formats or parses a date without an
     * offset, such as '20111203'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * the ISO-8601 basic local date format.
     * The format consists of:
     * !(ul)
     * !(li)Four digits for the {@link ChronoField#YEAR year}.
     *  Only years _in the range 0000 to 9999 are supported.
     * !(li)Two digits for the {@link ChronoField#MONTH_OF_YEAR month-of-year}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)Two digits for the {@link ChronoField#DAY_OF_MONTH day-of-month}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)If the offset is not available to format or parse then the format is complete.
     * !(li)The {@link ZoneOffset#getId() offset ID} without colons. If the offset has
     *  seconds then they will be handled even though this is not part of the ISO-8601 standard.
     *  The offset parsing is lenient, which allows the minutes and seconds to be optional.
     *  Parsing is case insensitive.
     * </ul>
     * !(p)
     * As this formatter has an optional element, it may be necessary to parse using
     * {@link DateTimeFormatter#parseBest}.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#STRICT STRICT} resolver style.
     */
    static DateTimeFormatter BASIC_ISO_DATE() {
        __gshared DateTimeFormatter _BASIC_ISO_DATE ;
        return initOnce!(_BASIC_ISO_DATE)({
            return new DateTimeFormatterBuilder()
                .parseCaseInsensitive()
                .appendValue(ChronoField.YEAR, 4)
                .appendValue(ChronoField.MONTH_OF_YEAR, 2)
                .appendValue(ChronoField.DAY_OF_MONTH, 2)
                .optionalStart()
                .parseLenient()
                .appendOffset("+HHMMss", "Z")
                .parseStrict()
                .toFormatter(ResolverStyle.STRICT, IsoChronology.INSTANCE);
        }());
    }

    //-----------------------------------------------------------------------
    /**
     * The RFC-1123 date-time formatter, such as 'Tue, 3 Jun 2008 11:05:30 GMT'.
     * !(p)
     * This returns an immutable formatter capable of formatting and parsing
     * most of the RFC-1123 format.
     * RFC-1123 updates RFC-822 changing the year from two digits to four.
     * This implementation requires a four digit year.
     * This implementation also does not handle North American or military zone
     * names, only 'GMT' and offset amounts.
     * !(p)
     * The format consists of:
     * !(ul)
     * !(li)If the day-of-week is not available to format or parse then jump to day-of-month.
     * !(li)Three letter {@link ChronoField#DAY_OF_WEEK day-of-week} _in English.
     * !(li)A comma
     * !(li)A space
     * !(li)One or two digits for the {@link ChronoField#DAY_OF_MONTH day-of-month}.
     * !(li)A space
     * !(li)Three letter {@link ChronoField#MONTH_OF_YEAR month-of-year} _in English.
     * !(li)A space
     * !(li)Four digits for the {@link ChronoField#YEAR year}.
     *  Only years _in the range 0000 to 9999 are supported.
     * !(li)A space
     * !(li)Two digits for the {@link ChronoField#HOUR_OF_DAY hour-of-day}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)A colon
     * !(li)Two digits for the {@link ChronoField#MINUTE_OF_HOUR minute-of-hour}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)If the second-of-minute is not available then jump to the next space.
     * !(li)A colon
     * !(li)Two digits for the {@link ChronoField#SECOND_OF_MINUTE second-of-minute}.
     *  This is pre-padded by zero to ensure two digits.
     * !(li)A space
     * !(li)The {@link ZoneOffset#getId() offset ID} without colons or seconds.
     *  An offset of zero uses "GMT". North American zone names and military zone names are not handled.
     * </ul>
     * !(p)
     * Parsing is case insensitive.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     */
    static DateTimeFormatter RFC_1123_DATE_TIME() {
        __gshared DateTimeFormatter _RFC_1123_DATE_TIME ;
        return initOnce!(_RFC_1123_DATE_TIME)({
            // manually code maps to ensure correct data always used
            // (locale data can be changed by application code)
            Map!(Long, string) dow = new HashMap!(Long, string)();
            dow.put(new Long(1L), "Mon");
            dow.put(new Long(2L), "Tue");
            dow.put(new Long(3L), "Wed");
            dow.put(new Long(4L), "Thu");
            dow.put(new Long(5L), "Fri");
            dow.put(new Long(6L), "Sat");
            dow.put(new Long(7L), "Sun");
            Map!(Long, string) moy = new HashMap!(Long, string)();
            moy.put(new Long(1L), "Jan");
            moy.put(new Long(2L), "Feb");
            moy.put(new Long(3L), "Mar");
            moy.put(new Long(4L), "Apr");
            moy.put(new Long(5L), "May");
            moy.put(new Long(6L), "Jun");
            moy.put(new Long(7L), "Jul");
            moy.put(new Long(8L), "Aug");
            moy.put(new Long(9L), "Sep");
            moy.put(new Long(10L), "Oct");
            moy.put(new Long(11L), "Nov");
            moy.put(new Long(12L), "Dec");

            return new DateTimeFormatterBuilder()
                .parseCaseInsensitive()
                .parseLenient()
                .optionalStart()
                .appendText(ChronoField.DAY_OF_WEEK, dow)
                .appendLiteral(", ")
                .optionalEnd()
                .appendValue(ChronoField.DAY_OF_MONTH, 1, 2, SignStyle.NOT_NEGATIVE)
                .appendLiteral(' ')
                .appendText(ChronoField.MONTH_OF_YEAR, moy)
                .appendLiteral(' ')
                .appendValue(ChronoField.YEAR, 4)  // 2 digit year not handled
                .appendLiteral(' ')
                .appendValue(ChronoField.HOUR_OF_DAY, 2)
                .appendLiteral(':')
                .appendValue(ChronoField.MINUTE_OF_HOUR, 2)
                .optionalStart()
                .appendLiteral(':')
                .appendValue(ChronoField.SECOND_OF_MINUTE, 2)
                .optionalEnd()
                .appendLiteral(' ')
                .appendOffset("+HHMM", "GMT")  // should handle UT/Z/EST/EDT/CST/CDT/MST/MDT/PST/MDT
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
        }());
    }

    /**
     * Query for a time-zone that is region-only.
     */
    static TemporalQuery!(ZoneId) QUERY_REGION_ONLY() {
        __gshared TemporalQuery!(ZoneId) _QUERY_REGION_ONLY;
        return initOnce!(_QUERY_REGION_ONLY)({
            return new class TemporalQuery!(ZoneId)  {
            ZoneId queryFrom(TemporalAccessor temporal){
                ZoneId zone = QueryHelper.query!ZoneId(temporal ,TemporalQueries.zoneId());
                return (zone !is null && (cast(ZoneOffset)(zone) !is null) == false ? zone : null);
            }
        };
        }());
    }

// dfmt on

    /**
     * The currently active builder, used by the outermost builder.
     */
    private DateTimeFormatterBuilder _active;
    // alias active = this;

    DateTimeFormatterBuilder active() @trusted nothrow
    {
        if (_active is null)
            return this;
        else
            return _active;
    }
    /**
     * The parent builder, null for the outermost builder.
     */
    private DateTimeFormatterBuilder parent;
    /**
     * The list of printers that will be used.
     */
    private List!(DateTimePrinterParser) printerParsers;
    /**
     * Whether this builder produces an optional formatter.
     */
    private bool optional;
    /**
     * The width to pad the next field to.
     */
    private int padNextWidth;
    /**
     * The character to pad the next field with.
     */
    private char padNextChar;
    /**
     * The index of the last variable width value parser.
     */
    private int valueParserIndex = -1;

    
    /**
     * Creates a formatter using the specified pattern.
     * !(p)
     * This method will create a formatter based on a simple
     * <a href="#patterns">pattern of letters and symbols</a>
     * as described _in the class documentation.
     * For example, {@code d MMM uuuu} will format 2011-12-03 as '3 Dec 2011'.
     * !(p)
     * The formatter will use the {@link Locale#getDefault(Locale.Category) default FORMAT locale}.
     * This can be changed using {@link DateTimeFormatter#withLocale(Locale)} on the returned formatter.
     * Alternatively use the {@link #ofPattern(string, Locale)} variant of this method.
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses {@link ResolverStyle#SMART SMART} resolver style.
     *
     * @param pattern  the pattern to use, not null
     * @return the formatter based on the pattern, not null
     * @throws IllegalArgumentException if the pattern is invalid
     * @see DateTimeFormatterBuilder#appendPattern(string)
     */
    public static DateTimeFormatter ofPattern(string pattern) {
        return new DateTimeFormatterBuilder().appendPattern(pattern).toFormatter();
    }

    /**
     * Creates a formatter using the specified pattern and locale.
     * !(p)
     * This method will create a formatter based on a simple
     * <a href="#patterns">pattern of letters and symbols</a>
     * as described _in the class documentation.
     * For example, {@code d MMM uuuu} will format 2011-12-03 as '3 Dec 2011'.
     * !(p)
     * The formatter will use the specified locale.
     * This can be changed using {@link DateTimeFormatter#withLocale(Locale)} on the returned formatter.
     * !(p)
     * The returned formatter has no override chronology or zone.
     * It uses {@link ResolverStyle#SMART SMART} resolver style.
     *
     * @param pattern  the pattern to use, not null
     * @param locale  the locale to use, not null
     * @return the formatter based on the pattern, not null
     * @throws IllegalArgumentException if the pattern is invalid
     * @see DateTimeFormatterBuilder#appendPattern(string)
     */
    public static DateTimeFormatter ofPattern(string pattern, Locale locale) {
        return new DateTimeFormatterBuilder().appendPattern(pattern).toFormatter(locale);
    }
    

    /**
     * Returns a locale specific date-time formatter for the ISO chronology.
     * !(p)
     * This returns a formatter that will format or parse a date-time.
     * The exact format pattern used varies by locale.
     * !(p)
     * The locale is determined from the formatter. The formatter returned directly by
     * this method will use the {@link Locale#getDefault(Locale.Category) default FORMAT locale}.
     * The locale can be controlled using {@link DateTimeFormatter#withLocale(Locale) withLocale(Locale)}
     * on the result of this method.
     * !(p)
     * Note that the localized pattern is looked up lazily.
     * This {@code DateTimeFormatter} holds the style required and the locale,
     * looking up the pattern required on demand.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     * The {@code FULL} and {@code LONG} styles typically require a time-zone.
     * When formatting using these styles, a {@code ZoneId} must be available,
     * either by using {@code ZonedDateTime} or {@link DateTimeFormatter#withZone}.
     *
     * @param dateTimeStyle  the formatter style to obtain, not null
     * @return the date-time formatter, not null
     */
    public static DateTimeFormatter ofLocalizedDateTime(FormatStyle dateTimeStyle) {
        assert(dateTimeStyle, "dateTimeStyle");
        return new DateTimeFormatterBuilder().appendLocalized(dateTimeStyle, dateTimeStyle)
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    }

    /**
     * Returns a locale specific date and time format for the ISO chronology.
     * !(p)
     * This returns a formatter that will format or parse a date-time.
     * The exact format pattern used varies by locale.
     * !(p)
     * The locale is determined from the formatter. The formatter returned directly by
     * this method will use the {@link Locale#getDefault() default FORMAT locale}.
     * The locale can be controlled using {@link DateTimeFormatter#withLocale(Locale) withLocale(Locale)}
     * on the result of this method.
     * !(p)
     * Note that the localized pattern is looked up lazily.
     * This {@code DateTimeFormatter} holds the style required and the locale,
     * looking up the pattern required on demand.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     * The {@code FULL} and {@code LONG} styles typically require a time-zone.
     * When formatting using these styles, a {@code ZoneId} must be available,
     * either by using {@code ZonedDateTime} or {@link DateTimeFormatter#withZone}.
     *
     * @param dateStyle  the date formatter style to obtain, not null
     * @param timeStyle  the time formatter style to obtain, not null
     * @return the date, time or date-time formatter, not null
     */
    public static DateTimeFormatter ofLocalizedDateTime(FormatStyle dateStyle, FormatStyle timeStyle) {
        assert(dateStyle, "dateStyle");
        assert(timeStyle, "timeStyle");
        return new DateTimeFormatterBuilder().appendLocalized(dateStyle, timeStyle)
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    }

    /**
     * Returns a locale specific time format for the ISO chronology.
     * !(p)
     * This returns a formatter that will format or parse a time.
     * The exact format pattern used varies by locale.
     * !(p)
     * The locale is determined from the formatter. The formatter returned directly by
     * this method will use the {@link Locale#getDefault(Locale.Category) default FORMAT locale}.
     * The locale can be controlled using {@link DateTimeFormatter#withLocale(Locale) withLocale(Locale)}
     * on the result of this method.
     * !(p)
     * Note that the localized pattern is looked up lazily.
     * This {@code DateTimeFormatter} holds the style required and the locale,
     * looking up the pattern required on demand.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     * The {@code FULL} and {@code LONG} styles typically require a time-zone.
     * When formatting using these styles, a {@code ZoneId} must be available,
     * either by using {@code ZonedDateTime} or {@link DateTimeFormatter#withZone}.
     *
     * @param timeStyle  the formatter style to obtain, not null
     * @return the time formatter, not null
     */
    public static DateTimeFormatter ofLocalizedTime(FormatStyle timeStyle) {
        assert(timeStyle, "timeStyle");
        return new DateTimeFormatterBuilder().appendLocalized(null, timeStyle)
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a locale specific date format for the ISO chronology.
     * !(p)
     * This returns a formatter that will format or parse a date.
     * The exact format pattern used varies by locale.
     * !(p)
     * The locale is determined from the formatter. The formatter returned directly by
     * this method will use the {@link Locale#getDefault(Locale.Category) default FORMAT locale}.
     * The locale can be controlled using {@link DateTimeFormatter#withLocale(Locale) withLocale(Locale)}
     * on the result of this method.
     * !(p)
     * Note that the localized pattern is looked up lazily.
     * This {@code DateTimeFormatter} holds the style required and the locale,
     * looking up the pattern required on demand.
     * !(p)
     * The returned formatter has a chronology of ISO set to ensure dates _in
     * other calendar systems are correctly converted.
     * It has no override zone and uses the {@link ResolverStyle#SMART SMART} resolver style.
     *
     * @param dateStyle  the formatter style to obtain, not null
     * @return the date formatter, not null
     */
    public static DateTimeFormatter ofLocalizedDate(FormatStyle dateStyle) {
        assert(dateStyle, "dateStyle");
        return new DateTimeFormatterBuilder().appendLocalized(dateStyle, null)
                .toFormatter(ResolverStyle.SMART, IsoChronology.INSTANCE);
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
     // using LocalizedPrinterParser.getLocalizedDateTimePattern
    public static string getLocalizedDateTimePattern(FormatStyle dateStyle,
            FormatStyle timeStyle, Chronology chrono, Locale locale)
    {
        // 
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

    /**
     * Converts the given FormatStyle to the java.text.DateFormat style.
     *
     * @param style  the FormatStyle style
     * @return the int style, or -1 if style is null, indicating un-required
     */
    private static int convertStyle(FormatStyle style)
    {
        if (style is null)
        {
            return -1;
        }
        return style.ordinal(); // indices happen to align
    }

    /**
     * Constructs a new instance of the builder.
     */
    public this()
    {
        // super();
        printerParsers = new ArrayList!(DateTimePrinterParser)();
        parent = null;
        optional = false;
    }

    /**
     * Constructs a new instance of the builder.
     *
     * @param parent  the parent builder, not null
     * @param optional  whether the formatter is optional, not null
     */
    private this(DateTimeFormatterBuilder parent, bool optional)
    {
        // super();
        printerParsers = new ArrayList!(DateTimePrinterParser)();
        this.parent = parent;
        this.optional = optional;
    }

    // void opAssign(DateTimeFormatterBuilder other)
    // {
    //     this.parent = other.parent;
    //     this.optional = other.optional;
    //     this.printerParsers = other.printerParsers;
    //     this.padNextWidth = other.padNextWidth;
    //     this.padNextChar = other.padNextChar;
    //     this.valueParserIndex = other.valueParserIndex;
    // }

    //-----------------------------------------------------------------------
    /**
     * Changes the parse style to be case sensitive for the remainder of the formatter.
     * !(p)
     * Parsing can be case sensitive or insensitive - by default it is case sensitive.
     * This method allows the case sensitivity setting of parsing to be changed.
     * !(p)
     * Calling this method changes the state of the builder such that all
     * subsequent builder method calls will parse text _in case sensitive mode.
     * See {@link #parseCaseInsensitive} for the opposite setting.
     * The parse case sensitive/insensitive methods may be called at any point
     * _in the builder, thus the parser can swap between case parsing modes
     * multiple times during the parse.
     * !(p)
     * Since the default is case sensitive, this method should only be used after
     * a previous call to {@code #parseCaseInsensitive}.
     *
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder parseCaseSensitive()
    {
        appendInternal(SettingsParser.SENSITIVE);
        return this;
    }

    /**
     * Changes the parse style to be case insensitive for the remainder of the formatter.
     * !(p)
     * Parsing can be case sensitive or insensitive - by default it is case sensitive.
     * This method allows the case sensitivity setting of parsing to be changed.
     * !(p)
     * Calling this method changes the state of the builder such that all
     * subsequent builder method calls will parse text _in case insensitive mode.
     * See {@link #parseCaseSensitive()} for the opposite setting.
     * The parse case sensitive/insensitive methods may be called at any point
     * _in the builder, thus the parser can swap between case parsing modes
     * multiple times during the parse.
     *
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder parseCaseInsensitive()
    {
        appendInternal(SettingsParser.INSENSITIVE);
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Changes the parse style to be strict for the remainder of the formatter.
     * !(p)
     * Parsing can be strict or lenient - by default its strict.
     * This controls the degree of flexibility _in matching the text and sign styles.
     * !(p)
     * When used, this method changes the parsing to be strict from this point onwards.
     * As strict is the default, this is normally only needed after calling {@link #parseLenient()}.
     * The change will remain _in force until the end of the formatter that is eventually
     * constructed or until {@code parseLenient} is called.
     *
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder parseStrict()
    {
        appendInternal(SettingsParser.STRICT);
        return this;
    }

    /**
     * Changes the parse style to be lenient for the remainder of the formatter.
     * Note that case sensitivity is set separately to this method.
     * !(p)
     * Parsing can be strict or lenient - by default its strict.
     * This controls the degree of flexibility _in matching the text and sign styles.
     * Applications calling this method should typically also call {@link #parseCaseInsensitive()}.
     * !(p)
     * When used, this method changes the parsing to be lenient from this point onwards.
     * The change will remain _in force until the end of the formatter that is eventually
     * constructed or until {@code parseStrict} is called.
     *
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder parseLenient()
    {
        appendInternal(SettingsParser.LENIENT);
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends a default value for a field to the formatter for use _in parsing.
     * !(p)
     * This appends an instruction to the builder to inject a default value
     * into the parsed result. This is especially useful _in conjunction with
     * optional parts of the formatter.
     * !(p)
     * For example, consider a formatter that parses the year, followed by
     * an optional month, with a further optional day-of-month. Using such a
     * formatter would require the calling code to check whether a full date,
     * year-month or just a year had been parsed. This method can be used to
     * default the month and day-of-month to a sensible value, such as the
     * first of the month, allowing the calling code to always get a date.
     * !(p)
     * During formatting, this method has no effect.
     * !(p)
     * During parsing, the current state of the parse is inspected.
     * If the specified field has no associated value, because it has not been
     * parsed successfully at that point, then the specified value is injected
     * into the parse result. Injection is immediate, thus the field-value pair
     * will be visible to any subsequent elements _in the formatter.
     * As such, this method is normally called at the end of the builder.
     *
     * @param field  the field to default the value of, not null
     * @param value  the value to default the field to
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder parseDefaulting(TemporalField field, long value)
    {
        assert(field, "field");
        appendInternal(new DefaultValueParser(field, value));
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends the value of a date-time field to the formatter using a normal
     * output style.
     * !(p)
     * The value of the field will be output during a format.
     * If the value cannot be obtained then an exception will be thrown.
     * !(p)
     * The value will be printed as per the normal format of an integer value.
     * Only negative numbers will be signed. No padding will be added.
     * !(p)
     * The parser for a variable width value such as this normally behaves greedily,
     * requiring one digit, but accepting as many digits as possible.
     * This behavior can be affected by 'adjacent value parsing'.
     * See {@link #appendValue(hunt.time.temporal.TemporalField, int)} for full details.
     *
     * @param field  the field to append, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendValue(TemporalField field)
    {
        assert(field, "field");
        appendValue(new NumberPrinterParser(field, 1, 19, SignStyle.NORMAL));
        return this;
    }

    /**
     * Appends the value of a date-time field to the formatter using a fixed
     * width, zero-padded approach.
     * !(p)
     * The value of the field will be output during a format.
     * If the value cannot be obtained then an exception will be thrown.
     * !(p)
     * The value will be zero-padded on the left. If the size of the value
     * means that it cannot be printed within the width then an exception is thrown.
     * If the value of the field is negative then an exception is thrown during formatting.
     * !(p)
     * This method supports a special technique of parsing known as 'adjacent value parsing'.
     * This technique solves the problem where a value, variable or fixed width, is followed by one or more
     * fixed length values. The standard parser is greedy, and thus it would normally
     * steal the digits that are needed by the fixed width value parsers that follow the
     * variable width one.
     * !(p)
     * No action is required to initiate 'adjacent value parsing'.
     * When a call to {@code appendValue} is made, the builder
     * enters adjacent value parsing setup mode. If the immediately subsequent method
     * call or calls on the same builder are for a fixed width value, then the parser will reserve
     * space so that the fixed width values can be parsed.
     * !(p)
     * For example, consider {@code builder.appendValue(YEAR).appendValue(MONTH_OF_YEAR, 2);}
     * The year is a variable width parse of between 1 and 19 digits.
     * The month is a fixed width parse of 2 digits.
     * Because these were appended to the same builder immediately after one another,
     * the year parser will reserve two digits for the month to parse.
     * Thus, the text '201106' will correctly parse to a year of 2011 and a month of 6.
     * Without adjacent value parsing, the year would greedily parse all six digits and leave
     * nothing for the month.
     * !(p)
     * Adjacent value parsing applies to each set of fixed width not-negative values _in the parser
     * that immediately follow any kind of value, variable or fixed width.
     * Calling any other append method will end the setup of adjacent value parsing.
     * Thus, _in the unlikely event that you need to avoid adjacent value parsing behavior,
     * simply add the {@code appendValue} to another {@code DateTimeFormatterBuilder}
     * and add that to this builder.
     * !(p)
     * If adjacent parsing is active, then parsing must match exactly the specified
     * number of digits _in both strict and lenient modes.
     * In addition, no positive or negative sign is permitted.
     *
     * @param field  the field to append, not null
     * @param width  the width of the printed field, from 1 to 19
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if the width is invalid
     */
    public DateTimeFormatterBuilder appendValue(TemporalField field, int width)
    {
        assert(field, "field");
        if (width < 1 || width > 19)
        {
            throw new IllegalArgumentException(
                    "The width must be from 1 to 19 inclusive but was " ~ width.to!string);
        }
        NumberPrinterParser pp = new NumberPrinterParser(field, width, width,
                SignStyle.NOT_NEGATIVE);
        appendValue(pp);
        return this;
    }

    /**
     * Appends the value of a date-time field to the formatter providing full
     * control over formatting.
     * !(p)
     * The value of the field will be output during a format.
     * If the value cannot be obtained then an exception will be thrown.
     * !(p)
     * This method provides full control of the numeric formatting, including
     * zero-padding and the positive/negative sign.
     * !(p)
     * The parser for a variable width value such as this normally behaves greedily,
     * accepting as many digits as possible.
     * This behavior can be affected by 'adjacent value parsing'.
     * See {@link #appendValue(hunt.time.temporal.TemporalField, int)} for full details.
     * !(p)
     * In strict parsing mode, the minimum number of parsed digits is {@code minWidth}
     * and the maximum is {@code maxWidth}.
     * In lenient parsing mode, the minimum number of parsed digits is one
     * and the maximum is 19 (except as limited by adjacent value parsing).
     * !(p)
     * If this method is invoked with equal minimum and maximum widths and a sign style of
     * {@code NOT_NEGATIVE} then it delegates to {@code appendValue(TemporalField,int)}.
     * In this scenario, the formatting and parsing behavior described there occur.
     *
     * @param field  the field to append, not null
     * @param minWidth  the minimum field width of the printed field, from 1 to 19
     * @param maxWidth  the maximum field width of the printed field, from 1 to 19
     * @param signStyle  the positive/negative output style, not null
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if the widths are invalid
     */
    public DateTimeFormatterBuilder appendValue(TemporalField field,
            int minWidth, int maxWidth, SignStyle signStyle)
    {
        if (minWidth == maxWidth && signStyle == SignStyle.NOT_NEGATIVE)
        {
            return appendValue(field, maxWidth);
        }
        assert(field, "field");
        // assert(signStyle, "signStyle");
        if (minWidth < 1 || minWidth > 19)
        {
            throw new IllegalArgumentException(
                    "The minimum width must be from 1 to 19 inclusive but was "
                    ~ minWidth.to!string);
        }
        if (maxWidth < 1 || maxWidth > 19)
        {
            throw new IllegalArgumentException(
                    "The maximum width must be from 1 to 19 inclusive but was "
                    ~ maxWidth.to!string);
        }
        if (maxWidth < minWidth)
        {
            throw new IllegalArgumentException("The maximum width must exceed or equal the minimum width but "
                    ~ maxWidth.to!string ~ " < " ~ minWidth.to!string);
        }
        NumberPrinterParser pp = new NumberPrinterParser(field, minWidth, maxWidth, signStyle);
        appendValue(pp);
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends the reduced value of a date-time field to the formatter.
     * !(p)
     * Since fields such as year vary by chronology, it is recommended to use the
     * {@link #appendValueReduced(TemporalField, int, int, ChronoLocalDate)} date}
     * variant of this method _in most cases. This variant is suitable for
     * simple fields or working with only the ISO chronology.
     * !(p)
     * For formatting, the {@code width} and {@code maxWidth} are used to
     * determine the number of characters to format.
     * If they are equal then the format is fixed width.
     * If the value of the field is within the range of the {@code baseValue} using
     * {@code width} characters then the reduced value is formatted otherwise the value is
     * truncated to fit {@code maxWidth}.
     * The rightmost characters are output to match the width, left padding with zero.
     * !(p)
     * For strict parsing, the number of characters allowed by {@code width} to {@code maxWidth} are parsed.
     * For lenient parsing, the number of characters must be at least 1 and less than 10.
     * If the number of digits parsed is equal to {@code width} and the value is positive,
     * the value of the field is computed to be the first number greater than
     * or equal to the {@code baseValue} with the same least significant characters,
     * otherwise the value parsed is the field value.
     * This allows a reduced value to be entered for values _in range of the baseValue
     * and width and absolute values can be entered for values outside the range.
     * !(p)
     * For example, a base value of {@code 1980} and a width of {@code 2} will have
     * valid values from {@code 1980} to {@code 2079}.
     * During parsing, the text {@code "12"} will result _in the value {@code 2012} as that
     * is the value within the range where the last two characters are "12".
     * By contrast, parsing the text {@code "1915"} will result _in the value {@code 1915}.
     *
     * @param field  the field to append, not null
     * @param width  the field width of the printed and parsed field, from 1 to 10
     * @param maxWidth  the maximum field width of the printed field, from 1 to 10
     * @param baseValue  the base value of the range of valid values
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if the width or base value is invalid
     */
    public DateTimeFormatterBuilder appendValueReduced(TemporalField field,
            int width, int maxWidth, int baseValue)
    {
        assert(field, "field");
        ReducedPrinterParser pp = new ReducedPrinterParser(field, width,
                maxWidth, baseValue, null);
        appendValue(pp);
        return this;
    }

    /**
     * Appends the reduced value of a date-time field to the formatter.
     * !(p)
     * This is typically used for formatting and parsing a two digit year.
     * !(p)
     * The base date is used to calculate the full value during parsing.
     * For example, if the base date is 1950-01-01 then parsed values for
     * a two digit year parse will be _in the range 1950-01-01 to 2049-12-31.
     * Only the year would be extracted from the date, thus a base date of
     * 1950-08-25 would also parse to the range 1950-01-01 to 2049-12-31.
     * This behavior is necessary to support fields such as week-based-year
     * or other calendar systems where the parsed value does not align with
     * standard ISO years.
     * !(p)
     * The exact behavior is as follows. Parse the full set of fields and
     * determine the effective chronology using the last chronology if
     * it appears more than once. Then convert the base date to the
     * effective chronology. Then extract the specified field from the
     * chronology-specific base date and use it to determine the
     * {@code baseValue} used below.
     * !(p)
     * For formatting, the {@code width} and {@code maxWidth} are used to
     * determine the number of characters to format.
     * If they are equal then the format is fixed width.
     * If the value of the field is within the range of the {@code baseValue} using
     * {@code width} characters then the reduced value is formatted otherwise the value is
     * truncated to fit {@code maxWidth}.
     * The rightmost characters are output to match the width, left padding with zero.
     * !(p)
     * For strict parsing, the number of characters allowed by {@code width} to {@code maxWidth} are parsed.
     * For lenient parsing, the number of characters must be at least 1 and less than 10.
     * If the number of digits parsed is equal to {@code width} and the value is positive,
     * the value of the field is computed to be the first number greater than
     * or equal to the {@code baseValue} with the same least significant characters,
     * otherwise the value parsed is the field value.
     * This allows a reduced value to be entered for values _in range of the baseValue
     * and width and absolute values can be entered for values outside the range.
     * !(p)
     * For example, a base value of {@code 1980} and a width of {@code 2} will have
     * valid values from {@code 1980} to {@code 2079}.
     * During parsing, the text {@code "12"} will result _in the value {@code 2012} as that
     * is the value within the range where the last two characters are "12".
     * By contrast, parsing the text {@code "1915"} will result _in the value {@code 1915}.
     *
     * @param field  the field to append, not null
     * @param width  the field width of the printed and parsed field, from 1 to 10
     * @param maxWidth  the maximum field width of the printed field, from 1 to 10
     * @param baseDate  the base date used to calculate the base value for the range
     *  of valid values _in the parsed chronology, not null
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if the width or base value is invalid
     */
    public DateTimeFormatterBuilder appendValueReduced(TemporalField field,
            int width, int maxWidth, ChronoLocalDate baseDate)
    {
        assert(field, "field");
        assert(baseDate, "baseDate");
        ReducedPrinterParser pp = new ReducedPrinterParser(field, width, maxWidth, 0, baseDate);
        appendValue(pp);
        return this;
    }

    /**
     * Appends a fixed or variable width printer-parser handling adjacent value mode.
     * If a PrinterParser is not active then the new PrinterParser becomes
     * the active PrinterParser.
     * Otherwise, the active PrinterParser is modified depending on the new PrinterParser.
     * If the new PrinterParser is fixed width and has sign style {@code NOT_NEGATIVE}
     * then its width is added to the active PP and
     * the new PrinterParser is forced to be fixed width.
     * If the new PrinterParser is variable width, the active PrinterParser is changed
     * to be fixed width and the new PrinterParser becomes the active PP.
     *
     * @param pp  the printer-parser, not null
     * @return this, for chaining, not null
     */
    private DateTimeFormatterBuilder appendValue(NumberPrinterParser pp)
    {
        if (active.valueParserIndex >= 0)
        {
            int activeValueParser = active.valueParserIndex;

            // adjacent parsing mode, update setting _in previous parsers
            NumberPrinterParser basePP = cast(NumberPrinterParser) active.printerParsers.get(
                    activeValueParser);
            if (pp.minWidth == pp.maxWidth && pp.signStyle == SignStyle.NOT_NEGATIVE)
            {
                // Append the width to the subsequentWidth of the active parser
                basePP = basePP.withSubsequentWidth(pp.maxWidth);
                // Append the new parser as a fixed width
                appendInternal(pp.withFixedWidth());
                // Retain the previous active parser
                active.valueParserIndex = activeValueParser;
            }
            else
            {
                // Modify the active parser to be fixed width
                basePP = basePP.withFixedWidth();
                // The new parser becomes the mew active parser
                active.valueParserIndex = appendInternal(pp);
            }
            // Replace the modified parser with the updated one
            active.printerParsers.set(activeValueParser, basePP);
        }
        else
        {
            // The new Parser becomes the active parser
            active.valueParserIndex = appendInternal(pp);
        }
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends the fractional value of a date-time field to the formatter.
     * !(p)
     * The fractional value of the field will be output including the
     * preceding decimal point. The preceding value is not output.
     * For example, the second-of-minute value of 15 would be output as {@code .25}.
     * !(p)
     * The width of the printed fraction can be controlled. Setting the
     * minimum width to zero will cause no output to be generated.
     * The printed fraction will have the minimum width necessary between
     * the minimum and maximum widths - trailing zeroes are omitted.
     * No rounding occurs due to the maximum width - digits are simply dropped.
     * !(p)
     * When parsing _in strict mode, the number of parsed digits must be between
     * the minimum and maximum width. In strict mode, if the minimum and maximum widths
     * are equal and there is no decimal point then the parser will
     * participate _in adjacent value parsing, see
     * {@link appendValue(hunt.time.temporal.TemporalField, int)}. When parsing _in lenient mode,
     * the minimum width is considered to be zero and the maximum is nine.
     * !(p)
     * If the value cannot be obtained then an exception will be thrown.
     * If the value is negative an exception will be thrown.
     * If the field does not have a fixed set of valid values then an
     * exception will be thrown.
     * If the field value _in the date-time to be printed is invalid it
     * cannot be printed and an exception will be thrown.
     *
     * @param field  the field to append, not null
     * @param minWidth  the minimum width of the field excluding the decimal point, from 0 to 9
     * @param maxWidth  the maximum width of the field excluding the decimal point, from 1 to 9
     * @param decimalPoint  whether to output the localized decimal point symbol
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if the field has a variable set of valid values or
     *  either width is invalid
     */
    public DateTimeFormatterBuilder appendFraction(TemporalField field,
            int minWidth, int maxWidth, bool decimalPoint)
    {
        if (minWidth == maxWidth && decimalPoint == false)
        {
            // adjacent parsing
            appendValue(new FractionPrinterParser(field, minWidth, maxWidth, decimalPoint));
        }
        else
        {
            appendInternal(new FractionPrinterParser(field, minWidth, maxWidth, decimalPoint));
        }
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends the text of a date-time field to the formatter using the full
     * text style.
     * !(p)
     * The text of the field will be output during a format.
     * The value must be within the valid range of the field.
     * If the value cannot be obtained then an exception will be thrown.
     * If the field has no textual representation, then the numeric value will be used.
     * !(p)
     * The value will be printed as per the normal format of an integer value.
     * Only negative numbers will be signed. No padding will be added.
     *
     * @param field  the field to append, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendText(TemporalField field)
    {
        return appendText(field, TextStyle.FULL);
    }

    /**
     * Appends the text of a date-time field to the formatter.
     * !(p)
     * The text of the field will be output during a format.
     * The value must be within the valid range of the field.
     * If the value cannot be obtained then an exception will be thrown.
     * If the field has no textual representation, then the numeric value will be used.
     * !(p)
     * The value will be printed as per the normal format of an integer value.
     * Only negative numbers will be signed. No padding will be added.
     *
     * @param field  the field to append, not null
     * @param textStyle  the text style to use, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendText(TemporalField field, TextStyle textStyle)
    {
        assert(field, "field");
        // assert(textStyle, "textStyle");
        appendInternal(new TextPrinterParser(field, textStyle, DateTimeTextProvider.getInstance()));
        return this;
    }

    /**
     * Appends the text of a date-time field to the formatter using the specified
     * map to supply the text.
     * !(p)
     * The standard text outputting methods use the localized text _in the JDK.
     * This method allows that text to be specified directly.
     * The supplied map is not validated by the builder to ensure that formatting or
     * parsing is possible, thus an invalid map may throw an error during later use.
     * !(p)
     * Supplying the map of text provides considerable flexibility _in formatting and parsing.
     * For example, a legacy application might require or supply the months of the
     * year as "JNY", "FBY", "MCH" etc. These do not match the standard set of text
     * for localized month names. Using this method, a map can be created which
     * defines the connection between each value and the text:
     * !(pre)
     * Map&lt;Long, string&gt; map = new HashMap&lt;&gt;();
     * map.put(1L, "JNY");
     * map.put(2L, "FBY");
     * map.put(3L, "MCH");
     * ...
     * builder.appendText(MONTH_OF_YEAR, map);
     * </pre>
     * !(p)
     * Other uses might be to output the value with a suffix, such as "1st", "2nd", "3rd",
     * or as Roman numerals "I", "II", "III", "IV".
     * !(p)
     * During formatting, the value is obtained and checked that it is _in the valid range.
     * If text is not available for the value then it is output as a number.
     * During parsing, the parser will match against the map of text and numeric values.
     *
     * @param field  the field to append, not null
     * @param textLookup  the map from the value to the text
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendText(TemporalField field, Map!(Long, string) textLookup)
    {
        assert(field, "field");
        assert(textLookup, "textLookup");
        Map!(Long, string) copy = new LinkedHashMap!(Long, string)(textLookup);
        Map!(TextStyle, Map!(Long, string)) map = /* Collections.singletonMap */ new HashMap!(TextStyle,
                    Map!(Long, string))();
        map.put(TextStyle.FULL, copy);
        LocaleStore store = new LocaleStore(map);
        DateTimeTextProvider provider = new class DateTimeTextProvider
        {
            override public string getText(Chronology chrono,
                    TemporalField field, long value, TextStyle style, Locale locale)
            {
                return store.getText(value, style);
            }

            override public string getText(TemporalField field, long value,
                    TextStyle style, Locale locale)
            {
                return store.getText(value, style);
            }

            override public Iterable!(MapEntry!(string, Long)) getTextIterator(Chronology chrono,
                    TemporalField field, TextStyle style, Locale locale)
            {
                return store.getTextIterator(style);
            }

            override public Iterable!(MapEntry!(string, Long)) getTextIterator(TemporalField field,
                    TextStyle style, Locale locale)
            {
                return store.getTextIterator(style);
            }
        };
        appendInternal(new TextPrinterParser(field, TextStyle.FULL, provider));
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends an instant using ISO-8601 to the formatter, formatting fractional
     * digits _in groups of three.
     * !(p)
     * Instants have a fixed output format.
     * They are converted to a date-time with a zone-offset of UTC and formatted
     * using the standard ISO-8601 format.
     * With this method, formatting nano-of-second outputs zero, three, six
     * or nine digits as necessary.
     * The localized decimal style is not used.
     * !(p)
     * The instant is obtained using {@link ChronoField#INSTANT_SECONDS INSTANT_SECONDS}
     * and optionally {@code NANO_OF_SECOND}. The value of {@code INSTANT_SECONDS}
     * may be outside the maximum range of {@code LocalDateTime}.
     * !(p)
     * The {@linkplain ResolverStyle resolver style} has no effect on instant parsing.
     * The end-of-day time of '24:00' is handled as midnight at the start of the following day.
     * The leap-second time of '23:59:59' is handled to some degree, see
     * {@link DateTimeFormatter#parsedLeapSecond()} for full details.
     * !(p)
     * When formatting, the instant will always be suffixed by 'Z' to indicate UTC.
     * When parsing, the behaviour of {@link DateTimeFormatterBuilder#appendOffsetId()}
     * will be used to parse the offset, converting the instant to UTC as necessary.
     * !(p)
     * An alternative to this method is to format/parse the instant as a single
     * epoch-seconds value. That is achieved using {@code appendValue(INSTANT_SECONDS)}.
     *
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendInstant()
    {
        appendInternal(new InstantPrinterParser(-2));
        return this;
    }

    /**
     * Appends an instant using ISO-8601 to the formatter with control over
     * the number of fractional digits.
     * !(p)
     * Instants have a fixed output format, although this method provides some
     * control over the fractional digits. They are converted to a date-time
     * with a zone-offset of UTC and printed using the standard ISO-8601 format.
     * The localized decimal style is not used.
     * !(p)
     * The {@code fractionalDigits} parameter allows the output of the fractional
     * second to be controlled. Specifying zero will cause no fractional digits
     * to be output. From 1 to 9 will output an increasing number of digits, using
     * zero right-padding if necessary. The special value -1 is used to output as
     * many digits as necessary to avoid any trailing zeroes.
     * !(p)
     * When parsing _in strict mode, the number of parsed digits must match the
     * fractional digits. When parsing _in lenient mode, any number of fractional
     * digits from zero to nine are accepted.
     * !(p)
     * The instant is obtained using {@link ChronoField#INSTANT_SECONDS INSTANT_SECONDS}
     * and optionally {@code NANO_OF_SECOND}. The value of {@code INSTANT_SECONDS}
     * may be outside the maximum range of {@code LocalDateTime}.
     * !(p)
     * The {@linkplain ResolverStyle resolver style} has no effect on instant parsing.
     * The end-of-day time of '24:00' is handled as midnight at the start of the following day.
     * The leap-second time of '23:59:60' is handled to some degree, see
     * {@link DateTimeFormatter#parsedLeapSecond()} for full details.
     * !(p)
     * An alternative to this method is to format/parse the instant as a single
     * epoch-seconds value. That is achieved using {@code appendValue(INSTANT_SECONDS)}.
     *
     * @param fractionalDigits  the number of fractional second digits to format with,
     *  from 0 to 9, or -1 to use as many digits as necessary
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if the number of fractional digits is invalid
     */
    public DateTimeFormatterBuilder appendInstant(int fractionalDigits)
    {
        if (fractionalDigits < -1 || fractionalDigits > 9)
        {
            throw new IllegalArgumentException(
                    "The fractional digits must be from -1 to 9 inclusive but was "
                    ~ fractionalDigits.to!string);
        }
        appendInternal(new InstantPrinterParser(fractionalDigits));
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends the zone offset, such as '+01:00', to the formatter.
     * !(p)
     * This appends an instruction to format/parse the offset ID to the builder.
     * This is equivalent to calling {@code appendOffset("+HH:mm:ss", "Z")}.
     * See {@link #appendOffset(string, string)} for details on formatting
     * and parsing.
     *
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendOffsetId()
    {
        appendInternal(OffsetIdPrinterParser.INSTANCE_ID_Z);
        return this;
    }

    /**
     * Appends the zone offset, such as '+01:00', to the formatter.
     * !(p)
     * This appends an instruction to format/parse the offset ID to the builder.
     * !(p)
     * During formatting, the offset is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#offset()}.
     * It will be printed using the format defined below.
     * If the offset cannot be obtained then an exception is thrown unless the
     * section of the formatter is optional.
     * !(p)
     * When parsing _in strict mode, the input must contain the mandatory
     * and optional elements are defined by the specified pattern.
     * If the offset cannot be parsed then an exception is thrown unless
     * the section of the formatter is optional.
     * !(p)
     * When parsing _in lenient mode, only the hours are mandatory - minutes
     * and seconds are optional. The colons are required if the specified
     * pattern contains a colon. If the specified pattern is "+HH", the
     * presence of colons is determined by whether the character after the
     * hour digits is a colon or not.
     * If the offset cannot be parsed then an exception is thrown unless
     * the section of the formatter is optional.
     * !(p)
     * The format of the offset is controlled by a pattern which must be one
     * of the following:
     * !(ul)
     * !(li){@code +HH} - hour only, ignoring minute and second
     * !(li){@code +HHmm} - hour, with minute if non-zero, ignoring second, no colon
     * !(li){@code +HH:mm} - hour, with minute if non-zero, ignoring second, with colon
     * !(li){@code +HHMM} - hour and minute, ignoring second, no colon
     * !(li){@code +HH:MM} - hour and minute, ignoring second, with colon
     * !(li){@code +HHMMss} - hour and minute, with second if non-zero, no colon
     * !(li){@code +HH:MM:ss} - hour and minute, with second if non-zero, with colon
     * !(li){@code +HHMMSS} - hour, minute and second, no colon
     * !(li){@code +HH:MM:SS} - hour, minute and second, with colon
     * !(li){@code +HHmmss} - hour, with minute if non-zero or with minute and
     * second if non-zero, no colon
     * !(li){@code +HH:mm:ss} - hour, with minute if non-zero or with minute and
     * second if non-zero, with colon
     * !(li){@code +H} - hour only, ignoring minute and second
     * !(li){@code +Hmm} - hour, with minute if non-zero, ignoring second, no colon
     * !(li){@code +H:mm} - hour, with minute if non-zero, ignoring second, with colon
     * !(li){@code +HMM} - hour and minute, ignoring second, no colon
     * !(li){@code +H:MM} - hour and minute, ignoring second, with colon
     * !(li){@code +HMMss} - hour and minute, with second if non-zero, no colon
     * !(li){@code +H:MM:ss} - hour and minute, with second if non-zero, with colon
     * !(li){@code +HMMSS} - hour, minute and second, no colon
     * !(li){@code +H:MM:SS} - hour, minute and second, with colon
     * !(li){@code +Hmmss} - hour, with minute if non-zero or with minute and
     * second if non-zero, no colon
     * !(li){@code +H:mm:ss} - hour, with minute if non-zero or with minute and
     * second if non-zero, with colon
     * </ul>
     * Patterns containing "HH" will format and parse a two digit hour,
     * zero-padded if necessary. Patterns containing "H" will format with no
     * zero-padding, and parse either one or two digits.
     * In lenient mode, the parser will be greedy and parse the maximum digits possible.
     * The "no offset" text controls what text is printed when the total amount of
     * the offset fields to be output is zero.
     * Example values would be 'Z', '+00:00', 'UTC' or 'GMT'.
     * Three formats are accepted for parsing UTC - the "no offset" text, and the
     * plus and minus versions of zero defined by the pattern.
     *
     * @param pattern  the pattern to use, not null
     * @param noOffsetText  the text to use when the offset is zero, not null
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if the pattern is invalid
     */
    public DateTimeFormatterBuilder appendOffset(string pattern, string noOffsetText)
    {
        appendInternal(new OffsetIdPrinterParser(pattern, noOffsetText));
        return this;
    }

    /**
     * Appends the localized zone offset, such as 'GMT+01:00', to the formatter.
     * !(p)
     * This appends a localized zone offset to the builder, the format of the
     * localized offset is controlled by the specified {@link FormatStyle style}
     * to this method:
     * !(ul)
     * !(li){@link TextStyle#FULL full} - formats with localized offset text, such
     * as 'GMT, 2-digit hour and minute field, optional second field if non-zero,
     * and colon.
     * !(li){@link TextStyle#SHORT short} - formats with localized offset text,
     * such as 'GMT, hour without leading zero, optional 2-digit minute and
     * second if non-zero, and colon.
     * </ul>
     * !(p)
     * During formatting, the offset is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#offset()}.
     * If the offset cannot be obtained then an exception is thrown unless the
     * section of the formatter is optional.
     * !(p)
     * During parsing, the offset is parsed using the format defined above.
     * If the offset cannot be parsed then an exception is thrown unless the
     * section of the formatter is optional.
     *
     * @param style  the format style to use, not null
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if style is neither {@link TextStyle#FULL
     * full} nor {@link TextStyle#SHORT short}
     */
    public DateTimeFormatterBuilder appendLocalizedOffset(TextStyle style)
    {
        // assert(style, "style");
        if (style != TextStyle.FULL && style != TextStyle.SHORT)
        {
            throw new IllegalArgumentException("Style must be either full or short");
        }
        appendInternal(new LocalizedOffsetIdPrinterParser(style));
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends the time-zone ID, such as 'Europe/Paris' or '+02:00', to the formatter.
     * !(p)
     * This appends an instruction to format/parse the zone ID to the builder.
     * The zone ID is obtained _in a strict manner suitable for {@code ZonedDateTime}.
     * By contrast, {@code OffsetDateTime} does not have a zone ID suitable
     * for use with this method, see {@link #appendZoneOrOffsetId()}.
     * !(p)
     * During formatting, the zone is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#zoneId()}.
     * It will be printed using the result of {@link ZoneId#getId()}.
     * If the zone cannot be obtained then an exception is thrown unless the
     * section of the formatter is optional.
     * !(p)
     * During parsing, the text must match a known zone or offset.
     * There are two types of zone ID, offset-based, such as '+01:30' and
     * region-based, such as 'Europe/London'. These are parsed differently.
     * If the parse starts with '+', '-', 'UT', 'UTC' or 'GMT', then the parser
     * expects an offset-based zone and will not match region-based zones.
     * The offset ID, such as '+02:30', may be at the start of the parse,
     * or prefixed by  'UT', 'UTC' or 'GMT'. The offset ID parsing is
     * equivalent to using {@link #appendOffset(string, string)} using the
     * arguments 'HH:MM:ss' and the no offset string '0'.
     * If the parse starts with 'UT', 'UTC' or 'GMT', and the parser cannot
     * match a following offset ID, then {@link ZoneOffset#UTC} is selected.
     * In all other cases, the list of known region-based zones is used to
     * find the longest available match. If no match is found, and the parse
     * starts with 'Z', then {@code ZoneOffset.UTC} is selected.
     * The parser uses the {@linkplain #parseCaseInsensitive() case sensitive} setting.
     * !(p)
     * For example, the following will parse:
     * !(pre)
     *   "Europe/London"           -- ZoneId.of("Europe/London")
     *   "Z"                       -- ZoneOffset.UTC
     *   "UT"                      -- ZoneId.of("UT")
     *   "UTC"                     -- ZoneId.of("UTC")
     *   "GMT"                     -- ZoneId.of("GMT")
     *   "+01:30"                  -- ZoneOffset.of("+01:30")
     *   "UT+01:30"                -- ZoneOffset.of("+01:30")
     *   "UTC+01:30"               -- ZoneOffset.of("+01:30")
     *   "GMT+01:30"               -- ZoneOffset.of("+01:30")
     * </pre>
     *
     * @return this, for chaining, not null
     * @see #appendZoneRegionId()
     */
    public DateTimeFormatterBuilder appendZoneId()
    {
        appendInternal(new ZoneIdPrinterParser(TemporalQueries.zoneId(), "ZoneId()"));
        return this;
    }

    /**
     * Appends the time-zone region ID, such as 'Europe/Paris', to the formatter,
     * rejecting the zone ID if it is a {@code ZoneOffset}.
     * !(p)
     * This appends an instruction to format/parse the zone ID to the builder
     * only if it is a region-based ID.
     * !(p)
     * During formatting, the zone is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#zoneId()}.
     * If the zone is a {@code ZoneOffset} or it cannot be obtained then
     * an exception is thrown unless the section of the formatter is optional.
     * If the zone is not an offset, then the zone will be printed using
     * the zone ID from {@link ZoneId#getId()}.
     * !(p)
     * During parsing, the text must match a known zone or offset.
     * There are two types of zone ID, offset-based, such as '+01:30' and
     * region-based, such as 'Europe/London'. These are parsed differently.
     * If the parse starts with '+', '-', 'UT', 'UTC' or 'GMT', then the parser
     * expects an offset-based zone and will not match region-based zones.
     * The offset ID, such as '+02:30', may be at the start of the parse,
     * or prefixed by  'UT', 'UTC' or 'GMT'. The offset ID parsing is
     * equivalent to using {@link #appendOffset(string, string)} using the
     * arguments 'HH:MM:ss' and the no offset string '0'.
     * If the parse starts with 'UT', 'UTC' or 'GMT', and the parser cannot
     * match a following offset ID, then {@link ZoneOffset#UTC} is selected.
     * In all other cases, the list of known region-based zones is used to
     * find the longest available match. If no match is found, and the parse
     * starts with 'Z', then {@code ZoneOffset.UTC} is selected.
     * The parser uses the {@linkplain #parseCaseInsensitive() case sensitive} setting.
     * !(p)
     * For example, the following will parse:
     * !(pre)
     *   "Europe/London"           -- ZoneId.of("Europe/London")
     *   "Z"                       -- ZoneOffset.UTC
     *   "UT"                      -- ZoneId.of("UT")
     *   "UTC"                     -- ZoneId.of("UTC")
     *   "GMT"                     -- ZoneId.of("GMT")
     *   "+01:30"                  -- ZoneOffset.of("+01:30")
     *   "UT+01:30"                -- ZoneOffset.of("+01:30")
     *   "UTC+01:30"               -- ZoneOffset.of("+01:30")
     *   "GMT+01:30"               -- ZoneOffset.of("+01:30")
     * </pre>
     * !(p)
     * Note that this method is identical to {@code appendZoneId()} except
     * _in the mechanism used to obtain the zone.
     * Note also that parsing accepts offsets, whereas formatting will never
     * produce one.
     *
     * @return this, for chaining, not null
     * @see #appendZoneId()
     */
    public DateTimeFormatterBuilder appendZoneRegionId()
    {
        appendInternal(new ZoneIdPrinterParser(QUERY_REGION_ONLY, "ZoneRegionId()"));
        return this;
    }

    /**
     * Appends the time-zone ID, such as 'Europe/Paris' or '+02:00', to
     * the formatter, using the best available zone ID.
     * !(p)
     * This appends an instruction to format/parse the best available
     * zone or offset ID to the builder.
     * The zone ID is obtained _in a lenient manner that first attempts to
     * find a true zone ID, such as that on {@code ZonedDateTime}, and
     * then attempts to find an offset, such as that on {@code OffsetDateTime}.
     * !(p)
     * During formatting, the zone is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#zone()}.
     * It will be printed using the result of {@link ZoneId#getId()}.
     * If the zone cannot be obtained then an exception is thrown unless the
     * section of the formatter is optional.
     * !(p)
     * During parsing, the text must match a known zone or offset.
     * There are two types of zone ID, offset-based, such as '+01:30' and
     * region-based, such as 'Europe/London'. These are parsed differently.
     * If the parse starts with '+', '-', 'UT', 'UTC' or 'GMT', then the parser
     * expects an offset-based zone and will not match region-based zones.
     * The offset ID, such as '+02:30', may be at the start of the parse,
     * or prefixed by  'UT', 'UTC' or 'GMT'. The offset ID parsing is
     * equivalent to using {@link #appendOffset(string, string)} using the
     * arguments 'HH:MM:ss' and the no offset string '0'.
     * If the parse starts with 'UT', 'UTC' or 'GMT', and the parser cannot
     * match a following offset ID, then {@link ZoneOffset#UTC} is selected.
     * In all other cases, the list of known region-based zones is used to
     * find the longest available match. If no match is found, and the parse
     * starts with 'Z', then {@code ZoneOffset.UTC} is selected.
     * The parser uses the {@linkplain #parseCaseInsensitive() case sensitive} setting.
     * !(p)
     * For example, the following will parse:
     * !(pre)
     *   "Europe/London"           -- ZoneId.of("Europe/London")
     *   "Z"                       -- ZoneOffset.UTC
     *   "UT"                      -- ZoneId.of("UT")
     *   "UTC"                     -- ZoneId.of("UTC")
     *   "GMT"                     -- ZoneId.of("GMT")
     *   "+01:30"                  -- ZoneOffset.of("+01:30")
     *   "UT+01:30"                -- ZoneOffset.of("UT+01:30")
     *   "UTC+01:30"               -- ZoneOffset.of("UTC+01:30")
     *   "GMT+01:30"               -- ZoneOffset.of("GMT+01:30")
     * </pre>
     * !(p)
     * Note that this method is identical to {@code appendZoneId()} except
     * _in the mechanism used to obtain the zone.
     *
     * @return this, for chaining, not null
     * @see #appendZoneId()
     */
    public DateTimeFormatterBuilder appendZoneOrOffsetId()
    {
        appendInternal(new ZoneIdPrinterParser(TemporalQueries.zone(), "ZoneOrOffsetId()"));
        return this;
    }

    /**
     * Appends the time-zone name, such as 'British Summer Time', to the formatter.
     * !(p)
     * This appends an instruction to format/parse the textual name of the zone to
     * the builder.
     * !(p)
     * During formatting, the zone is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#zoneId()}.
     * If the zone is a {@code ZoneOffset} it will be printed using the
     * result of {@link ZoneOffset#getId()}.
     * If the zone is not an offset, the textual name will be looked up
     * for the locale set _in the {@link DateTimeFormatter}.
     * If the temporal object being printed represents an instant, or if it is a
     * local date-time that is not _in a daylight saving gap or overlap then
     * the text will be the summer or winter time text as appropriate.
     * If the lookup for text does not find any suitable result, then the
     * {@link ZoneId#getId() ID} will be printed.
     * If the zone cannot be obtained then an exception is thrown unless the
     * section of the formatter is optional.
     * !(p)
     * During parsing, either the textual zone name, the zone ID or the offset
     * is accepted. Many textual zone names are not unique, such as CST can be
     * for both "Central Standard Time" and "China Standard Time". In this
     * situation, the zone id will be determined by the region information from
     * formatter's  {@link DateTimeFormatter#getLocale() locale} and the standard
     * zone id for that area, for example, America/New_York for the America Eastern
     * zone. The {@link #appendZoneText(TextStyle, Set)} may be used
     * to specify a set of preferred {@link ZoneId} _in this situation.
     *
     * @param textStyle  the text style to use, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendZoneText(TextStyle textStyle)
    {
        appendInternal(new ZoneTextPrinterParser(textStyle, null, false));
        return this;
    }

    /**
     * Appends the time-zone name, such as 'British Summer Time', to the formatter.
     * !(p)
     * This appends an instruction to format/parse the textual name of the zone to
     * the builder.
     * !(p)
     * During formatting, the zone is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#zoneId()}.
     * If the zone is a {@code ZoneOffset} it will be printed using the
     * result of {@link ZoneOffset#getId()}.
     * If the zone is not an offset, the textual name will be looked up
     * for the locale set _in the {@link DateTimeFormatter}.
     * If the temporal object being printed represents an instant, or if it is a
     * local date-time that is not _in a daylight saving gap or overlap, then the text
     * will be the summer or winter time text as appropriate.
     * If the lookup for text does not find any suitable result, then the
     * {@link ZoneId#getId() ID} will be printed.
     * If the zone cannot be obtained then an exception is thrown unless the
     * section of the formatter is optional.
     * !(p)
     * During parsing, either the textual zone name, the zone ID or the offset
     * is accepted. Many textual zone names are not unique, such as CST can be
     * for both "Central Standard Time" and "China Standard Time". In this
     * situation, the zone id will be determined by the region information from
     * formatter's  {@link DateTimeFormatter#getLocale() locale} and the standard
     * zone id for that area, for example, America/New_York for the America Eastern
     * zone. This method also allows a set of preferred {@link ZoneId} to be
     * specified for parsing. The matched preferred zone id will be used if the
     * textural zone name being parsed is not unique.
     * !(p)
     * If the zone cannot be parsed then an exception is thrown unless the
     * section of the formatter is optional.
     *
     * @param textStyle  the text style to use, not null
     * @param preferredZones  the set of preferred zone ids, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendZoneText(TextStyle textStyle, Set!(ZoneId) preferredZones)
    {
        assert(preferredZones, "preferredZones");
        appendInternal(new ZoneTextPrinterParser(textStyle, preferredZones, false));
        return this;
    }
    //----------------------------------------------------------------------
    /**
     * Appends the generic time-zone name, such as 'Pacific Time', to the formatter.
     * !(p)
     * This appends an instruction to format/parse the generic textual
     * name of the zone to the builder. The generic name is the same throughout the whole
     * year, ignoring any daylight saving changes. For example, 'Pacific Time' is the
     * generic name, whereas 'Pacific Standard Time' and 'Pacific Daylight Time' are the
     * specific names, see {@link #appendZoneText(TextStyle)}.
     * !(p)
     * During formatting, the zone is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#zoneId()}.
     * If the zone is a {@code ZoneOffset} it will be printed using the
     * result of {@link ZoneOffset#getId()}.
     * If the zone is not an offset, the textual name will be looked up
     * for the locale set _in the {@link DateTimeFormatter}.
     * If the lookup for text does not find any suitable result, then the
     * {@link ZoneId#getId() ID} will be printed.
     * If the zone cannot be obtained then an exception is thrown unless the
     * section of the formatter is optional.
     * !(p)
     * During parsing, either the textual zone name, the zone ID or the offset
     * is accepted. Many textual zone names are not unique, such as CST can be
     * for both "Central Standard Time" and "China Standard Time". In this
     * situation, the zone id will be determined by the region information from
     * formatter's  {@link DateTimeFormatter#getLocale() locale} and the standard
     * zone id for that area, for example, America/New_York for the America Eastern zone.
     * The {@link #appendGenericZoneText(TextStyle, Set)} may be used
     * to specify a set of preferred {@link ZoneId} _in this situation.
     *
     * @param textStyle  the text style to use, not null
     * @return this, for chaining, not null
     * @since 9
     */
    public DateTimeFormatterBuilder appendGenericZoneText(TextStyle textStyle)
    {
        appendInternal(new ZoneTextPrinterParser(textStyle, null, true));
        return this;
    }

    /**
     * Appends the generic time-zone name, such as 'Pacific Time', to the formatter.
     * !(p)
     * This appends an instruction to format/parse the generic textual
     * name of the zone to the builder. The generic name is the same throughout the whole
     * year, ignoring any daylight saving changes. For example, 'Pacific Time' is the
     * generic name, whereas 'Pacific Standard Time' and 'Pacific Daylight Time' are the
     * specific names, see {@link #appendZoneText(TextStyle)}.
     * !(p)
     * This method also allows a set of preferred {@link ZoneId} to be
     * specified for parsing. The matched preferred zone id will be used if the
     * textural zone name being parsed is not unique.
     * !(p)
     * See {@link #appendGenericZoneText(TextStyle)} for details about
     * formatting and parsing.
     *
     * @param textStyle  the text style to use, not null
     * @param preferredZones  the set of preferred zone ids, not null
     * @return this, for chaining, not null
     * @since 9
     */
    public DateTimeFormatterBuilder appendGenericZoneText(TextStyle textStyle,
            Set!(ZoneId) preferredZones)
    {
        appendInternal(new ZoneTextPrinterParser(textStyle, preferredZones, true));
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends the chronology ID, such as 'ISO' or 'ThaiBuddhist', to the formatter.
     * !(p)
     * This appends an instruction to format/parse the chronology ID to the builder.
     * !(p)
     * During formatting, the chronology is obtained using a mechanism equivalent
     * to querying the temporal with {@link TemporalQueries#chronology()}.
     * It will be printed using the result of {@link Chronology#getId()}.
     * If the chronology cannot be obtained then an exception is thrown unless the
     * section of the formatter is optional.
     * !(p)
     * During parsing, the chronology is parsed and must match one of the chronologies
     * _in {@link Chronology#getAvailableChronologies()}.
     * If the chronology cannot be parsed then an exception is thrown unless the
     * section of the formatter is optional.
     * The parser uses the {@linkplain #parseCaseInsensitive() case sensitive} setting.
     *
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendChronologyId()
    {
        appendInternal(new ChronoPrinterParser(null));
        return this;
    }

    /**
     * Appends the chronology name to the formatter.
     * !(p)
     * The calendar system name will be output during a format.
     * If the chronology cannot be obtained then an exception will be thrown.
     *
     * @param textStyle  the text style to use, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendChronologyText(TextStyle textStyle)
    {
        assert(textStyle, "textStyle");
        appendInternal(new ChronoPrinterParser(textStyle));
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends a localized date-time pattern to the formatter.
     * !(p)
     * This appends a localized section to the builder, suitable for outputting
     * a date, time or date-time combination. The format of the localized
     * section is lazily looked up based on four items:
     * !(ul)
     * !(li)the {@code dateStyle} specified to this method
     * !(li)the {@code timeStyle} specified to this method
     * !(li)the {@code Locale} of the {@code DateTimeFormatter}
     * !(li)the {@code Chronology}, selecting the best available
     * </ul>
     * During formatting, the chronology is obtained from the temporal object
     * being formatted, which may have been overridden by
     * {@link DateTimeFormatter#withChronology(Chronology)}.
     * The {@code FULL} and {@code LONG} styles typically require a time-zone.
     * When formatting using these styles, a {@code ZoneId} must be available,
     * either by using {@code ZonedDateTime} or {@link DateTimeFormatter#withZone}.
     * !(p)
     * During parsing, if a chronology has already been parsed, then it is used.
     * Otherwise the default from {@code DateTimeFormatter.withChronology(Chronology)}
     * is used, with {@code IsoChronology} as the fallback.
     * !(p)
     * Note that this method provides similar functionality to methods on
     * {@code DateFormat} such as {@link java.text.DateFormat#getDateTimeInstance(int, int)}.
     *
     * @param dateStyle  the date style to use, null means no date required
     * @param timeStyle  the time style to use, null means no time required
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if both the date and time styles are null
     */
    public DateTimeFormatterBuilder appendLocalized(FormatStyle dateStyle, FormatStyle timeStyle)
    {
        if (dateStyle is null && timeStyle is null)
        {
            throw new IllegalArgumentException("Either the date or time style must be non-null");
        }
        appendInternal(new LocalizedPrinterParser(dateStyle, timeStyle));
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends a character literal to the formatter.
     * !(p)
     * This character will be output during a format.
     *
     * @param literal  the literal to append, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendLiteral(char literal)
    {
        appendInternal(new CharLiteralPrinterParser(literal));
        return this;
    }

    /**
     * Appends a string literal to the formatter.
     * !(p)
     * This string will be output during a format.
     * !(p)
     * If the literal is empty, nothing is added to the formatter.
     *
     * @param literal  the literal to append, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendLiteral(string literal)
    {
        assert(literal, "literal");
        if (literal.length > 0)
        {
            if (literal.length == 1)
            {
                appendInternal(new CharLiteralPrinterParser(literal[0]));
            }
            else
            {
                appendInternal(new StringLiteralPrinterParser(literal));
            }
        }
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends all the elements of a formatter to the builder.
     * !(p)
     * This method has the same effect as appending each of the constituent
     * parts of the formatter directly to this builder.
     *
     * @param formatter  the formatter to add, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder append(DateTimeFormatter formatter)
    {
        assert(formatter, "formatter");
        appendInternal(formatter.toPrinterParser(false));
        return this;
    }

    /**
     * Appends a formatter to the builder which will optionally format/parse.
     * !(p)
     * This method has the same effect as appending each of the constituent
     * parts directly to this builder surrounded by an {@link #optionalStart()} and
     * {@link #optionalEnd()}.
     * !(p)
     * The formatter will format if data is available for all the fields contained within it.
     * The formatter will parse if the string matches, otherwise no error is returned.
     *
     * @param formatter  the formatter to add, not null
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder appendOptional(DateTimeFormatter formatter)
    {
        assert(formatter, "formatter");
        appendInternal(formatter.toPrinterParser(true));
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends the elements defined by the specified pattern to the builder.
     * !(p)
     * All letters 'A' to 'Z' and 'a' to 'z' are reserved as pattern letters.
     * The characters '#', '{' and '}' are reserved for future use.
     * The characters '[' and ']' indicate optional patterns.
     * The following pattern letters are defined:
     * !(pre)
     *  Symbol  Meaning                     Presentation      Examples
     *  ------  -------                     ------------      -------
     *   G       era                         text              AD; Anno Domini; A
     *   u       year                        year              2004; 04
     *   y       year-of-era                 year              2004; 04
     *   D       day-of-year                 number            189
     *   M/L     month-of-year               number/text       7; 07; Jul; July; J
     *   d       day-of-month                number            10
     *   g       modified-julian-day         number            2451334
     *
     *   Q/q     quarter-of-year             number/text       3; 03; Q3; 3rd quarter
     *   Y       week-based-year             year              1996; 96
     *   w       week-of-week-based-year     number            27
     *   W       week-of-month               number            4
     *   E       day-of-week                 text              Tue; Tuesday; T
     *   e/c     localized day-of-week       number/text       2; 02; Tue; Tuesday; T
     *   F       day-of-week-_in-month        number            3
     *
     *   a       am-pm-of-day                text              PM
     *   h       clock-hour-of-am-pm (1-12)  number            12
     *   K       hour-of-am-pm (0-11)        number            0
     *   k       clock-hour-of-day (1-24)    number            24
     *
     *   H       hour-of-day (0-23)          number            0
     *   m       minute-of-hour              number            30
     *   s       second-of-minute            number            55
     *   S       fraction-of-second          fraction          978
     *   A       milli-of-day                number            1234
     *   n       nano-of-second              number            987654321
     *   N       nano-of-day                 number            1234000000
     *
     *   V       time-zone ID                zone-id           America/Los_Angeles; Z; -08:30
     *   v       generic time-zone name      zone-name         PT, Pacific Time
     *   z       time-zone name              zone-name         Pacific Standard Time; PST
     *   O       localized zone-offset       offset-O          GMT+8; GMT+08:00; UTC-08:00;
     *   X       zone-offset 'Z' for zero    offset-X          Z; -08; -0830; -08:30; -083015; -08:30:15
     *   x       zone-offset                 offset-x          +0000; -08; -0830; -08:30; -083015; -08:30:15
     *   Z       zone-offset                 offset-Z          +0000; -0800; -08:00
     *
     *   p       pad next                    pad modifier      1
     *
     *   '       escape for text             delimiter
     *   ''      single quote                literal           '
     *   [       optional section start
     *   ]       optional section end
     *   #       reserved for future use
     *   {       reserved for future use
     *   }       reserved for future use
     * </pre>
     * !(p)
     * The count of pattern letters determine the format.
     * See <a href="DateTimeFormatter.html#patterns">DateTimeFormatter</a> for a user-focused description of the patterns.
     * The following tables define how the pattern letters map to the builder.
     * !(p)
     * !(b)Date fields</b>: Pattern letters to output a date.
     * !(pre)
     *  Pattern  Count  Equivalent builder methods
     *  -------  -----  --------------------------
     *    G       1      appendText(ChronoField.ERA, TextStyle.SHORT)
     *    GG      2      appendText(ChronoField.ERA, TextStyle.SHORT)
     *    GGG     3      appendText(ChronoField.ERA, TextStyle.SHORT)
     *    GGGG    4      appendText(ChronoField.ERA, TextStyle.FULL)
     *    GGGGG   5      appendText(ChronoField.ERA, TextStyle.NARROW)
     *
     *    u       1      appendValue(ChronoField.YEAR, 1, 19, SignStyle.NORMAL)
     *    uu      2      appendValueReduced(ChronoField.YEAR, 2, 2000)
     *    uuu     3      appendValue(ChronoField.YEAR, 3, 19, SignStyle.NORMAL)
     *    u..u    4..n   appendValue(ChronoField.YEAR, n, 19, SignStyle.EXCEEDS_PAD)
     *    y       1      appendValue(ChronoField.YEAR_OF_ERA, 1, 19, SignStyle.NORMAL)
     *    yy      2      appendValueReduced(ChronoField.YEAR_OF_ERA, 2, 2000)
     *    yyy     3      appendValue(ChronoField.YEAR_OF_ERA, 3, 19, SignStyle.NORMAL)
     *    y..y    4..n   appendValue(ChronoField.YEAR_OF_ERA, n, 19, SignStyle.EXCEEDS_PAD)
     *    Y       1      append special localized WeekFields element for numeric week-based-year
     *    YY      2      append special localized WeekFields element for reduced numeric week-based-year 2 digits
     *    YYY     3      append special localized WeekFields element for numeric week-based-year (3, 19, SignStyle.NORMAL)
     *    Y..Y    4..n   append special localized WeekFields element for numeric week-based-year (n, 19, SignStyle.EXCEEDS_PAD)
     *
     *    Q       1      appendValue(IsoFields.QUARTER_OF_YEAR)
     *    QQ      2      appendValue(IsoFields.QUARTER_OF_YEAR, 2)
     *    QQQ     3      appendText(IsoFields.QUARTER_OF_YEAR, TextStyle.SHORT)
     *    QQQQ    4      appendText(IsoFields.QUARTER_OF_YEAR, TextStyle.FULL)
     *    QQQQQ   5      appendText(IsoFields.QUARTER_OF_YEAR, TextStyle.NARROW)
     *    q       1      appendValue(IsoFields.QUARTER_OF_YEAR)
     *    qq      2      appendValue(IsoFields.QUARTER_OF_YEAR, 2)
     *    qqq     3      appendText(IsoFields.QUARTER_OF_YEAR, TextStyle.SHORT_STANDALONE)
     *    qqqq    4      appendText(IsoFields.QUARTER_OF_YEAR, TextStyle.FULL_STANDALONE)
     *    qqqqq   5      appendText(IsoFields.QUARTER_OF_YEAR, TextStyle.NARROW_STANDALONE)
     *
     *    M       1      appendValue(ChronoField.MONTH_OF_YEAR)
     *    MM      2      appendValue(ChronoField.MONTH_OF_YEAR, 2)
     *    MMM     3      appendText(ChronoField.MONTH_OF_YEAR, TextStyle.SHORT)
     *    MMMM    4      appendText(ChronoField.MONTH_OF_YEAR, TextStyle.FULL)
     *    MMMMM   5      appendText(ChronoField.MONTH_OF_YEAR, TextStyle.NARROW)
     *    L       1      appendValue(ChronoField.MONTH_OF_YEAR)
     *    LL      2      appendValue(ChronoField.MONTH_OF_YEAR, 2)
     *    LLL     3      appendText(ChronoField.MONTH_OF_YEAR, TextStyle.SHORT_STANDALONE)
     *    LLLL    4      appendText(ChronoField.MONTH_OF_YEAR, TextStyle.FULL_STANDALONE)
     *    LLLLL   5      appendText(ChronoField.MONTH_OF_YEAR, TextStyle.NARROW_STANDALONE)
     *
     *    w       1      append special localized WeekFields element for numeric week-of-year
     *    ww      2      append special localized WeekFields element for numeric week-of-year, zero-padded
     *    W       1      append special localized WeekFields element for numeric week-of-month
     *    d       1      appendValue(ChronoField.DAY_OF_MONTH)
     *    dd      2      appendValue(ChronoField.DAY_OF_MONTH, 2)
     *    D       1      appendValue(ChronoField.DAY_OF_YEAR)
     *    DD      2      appendValue(ChronoField.DAY_OF_YEAR, 2, 3, SignStyle.NOT_NEGATIVE)
     *    DDD     3      appendValue(ChronoField.DAY_OF_YEAR, 3)
     *    F       1      appendValue(ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH)
     *    g..g    1..n   appendValue(JulianFields.MODIFIED_JULIAN_DAY, n, 19, SignStyle.NORMAL)
     *    E       1      appendText(ChronoField.DAY_OF_WEEK, TextStyle.SHORT)
     *    EE      2      appendText(ChronoField.DAY_OF_WEEK, TextStyle.SHORT)
     *    EEE     3      appendText(ChronoField.DAY_OF_WEEK, TextStyle.SHORT)
     *    EEEE    4      appendText(ChronoField.DAY_OF_WEEK, TextStyle.FULL)
     *    EEEEE   5      appendText(ChronoField.DAY_OF_WEEK, TextStyle.NARROW)
     *    e       1      append special localized WeekFields element for numeric day-of-week
     *    ee      2      append special localized WeekFields element for numeric day-of-week, zero-padded
     *    eee     3      appendText(ChronoField.DAY_OF_WEEK, TextStyle.SHORT)
     *    eeee    4      appendText(ChronoField.DAY_OF_WEEK, TextStyle.FULL)
     *    eeeee   5      appendText(ChronoField.DAY_OF_WEEK, TextStyle.NARROW)
     *    c       1      append special localized WeekFields element for numeric day-of-week
     *    ccc     3      appendText(ChronoField.DAY_OF_WEEK, TextStyle.SHORT_STANDALONE)
     *    cccc    4      appendText(ChronoField.DAY_OF_WEEK, TextStyle.FULL_STANDALONE)
     *    ccccc   5      appendText(ChronoField.DAY_OF_WEEK, TextStyle.NARROW_STANDALONE)
     * </pre>
     * !(p)
     * !(b)Time fields</b>: Pattern letters to output a time.
     * !(pre)
     *  Pattern  Count  Equivalent builder methods
     *  -------  -----  --------------------------
     *    a       1      appendText(ChronoField.AMPM_OF_DAY, TextStyle.SHORT)
     *    h       1      appendValue(ChronoField.CLOCK_HOUR_OF_AMPM)
     *    hh      2      appendValue(ChronoField.CLOCK_HOUR_OF_AMPM, 2)
     *    H       1      appendValue(ChronoField.HOUR_OF_DAY)
     *    HH      2      appendValue(ChronoField.HOUR_OF_DAY, 2)
     *    k       1      appendValue(ChronoField.CLOCK_HOUR_OF_DAY)
     *    kk      2      appendValue(ChronoField.CLOCK_HOUR_OF_DAY, 2)
     *    K       1      appendValue(ChronoField.HOUR_OF_AMPM)
     *    KK      2      appendValue(ChronoField.HOUR_OF_AMPM, 2)
     *    m       1      appendValue(ChronoField.MINUTE_OF_HOUR)
     *    mm      2      appendValue(ChronoField.MINUTE_OF_HOUR, 2)
     *    s       1      appendValue(ChronoField.SECOND_OF_MINUTE)
     *    ss      2      appendValue(ChronoField.SECOND_OF_MINUTE, 2)
     *
     *    S..S    1..n   appendFraction(ChronoField.NANO_OF_SECOND, n, n, false)
     *    A..A    1..n   appendValue(ChronoField.MILLI_OF_DAY, n, 19, SignStyle.NOT_NEGATIVE)
     *    n..n    1..n   appendValue(ChronoField.NANO_OF_SECOND, n, 19, SignStyle.NOT_NEGATIVE)
     *    N..N    1..n   appendValue(ChronoField.NANO_OF_DAY, n, 19, SignStyle.NOT_NEGATIVE)
     * </pre>
     * !(p)
     * !(b)Zone ID</b>: Pattern letters to output {@code ZoneId}.
     * !(pre)
     *  Pattern  Count  Equivalent builder methods
     *  -------  -----  --------------------------
     *    VV      2      appendZoneId()
     *    v       1      appendGenericZoneText(TextStyle.SHORT)
     *    vvvv    4      appendGenericZoneText(TextStyle.FULL)
     *    z       1      appendZoneText(TextStyle.SHORT)
     *    zz      2      appendZoneText(TextStyle.SHORT)
     *    zzz     3      appendZoneText(TextStyle.SHORT)
     *    zzzz    4      appendZoneText(TextStyle.FULL)
     * </pre>
     * !(p)
     * !(b)Zone offset</b>: Pattern letters to output {@code ZoneOffset}.
     * !(pre)
     *  Pattern  Count  Equivalent builder methods
     *  -------  -----  --------------------------
     *    O       1      appendLocalizedOffset(TextStyle.SHORT)
     *    OOOO    4      appendLocalizedOffset(TextStyle.FULL)
     *    X       1      appendOffset("+HHmm","Z")
     *    XX      2      appendOffset("+HHMM","Z")
     *    XXX     3      appendOffset("+HH:MM","Z")
     *    XXXX    4      appendOffset("+HHMMss","Z")
     *    XXXXX   5      appendOffset("+HH:MM:ss","Z")
     *    x       1      appendOffset("+HHmm","+00")
     *    xx      2      appendOffset("+HHMM","+0000")
     *    xxx     3      appendOffset("+HH:MM","+00:00")
     *    xxxx    4      appendOffset("+HHMMss","+0000")
     *    xxxxx   5      appendOffset("+HH:MM:ss","+00:00")
     *    Z       1      appendOffset("+HHMM","+0000")
     *    ZZ      2      appendOffset("+HHMM","+0000")
     *    ZZZ     3      appendOffset("+HHMM","+0000")
     *    ZZZZ    4      appendLocalizedOffset(TextStyle.FULL)
     *    ZZZZZ   5      appendOffset("+HH:MM:ss","Z")
     * </pre>
     * !(p)
     * !(b)Modifiers</b>: Pattern letters that modify the rest of the pattern:
     * !(pre)
     *  Pattern  Count  Equivalent builder methods
     *  -------  -----  --------------------------
     *    [       1      optionalStart()
     *    ]       1      optionalEnd()
     *    p..p    1..n   padNext(n)
     * </pre>
     * !(p)
     * Any sequence of letters not specified above, unrecognized letter or
     * reserved character will throw an exception.
     * Future versions may add to the set of patterns.
     * It is recommended to use single quotes around all characters that you want
     * to output directly to ensure that future changes do not break your application.
     * !(p)
     * Note that the pattern string is similar, but not identical, to
     * {@link java.text.SimpleDateFormat SimpleDateFormat}.
     * The pattern string is also similar, but not identical, to that defined by the
     * Unicode Common Locale Data Repository (CLDR/LDML).
     * Pattern letters 'X' and 'u' are aligned with Unicode CLDR/LDML.
     * By contrast, {@code SimpleDateFormat} uses 'u' for the numeric day of week.
     * Pattern letters 'y' and 'Y' parse years of two digits and more than 4 digits differently.
     * Pattern letters 'n', 'A', 'N', and 'p' are added.
     * Number types will reject large numbers.
     *
     * @param pattern  the pattern to add, not null
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if the pattern is invalid
     */
    public DateTimeFormatterBuilder appendPattern(string pattern)
    {
        assert(pattern, "pattern");
        parsePattern(pattern);
        return this;
    }

    private void parsePattern(string pattern)
    {
        for (int pos = 0; pos < pattern.length; pos++)
        {
            char cur = pattern[pos];
            if ((cur >= 'A' && cur <= 'Z') || (cur >= 'a' && cur <= 'z'))
            {
                int start = pos++;
                for (; pos < pattern.length && pattern[pos] == cur; pos++)
                {
                } // short loop
                int count = pos - start;
                // padding
                if (cur == 'p')
                {
                    int pad = 0;
                    if (pos < pattern.length)
                    {
                        cur = pattern[pos];
                        if ((cur >= 'A' && cur <= 'Z') || (cur >= 'a' && cur <= 'z'))
                        {
                            pad = count;
                            start = pos++;
                            for (; pos < pattern.length && pattern[pos] == cur;
                                    pos++)
                            {
                            } // short loop
                            count = pos - start;
                        }
                    }
                    if (pad == 0)
                    {
                        throw new IllegalArgumentException(
                                "Pad letter 'p' must be followed by valid pad pattern: " ~ pattern);
                    }
                    padNext(pad); // pad and continue parsing
                }
                // main rules
                TemporalField field = FIELD_MAP.get(cur);
                if (field !is null)
                {
                    parseField(cur, count, field);
                }
                else if (cur == 'z')
                {
                    if (count > 4)
                    {
                        throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
                    }
                    else if (count == 4)
                    {
                        appendZoneText(TextStyle.FULL);
                    }
                    else
                    {
                        appendZoneText(TextStyle.SHORT);
                    }
                }
                else if (cur == 'V')
                {
                    if (count != 2)
                    {
                        throw new IllegalArgumentException("Pattern letter count must be 2: " ~ cur);
                    }
                    appendZoneId();
                }
                else if (cur == 'v')
                {
                    if (count == 1)
                    {
                        appendGenericZoneText(TextStyle.SHORT);
                    }
                    else if (count == 4)
                    {
                        appendGenericZoneText(TextStyle.FULL);
                    }
                    else
                    {
                        throw new IllegalArgumentException(
                                "Wrong number of  pattern letters: " ~ cur);
                    }
                }
                else if (cur == 'Z')
                {
                    if (count < 4)
                    {
                        appendOffset("+HHMM", "+0000");
                    }
                    else if (count == 4)
                    {
                        appendLocalizedOffset(TextStyle.FULL);
                    }
                    else if (count == 5)
                    {
                        appendOffset("+HH:MM:ss", "Z");
                    }
                    else
                    {
                        throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
                    }
                }
                else if (cur == 'O')
                {
                    if (count == 1)
                    {
                        appendLocalizedOffset(TextStyle.SHORT);
                    }
                    else if (count == 4)
                    {
                        appendLocalizedOffset(TextStyle.FULL);
                    }
                    else
                    {
                        throw new IllegalArgumentException(
                                "Pattern letter count must be 1 or 4: " ~ cur);
                    }
                }
                else if (cur == 'X')
                {
                    if (count > 5)
                    {
                        throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
                    }
                    appendOffset(OffsetIdPrinterParser.PATTERNS[count + (count == 1 ? 0 : 1)], "Z");
                }
                else if (cur == 'x')
                {
                    if (count > 5)
                    {
                        throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
                    }
                    string zero = (count == 1 ? "+00" : (count % 2 == 0 ? "+0000" : "+00:00"));
                    appendOffset(OffsetIdPrinterParser.PATTERNS[count + (count == 1 ? 0 : 1)], zero);
                }
                else if (cur == 'W')
                {
                    // Fields defined by Locale
                    if (count > 1)
                    {
                        throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
                    }
                    appendValue(new WeekBasedFieldPrinterParser(cur, count, count, count));
                }
                else if (cur == 'w')
                {
                    // Fields defined by Locale
                    if (count > 2)
                    {
                        throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
                    }
                    appendValue(new WeekBasedFieldPrinterParser(cur, count, count, 2));
                }
                else if (cur == 'Y')
                {
                    // Fields defined by Locale
                    if (count == 2)
                    {
                        appendValue(new WeekBasedFieldPrinterParser(cur, count, count, 2));
                    }
                    else
                    {
                        appendValue(new WeekBasedFieldPrinterParser(cur, count, count, 19));
                    }
                }
                else
                {
                    throw new IllegalArgumentException("Unknown pattern letter: " ~ cur);
                }
                pos--;

            }
            else if (cur == '\'')
            {
                // parse literals
                int start = pos++;
                for (; pos < pattern.length; pos++)
                {
                    if (pattern[pos] == '\'')
                    {
                        if (pos + 1 < pattern.length && pattern[pos + 1] == '\'')
                        {
                            pos++;
                        }
                        else
                        {
                            break; // end of literal
                        }
                    }
                }
                if (pos >= pattern.length)
                {
                    throw new IllegalArgumentException(
                            "Pattern ends with an incomplete string literal: " ~ pattern);
                }
                string str = pattern.substring(start + 1, pos);
                if (str.length == 0)
                {
                    appendLiteral('\'');
                }
                else
                {
                    import std.array;

                    appendLiteral(str.replace("''", "'"));
                }

            }
            else if (cur == '[')
            {
                optionalStart();

            }
            else if (cur == ']')
            {
                if (active.parent is null)
                {
                    throw new IllegalArgumentException(
                            "Pattern invalid as it contains ] without previous [");
                }
                optionalEnd();

            }
            else if (cur == '{' || cur == '}' || cur == '#')
            {
                throw new IllegalArgumentException(
                        "Pattern includes reserved character: '" ~ cur ~ "'");
            }
            else
            {
                appendLiteral(cur);
            }
        }
    }

    // @SuppressWarnings("fallthrough")
    private void parseField(char cur, int count, TemporalField field)
    {
        bool standalone = false;
        switch (cur)
        {
        case 'u':
        case 'y':
            if (count == 2)
            {
                appendValueReduced(field, 2, 2, ReducedPrinterParser.BASE_DATE);
            }
            else if (count < 4)
            {
                appendValue(field, count, 19, SignStyle.NORMAL);
            }
            else
            {
                appendValue(field, count, 19, SignStyle.EXCEEDS_PAD);
            }
            break;
        case 'c':
            if (count == 1)
            {
                appendValue(new WeekBasedFieldPrinterParser(cur, count, count, count));
                break;
            }
            else if (count == 2)
            {
                throw new IllegalArgumentException("Invalid pattern \"cc\"");
            }
            /*fallthrough*/
            goto case 'L';
        case 'L':
        case 'q':
            standalone = true;
            /*fallthrough*/
            goto case 'M';
        case 'M':
        case 'Q':
        case 'E':
        case 'e':
            switch (count)
            {
            case 1:
            case 2:
                if (cur == 'e')
                {
                    appendValue(new WeekBasedFieldPrinterParser(cur, count, count, count));
                }
                else if (cur == 'E')
                {
                    appendText(field, TextStyle.SHORT);
                }
                else
                {
                    if (count == 1)
                    {
                        appendValue(field);
                    }
                    else
                    {
                        appendValue(field, 2);
                    }
                }
                break;
            case 3:
                appendText(field, standalone ? TextStyle.SHORT_STANDALONE : TextStyle.SHORT);
                break;
            case 4:
                appendText(field, standalone ? TextStyle.FULL_STANDALONE : TextStyle.FULL);
                break;
            case 5:
                appendText(field, standalone ? TextStyle.NARROW_STANDALONE : TextStyle.NARROW);
                break;
            default:
                throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
            }
            break;
        case 'a':
            if (count == 1)
            {
                appendText(field, TextStyle.SHORT);
            }
            else
            {
                throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
            }
            break;
        case 'G':
            switch (count)
            {
            case 1:
            case 2:
            case 3:
                appendText(field, TextStyle.SHORT);
                break;
            case 4:
                appendText(field, TextStyle.FULL);
                break;
            case 5:
                appendText(field, TextStyle.NARROW);
                break;
            default:
                throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
            }
            break;
        case 'S':
            appendFraction(ChronoField.NANO_OF_SECOND, count, count, false);
            break;
        case 'F':
            if (count == 1)
            {
                appendValue(field);
            }
            else
            {
                throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
            }
            break;
        case 'd':
        case 'h':
        case 'H':
        case 'k':
        case 'K':
        case 'm':
        case 's':
            if (count == 1)
            {
                appendValue(field);
            }
            else if (count == 2)
            {
                appendValue(field, count);
            }
            else
            {
                throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
            }
            break;
        case 'D':
            if (count == 1)
            {
                appendValue(field);
            }
            else if (count == 2 || count == 3)
            {
                appendValue(field, count, 3, SignStyle.NOT_NEGATIVE);
            }
            else
            {
                throw new IllegalArgumentException("Too many pattern letters: " ~ cur);
            }
            break;
        case 'g':
            appendValue(field, count, 19, SignStyle.NORMAL);
            break;
        case 'A':
        case 'n':
        case 'N':
            appendValue(field, count, 19, SignStyle.NOT_NEGATIVE);
            break;
        default:
            if (count == 1)
            {
                appendValue(field);
            }
            else
            {
                appendValue(field, count);
            }
            break;
        }
    }

    /** Map of letters to fields. */
    // __gshared Map!(char, TemporalField) FIELD_MAP;

    // shared static this()
    // {
    //     FIELD_MAP = new HashMap!(char, TemporalField)();
        mixin(MakeGlobalVar!(Map!(char, TemporalField))("FIELD_MAP",`new HashMap!(char, TemporalField)()`));
    // }

    static Comparator!(string) LENGTH_SORT;

    // static this()
    // {
    //     LENGTH_SORT = new class Comparator!(string)
    //     {
    //         override public int compare(string str1, string str2)
    //         {
    //             return str1.length == str2.length ? str1.compare(str2)
    //                 : cast(int)(str1.length - str2.length);
    //         }
    //     };
    //     // SDF = SimpleDateFormat
    //     FIELD_MAP.put('G', ChronoField.ERA); // SDF, LDML (different to both for 1/2 chars)
    //     FIELD_MAP.put('y', ChronoField.YEAR_OF_ERA); // SDF, LDML
    //     FIELD_MAP.put('u', ChronoField.YEAR); // LDML (different _in SDF)
    //     FIELD_MAP.put('Q', IsoFields.QUARTER_OF_YEAR); // LDML (removed quarter from 310)
    //     FIELD_MAP.put('q', IsoFields.QUARTER_OF_YEAR); // LDML (stand-alone)
    //     FIELD_MAP.put('M', ChronoField.MONTH_OF_YEAR); // SDF, LDML
    //     FIELD_MAP.put('L', ChronoField.MONTH_OF_YEAR); // SDF, LDML (stand-alone)
    //     FIELD_MAP.put('D', ChronoField.DAY_OF_YEAR); // SDF, LDML
    //     FIELD_MAP.put('d', ChronoField.DAY_OF_MONTH); // SDF, LDML
    //     FIELD_MAP.put('F', ChronoField.ALIGNED_DAY_OF_WEEK_IN_MONTH); // SDF, LDML
    //     FIELD_MAP.put('E', ChronoField.DAY_OF_WEEK); // SDF, LDML (different to both for 1/2 chars)
    //     FIELD_MAP.put('c', ChronoField.DAY_OF_WEEK); // LDML (stand-alone)
    //     FIELD_MAP.put('e', ChronoField.DAY_OF_WEEK); // LDML (needs localized week number)
    //     FIELD_MAP.put('a', ChronoField.AMPM_OF_DAY); // SDF, LDML
    //     FIELD_MAP.put('H', ChronoField.HOUR_OF_DAY); // SDF, LDML
    //     FIELD_MAP.put('k', ChronoField.CLOCK_HOUR_OF_DAY); // SDF, LDML
    //     FIELD_MAP.put('K', ChronoField.HOUR_OF_AMPM); // SDF, LDML
    //     FIELD_MAP.put('h', ChronoField.CLOCK_HOUR_OF_AMPM); // SDF, LDML
    //     FIELD_MAP.put('m', ChronoField.MINUTE_OF_HOUR); // SDF, LDML
    //     FIELD_MAP.put('s', ChronoField.SECOND_OF_MINUTE); // SDF, LDML
    //     FIELD_MAP.put('S', ChronoField.NANO_OF_SECOND); // LDML (SDF uses milli-of-second number)
    //     FIELD_MAP.put('A', ChronoField.MILLI_OF_DAY); // LDML
    //     FIELD_MAP.put('n', ChronoField.NANO_OF_SECOND); // 310 (proposed for LDML)
    //     FIELD_MAP.put('N', ChronoField.NANO_OF_DAY); // 310 (proposed for LDML)
    //     // FIELD_MAP.put('g', JulianFields.MODIFIED_JULIAN_DAY);
    //     // 310 - z - time-zone names, matches LDML and SimpleDateFormat 1 to 4
    //     // 310 - Z - matches SimpleDateFormat and LDML
    //     // 310 - V - time-zone id, matches LDML
    //     // 310 - v - general timezone names, not matching exactly with LDML because LDML specify to fall back
    //     //           to 'VVVV' if general-nonlocation unavailable but here it's not falling back because of lack of data
    //     // 310 - p - prefix for padding
    //     // 310 - X - matches LDML, almost matches SDF for 1, exact match 2&3, extended 4&5
    //     // 310 - x - matches LDML
    //     // 310 - w, W, and Y are localized forms matching LDML
    //     // LDML - U - cycle year name, not supported by 310 yet
    //     // LDML - l - deprecated
    //     // LDML - j - not relevant
    // }

    //-----------------------------------------------------------------------
    /**
     * Causes the next added printer/parser to pad to a fixed width using a space.
     * !(p)
     * This padding will pad to a fixed width using spaces.
     * !(p)
     * During formatting, the decorated element will be output and then padded
     * to the specified width. An exception will be thrown during formatting if
     * the pad width is exceeded.
     * !(p)
     * During parsing, the padding and decorated element are parsed.
     * If parsing is lenient, then the pad width is treated as a maximum.
     * The padding is parsed greedily. Thus, if the decorated element starts with
     * the pad character, it will not be parsed.
     *
     * @param padWidth  the pad width, 1 or greater
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if pad width is too small
     */
    public DateTimeFormatterBuilder padNext(int padWidth)
    {
        return padNext(padWidth, ' ');
    }

    /**
     * Causes the next added printer/parser to pad to a fixed width.
     * !(p)
     * This padding is intended for padding other than zero-padding.
     * Zero-padding should be achieved using the appendValue methods.
     * !(p)
     * During formatting, the decorated element will be output and then padded
     * to the specified width. An exception will be thrown during formatting if
     * the pad width is exceeded.
     * !(p)
     * During parsing, the padding and decorated element are parsed.
     * If parsing is lenient, then the pad width is treated as a maximum.
     * If parsing is case insensitive, then the pad character is matched ignoring case.
     * The padding is parsed greedily. Thus, if the decorated element starts with
     * the pad character, it will not be parsed.
     *
     * @param padWidth  the pad width, 1 or greater
     * @param padChar  the pad character
     * @return this, for chaining, not null
     * @throws IllegalArgumentException if pad width is too small
     */
    public DateTimeFormatterBuilder padNext(int padWidth, char padChar)
    {
        if (padWidth < 1)
        {
            throw new IllegalArgumentException(
                    "The pad width must be at least one but was " ~ padWidth.to!string);
        }
        active.padNextWidth = padWidth;
        active.padNextChar = padChar;
        active.valueParserIndex = -1;
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Mark the start of an optional section.
     * !(p)
     * The output of formatting can include optional sections, which may be nested.
     * An optional section is started by calling this method and ended by calling
     * {@link #optionalEnd()} or by ending the build process.
     * !(p)
     * All elements _in the optional section are treated as optional.
     * During formatting, the section is only output if data is available _in the
     * {@code TemporalAccessor} for all the elements _in the section.
     * During parsing, the whole section may be missing from the parsed string.
     * !(p)
     * For example, consider a builder setup as
     * {@code builder.appendValue(HOUR_OF_DAY,2).optionalStart().appendValue(MINUTE_OF_HOUR,2)}.
     * The optional section ends automatically at the end of the builder.
     * During formatting, the minute will only be output if its value can be obtained from the date-time.
     * During parsing, the input will be successfully parsed whether the minute is present or not.
     *
     * @return this, for chaining, not null
     */
    public DateTimeFormatterBuilder optionalStart()
    {
        active.valueParserIndex = -1;

        _active = new DateTimeFormatterBuilder(active, true);
        // tmp.optional = true;
        // tmp.parent = this;
        // active = tmp;
        return this;
    }

    /**
     * Ends an optional section.
     * !(p)
     * The output of formatting can include optional sections, which may be nested.
     * An optional section is started by calling {@link #optionalStart()} and ended
     * using this method (or at the end of the builder).
     * !(p)
     * Calling this method without having previously called {@code optionalStart}
     * will throw an exception.
     * Calling this method immediately after calling {@code optionalStart} has no effect
     * on the formatter other than ending the (empty) optional section.
     * !(p)
     * All elements _in the optional section are treated as optional.
     * During formatting, the section is only output if data is available _in the
     * {@code TemporalAccessor} for all the elements _in the section.
     * During parsing, the whole section may be missing from the parsed string.
     * !(p)
     * For example, consider a builder setup as
     * {@code builder.appendValue(HOUR_OF_DAY,2).optionalStart().appendValue(MINUTE_OF_HOUR,2).optionalEnd()}.
     * During formatting, the minute will only be output if its value can be obtained from the date-time.
     * During parsing, the input will be successfully parsed whether the minute is present or not.
     *
     * @return this, for chaining, not null
     * @throws IllegalStateException if there was no previous call to {@code optionalStart}
     */
    public DateTimeFormatterBuilder optionalEnd()
    {
        if (active.parent is null)
        {
            throw new IllegalStateException(
                    "Cannot call optionalEnd() as there was no previous call to optionalStart()");
        }
        if (active.printerParsers.size() > 0)
        {
            CompositePrinterParser cpp = new CompositePrinterParser(active.printerParsers,
                    active.optional);
            _active = active.parent;
            appendInternal(cpp);
        }
        else
        {
            _active = active.parent;
        }
        return this;
    }

    //-----------------------------------------------------------------------
    /**
     * Appends a printer and/or parser to the internal list handling padding.
     *
     * @param pp  the printer-parser to add, not null
     * @return the index into the active parsers list
     */
    private int appendInternal(DateTimePrinterParser pp)
    {
        assert(pp, "pp");
        if (active.padNextWidth > 0)
        {
            if (pp !is null)
            {
                pp = new PadPrinterParserDecorator(pp, active.padNextWidth, active.padNextChar);
            }
            active.padNextWidth = 0;
            active.padNextChar = 0;
        }
        active.printerParsers.add(pp);
        active.valueParserIndex = -1;
        return active.printerParsers.size() - 1;
    }

    //-----------------------------------------------------------------------
    /**
     * Completes this builder by creating the {@code DateTimeFormatter}
     * using the default locale.
     * !(p)
     * This will create a formatter with the {@linkplain Locale#getDefault(Locale.Category) default FORMAT locale}.
     * Numbers will be printed and parsed using the standard DecimalStyle.
     * The resolver style will be {@link ResolverStyle#SMART SMART}.
     * !(p)
     * Calling this method will end any open optional sections by repeatedly
     * calling {@link #optionalEnd()} before creating the formatter.
     * !(p)
     * This builder can still be used after creating the formatter if desired,
     * although the state may have been changed by calls to {@code optionalEnd}.
     *
     * @return the created formatter, not null
     */
    public DateTimeFormatter toFormatter()
    {
        ///@gxc
        // return toFormatter(Locale.getDefault(Locale.Category.FORMAT));
        return toFormatter(Locale.CHINESE);

        // implementationMissing();
        // return null;
    }

    /**
     * Completes this builder by creating the {@code DateTimeFormatter}
     * using the specified locale.
     * !(p)
     * This will create a formatter with the specified locale.
     * Numbers will be printed and parsed using the standard DecimalStyle.
     * The resolver style will be {@link ResolverStyle#SMART SMART}.
     * !(p)
     * Calling this method will end any open optional sections by repeatedly
     * calling {@link #optionalEnd()} before creating the formatter.
     * !(p)
     * This builder can still be used after creating the formatter if desired,
     * although the state may have been changed by calls to {@code optionalEnd}.
     *
     * @param locale  the locale to use for formatting, not null
     * @return the created formatter, not null
     */
    public DateTimeFormatter toFormatter(Locale locale)
    {
        return toFormatter(locale, ResolverStyle.SMART, null);
    }

    /**
     * Completes this builder by creating the formatter.
     * This uses the default locale.
     *
     * @param resolverStyle  the resolver style to use, not null
     * @return the created formatter, not null
     */
    DateTimeFormatter toFormatter(ResolverStyle resolverStyle, Chronology chrono)
    {
        //@gxc
        // return toFormatter(Locale.getDefault(Locale.Category.FORMAT), resolverStyle, chrono);
        return toFormatter(Locale.CHINESE, resolverStyle, chrono);

        // implementationMissing();
        // return null;
    }

    /**
     * Completes this builder by creating the formatter.
     *
     * @param locale  the locale to use for formatting, not null
     * @param chrono  the chronology to use, may be null
     * @return the created formatter, not null
     */
    private DateTimeFormatter toFormatter(Locale locale,
            ResolverStyle resolverStyle, Chronology chrono)
    {
        assert(locale, "locale");
        while (active.parent !is null)
        {
            optionalEnd();
        }
        CompositePrinterParser pp = new CompositePrinterParser(printerParsers, false);
        return new DateTimeFormatter(pp, locale, DecimalStyle.STANDARD,
                resolverStyle, null, chrono, null);
    }
        
    //-------------------------------------------------------------------------
    /**
     * Length comparator.
     */

    }
