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

module hunt.time.chrono.Chronology;

import hunt.time.temporal.ChronoField;

import hunt.time.Clock;
import hunt.time.DateTimeException;
import hunt.time.Instant;
import hunt.time.LocalDate;
import hunt.time.LocalTime;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
// import hunt.time.format.DateTimeFormatterBuilder;
import hunt.time.format.ResolverStyle;
import hunt.time.format.TextStyle;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.time.temporal.ValueRange;
import hunt.collection.List;
import hunt.time.util.Locale;
import hunt.collection.Map;
import hunt.Functions;
import hunt.collection.Set;
import hunt.time.chrono.ChronoLocalDate;
import hunt.time.chrono.Era;
import hunt.time.chrono.ChronoZonedDateTime;
import hunt.time.chrono.ChronoLocalDateTime;
// import hunt.lang;
import hunt.time.chrono.ChronoPeriod;
import hunt.time.chrono.AbstractChronology;
import hunt.time.chrono.IsoChronology;
import hunt.time.util.QueryHelper;


/**
 * A calendar system, used to organize and identify dates.
 * !(p)
 * The main date and time API is built on the ISO calendar system.
 * The chronology operates behind the scenes to represent the general concept of a calendar system.
 * For example, the Japanese, Minguo, Thai Buddhist and others.
 * !(p)
 * Most other calendar systems also operate on the shared concepts of year, month and day,
 * linked to the cycles of the Earth around the Sun, and the Moon around the Earth.
 * These shared concepts are defined by {@link ChronoField} and are available
 * for use by any {@code Chronology} implementation:
 * !(pre)
 *   LocalDate isoDate = ...
 *   ThaiBuddhistDate thaiDate = ...
 *   int isoYear = isoDate.get(ChronoField.YEAR);
 *   int thaiYear = thaiDate.get(ChronoField.YEAR);
 * </pre>
 * As shown, although the date objects are _in different calendar systems, represented by different
 * {@code Chronology} instances, both can be queried using the same constant on {@code ChronoField}.
 * For a full discussion of the implications of this, see {@link ChronoLocalDate}.
 * In general, the advice is to use the known ISO-based {@code LocalDate}, rather than
 * {@code ChronoLocalDate}.
 * !(p)
 * While a {@code Chronology} object typically uses {@code ChronoField} and is based on
 * an era, year-of-era, month-of-year, day-of-month model of a date, this is not required.
 * A {@code Chronology} instance may represent a totally different kind of calendar system,
 * such as the Mayan.
 * !(p)
 * In practical terms, the {@code Chronology} instance also acts as a factory.
 * The {@link #of(string)} method allows an instance to be looked up by identifier,
 * while the {@link #ofLocale(Locale)} method allows lookup by locale.
 * !(p)
 * The {@code Chronology} instance provides a set of methods to create {@code ChronoLocalDate} instances.
 * The date classes are used to manipulate specific dates.
 * !(ul)
 * !(li) {@link #dateNow() dateNow()}
 * !(li) {@link #dateNow(Clock) dateNow(clock)}
 * !(li) {@link #dateNow(ZoneId) dateNow(zone)}
 * !(li) {@link #date(int, int, int) date(yearProleptic, month, day)}
 * !(li) {@link #date(Era, int, int, int) date(era, yearOfEra, month, day)}
 * !(li) {@link #dateYearDay(int, int) dateYearDay(yearProleptic, dayOfYear)}
 * !(li) {@link #dateYearDay(Era, int, int) dateYearDay(era, yearOfEra, dayOfYear)}
 * !(li) {@link #date(TemporalAccessor) date(TemporalAccessor)}
 * </ul>
 *
 * <h3 id="addcalendars">Adding New Calendars</h3>
 * The set of available chronologies can be extended by applications.
 * Adding a new calendar system requires the writing of an implementation of
 * {@code Chronology}, {@code ChronoLocalDate} and {@code Era}.
 * The majority of the logic specific to the calendar system will be _in the
 * {@code ChronoLocalDate} implementation.
 * The {@code Chronology} implementation acts as a factory.
 * !(p)
 * To permit the discovery of additional chronologies, the {@link java.util.ServiceLoader ServiceLoader}
 * is used. A file must be added to the {@code META-INF/services} directory with the
 * name 'hunt.time.chrono.Chronology' listing the implementation classes.
 * See the ServiceLoader for more details on service loading.
 * For lookup by id or calendarType, the system provided calendars are found
 * first followed by application provided calendars.
 * !(p)
 * Each chronology must define a chronology ID that is unique within the system.
 * If the chronology represents a calendar system defined by the
 * CLDR specification then the calendar type is the concatenation of the
 * CLDR type and, if applicable, the CLDR variant.
 *
 * @implSpec
 * This interface must be implemented with care to ensure other classes operate correctly.
 * All implementations that can be instantiated must be final, immutable and thread-safe.
 * Subclasses should be Serializable wherever possible.
 *
 * @since 1.8
 */
public interface Chronology : Comparable!(Chronology) {

    /**
     * Obtains an instance of {@code Chronology} from a temporal object.
     * !(p)
     * This obtains a chronology based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code Chronology}.
     * !(p)
     * The conversion will obtain the chronology using {@link TemporalQueries#chronology()}.
     * If the specified temporal object does not have a chronology, {@link IsoChronology} is returned.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code Chronology::from}.
     *
     * @param temporal  the temporal to convert, not null
     * @return the chronology, not null
     * @throws DateTimeException if unable to convert to a {@code Chronology}
     */
    static Chronology from(TemporalAccessor temporal) {
        assert(temporal, "temporal");
        Chronology obj = QueryHelper.query!Chronology(temporal,TemporalQueries.chronology());
        return obj !is null ? obj : IsoChronology.INSTANCE;
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Chronology} from a locale.
     * !(p)
     * This returns a {@code Chronology} based on the specified locale,
     * typically returning {@code IsoChronology}. Other calendar systems
     * are only returned if they are explicitly selected within the locale.
     * !(p)
     * The {@link Locale} class provide access to a range of information useful
     * for localizing an application. This includes the language and region,
     * such as "en-GB" for English as used _in Great Britain.
     * !(p)
     * The {@code Locale} class also supports an extension mechanism that
     * can be used to identify a calendar system. The mechanism is a form
     * of key-value pairs, where the calendar system has the key "ca".
     * For example, the locale "en-JP-u-ca-japanese" represents the English
     * language as used _in Japan with the Japanese calendar system.
     * !(p)
     * This method finds the desired calendar system _in a manner equivalent
     * to passing "ca" to {@link Locale#getUnicodeLocaleType(string)}.
     * If the "ca" key is not present, then {@code IsoChronology} is returned.
     * !(p)
     * Note that the behavior of this method differs from the older
     * {@link java.util.Calendar#getInstance(Locale)} method.
     * If that method receives a locale of "th_TH" it will return {@code BuddhistCalendar}.
     * By contrast, this method will return {@code IsoChronology}.
     * Passing the locale "th-TH-u-ca-buddhist" into either method will
     * result _in the Thai Buddhist calendar system and is therefore the
     * recommended approach going forward for Thai calendar system localization.
     * !(p)
     * A similar, but simpler, situation occurs for the Japanese calendar system.
     * The locale "jp_JP_JP" has previously been used to access the calendar.
     * However, unlike the Thai locale, "ja_JP_JP" is automatically converted by
     * {@code Locale} to the modern and recommended form of "ja-JP-u-ca-japanese".
     * Thus, there is no difference _in behavior between this method and
     * {@code Calendar#getInstance(Locale)}.
     *
     * @param locale  the locale to use to obtain the calendar system, not null
     * @return the calendar system associated with the locale, not null
     * @throws DateTimeException if the locale-specified calendar cannot be found
     */
    static Chronology ofLocale(Locale locale) {
        return AbstractChronology.ofLocale(locale);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Chronology} from a chronology ID or
     * calendar system type.
     * !(p)
     * This returns a chronology based on either the ID or the type.
     * The {@link #getId() chronology ID} uniquely identifies the chronology.
     * The {@link #getCalendarType() calendar system type} is defined by the
     * CLDR specification.
     * !(p)
     * The chronology may be a system chronology or a chronology
     * provided by the application via ServiceLoader configuration.
     * !(p)
     * Since some calendars can be customized, the ID or type typically refers
     * to the  customization. For example, the Gregorian calendar can have multiple
     * cutover dates from the Julian, but the lookup only provides the  cutover date.
     *
     * @param id  the chronology ID or calendar system type, not null
     * @return the chronology with the identifier requested, not null
     * @throws DateTimeException if the chronology cannot be found
     */
    static Chronology of(string id) {
        return AbstractChronology.of(id);
    }

    /**
     * Returns the available chronologies.
     * !(p)
     * Each returned {@code Chronology} is available for use _in the system.
     * The set of chronologies includes the system chronologies and
     * any chronologies provided by the application via ServiceLoader
     * configuration.
     *
     * @return the independent, modifiable set of the available chronology IDs, not null
     */
    static Set!(Chronology) getAvailableChronologies() {
        return AbstractChronology.getAvailableChronologies();
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the ID of the chronology.
     * !(p)
     * The ID uniquely identifies the {@code Chronology}.
     * It can be used to lookup the {@code Chronology} using {@link #of(string)}.
     *
     * @return the chronology ID, not null
     * @see #getCalendarType()
     */
    string getId();

    /**
     * Gets the calendar type of the calendar system.
     * !(p)
     * The calendar type is an identifier defined by the CLDR and
     * !(em)Unicode Locale Data Markup Language (LDML)</em> specifications
     * to uniquely identify a calendar.
     * The {@code getCalendarType} is the concatenation of the CLDR calendar type
     * and the variant, if applicable, is appended separated by "-".
     * The calendar type is used to lookup the {@code Chronology} using {@link #of(string)}.
     *
     * @return the calendar system type, null if the calendar is not defined by CLDR/LDML
     * @see #getId()
     */
    string getCalendarType();

    //-----------------------------------------------------------------------
    /**
     * Obtains a local date _in this chronology from the era, year-of-era,
     * month-of-year and day-of-month fields.
     *
     * @implSpec
     * The  implementation combines the era and year-of-era into a proleptic
     * year before calling {@link #date(int, int, int)}.
     *
     * @param era  the era of the correct type for the chronology, not null
     * @param yearOfEra  the chronology year-of-era
     * @param month  the chronology month-of-year
     * @param dayOfMonth  the chronology day-of-month
     * @return the local date _in this chronology, not null
     * @throws DateTimeException if unable to create the date
     * @throws ClassCastException if the {@code era} is not of the correct type for the chronology
     */
     ChronoLocalDate date(Era era, int yearOfEra, int month, int dayOfMonth);
    //  ChronoLocalDate date(Era era, int yearOfEra, int month, int dayOfMonth) {
    //     return date(prolepticYear(era, yearOfEra), month, dayOfMonth);
    // }

    /**
     * Obtains a local date _in this chronology from the proleptic-year,
     * month-of-year and day-of-month fields.
     *
     * @param prolepticYear  the chronology proleptic-year
     * @param month  the chronology month-of-year
     * @param dayOfMonth  the chronology day-of-month
     * @return the local date _in this chronology, not null
     * @throws DateTimeException if unable to create the date
     */
    ChronoLocalDate date(int prolepticYear, int month, int dayOfMonth);

    /**
     * Obtains a local date _in this chronology from the era, year-of-era and
     * day-of-year fields.
     *
     * @implSpec
     * The  implementation combines the era and year-of-era into a proleptic
     * year before calling {@link #dateYearDay(int, int)}.
     *
     * @param era  the era of the correct type for the chronology, not null
     * @param yearOfEra  the chronology year-of-era
     * @param dayOfYear  the chronology day-of-year
     * @return the local date _in this chronology, not null
     * @throws DateTimeException if unable to create the date
     * @throws ClassCastException if the {@code era} is not of the correct type for the chronology
     */
     ChronoLocalDate dateYearDay(Era era, int yearOfEra, int dayOfYear);
    //  ChronoLocalDate dateYearDay(Era era, int yearOfEra, int dayOfYear) {
    //     return dateYearDay(prolepticYear(era, yearOfEra), dayOfYear);
    // }

    /**
     * Obtains a local date _in this chronology from the proleptic-year and
     * day-of-year fields.
     *
     * @param prolepticYear  the chronology proleptic-year
     * @param dayOfYear  the chronology day-of-year
     * @return the local date _in this chronology, not null
     * @throws DateTimeException if unable to create the date
     */
    ChronoLocalDate dateYearDay(int prolepticYear, int dayOfYear);

    /**
     * Obtains a local date _in this chronology from the epoch-day.
     * !(p)
     * The definition of {@link ChronoField#EPOCH_DAY EPOCH_DAY} is the same
     * for all calendar systems, thus it can be used for conversion.
     *
     * @param epochDay  the epoch day
     * @return the local date _in this chronology, not null
     * @throws DateTimeException if unable to create the date
     */
    ChronoLocalDate dateEpochDay(long epochDay);

    //-----------------------------------------------------------------------
    /**
     * Obtains the current local date _in this chronology from the system clock _in the  time-zone.
     * !(p)
     * This will query the {@link Clock#systemDefaultZone() system clock} _in the 
     * time-zone to obtain the current date.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @implSpec
     * The  implementation invokes {@link #dateNow(Clock)}.
     *
     * @return the current local date using the system clock and  time-zone, not null
     * @throws DateTimeException if unable to create the date
     */
     ChronoLocalDate dateNow();
    //  ChronoLocalDate dateNow() {
    //     return dateNow(Clock.systemDefaultZone());
    // }

    /**
     * Obtains the current local date _in this chronology from the system clock _in the specified time-zone.
     * !(p)
     * This will query the {@link Clock#system(ZoneId) system clock} to obtain the current date.
     * Specifying the time-zone avoids dependence on the  time-zone.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @implSpec
     * The  implementation invokes {@link #dateNow(Clock)}.
     *
     * @param zone  the zone ID to use, not null
     * @return the current local date using the system clock, not null
     * @throws DateTimeException if unable to create the date
     */
     ChronoLocalDate dateNow(ZoneId zone);
    //  ChronoLocalDate dateNow(ZoneId zone) {
    //     return dateNow(Clock.system(zone));
    // }

    /**
     * Obtains the current local date _in this chronology from the specified clock.
     * !(p)
     * This will query the specified clock to obtain the current date - today.
     * Using this method allows the use of an alternate clock for testing.
     * The alternate clock may be introduced using {@link Clock dependency injection}.
     *
     * @implSpec
     * The  implementation invokes {@link #date(TemporalAccessor)}.
     *
     * @param clock  the clock to use, not null
     * @return the current local date, not null
     * @throws DateTimeException if unable to create the date
     */
     ChronoLocalDate dateNow(Clock clock);
    //  ChronoLocalDate dateNow(Clock clock) {
    //     assert(clock, "clock");
    //     return date(LocalDate.now(clock));
    // }

    //-----------------------------------------------------------------------
    /**
     * Obtains a local date _in this chronology from another temporal object.
     * !(p)
     * This obtains a date _in this chronology based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code ChronoLocalDate}.
     * !(p)
     * The conversion typically uses the {@link ChronoField#EPOCH_DAY EPOCH_DAY}
     * field, which is standardized across calendar systems.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code aChronology::date}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the local date _in this chronology, not null
     * @throws DateTimeException if unable to create the date
     * @see ChronoLocalDate#from(TemporalAccessor)
     */
    ChronoLocalDate date(TemporalAccessor temporal);

    /**
     * Obtains a local date-time _in this chronology from another temporal object.
     * !(p)
     * This obtains a date-time _in this chronology based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code ChronoLocalDateTime}.
     * !(p)
     * The conversion extracts and combines the {@code ChronoLocalDate} and the
     * {@code LocalTime} from the temporal object.
     * Implementations are permitted to perform optimizations such as accessing
     * those fields that are equivalent to the relevant objects.
     * The result uses this chronology.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code aChronology::localDateTime}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the local date-time _in this chronology, not null
     * @throws DateTimeException if unable to create the date-time
     * @see ChronoLocalDateTime#from(TemporalAccessor)
     */
     ChronoLocalDateTime!(ChronoLocalDate) localDateTime(TemporalAccessor temporal);
    //  ChronoLocalDateTime!(ChronoLocalDate) localDateTime(TemporalAccessor temporal) {
    //     try {
    //         return date(temporal).atTime(LocalTime.from(temporal));
    //     } catch (DateTimeException ex) {
    //         throw new DateTimeException("Unable to obtain ChronoLocalDateTime from TemporalAccessor: " ~ typeid(temporal).stringof, ex);
    //     }
    // }

    /**
     * Obtains a {@code ChronoZonedDateTime} _in this chronology from another temporal object.
     * !(p)
     * This obtains a zoned date-time _in this chronology based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code ChronoZonedDateTime}.
     * !(p)
     * The conversion will first obtain a {@code ZoneId} from the temporal object,
     * falling back to a {@code ZoneOffset} if necessary. It will then try to obtain
     * an {@code Instant}, falling back to a {@code ChronoLocalDateTime} if necessary.
     * The result will be either the combination of {@code ZoneId} or {@code ZoneOffset}
     * with {@code Instant} or {@code ChronoLocalDateTime}.
     * Implementations are permitted to perform optimizations such as accessing
     * those fields that are equivalent to the relevant objects.
     * The result uses this chronology.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code aChronology::zonedDateTime}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the zoned date-time _in this chronology, not null
     * @throws DateTimeException if unable to create the date-time
     * @see ChronoZonedDateTime#from(TemporalAccessor)
     */
     ChronoZonedDateTime!(ChronoLocalDate) zonedDateTime(TemporalAccessor temporal);
    //  ChronoZonedDateTime!(ChronoLocalDate) zonedDateTime(TemporalAccessor temporal) {
    //     try {
    //         ZoneId zone = ZoneId.from(temporal);
    //         try {
    //             Instant instant = Instant.from(temporal);
    //             return zonedDateTime(instant, zone);

    //         } catch (DateTimeException ex1) {
    //             ChronoLocalDateTimeImpl!(Object) cldt = ChronoLocalDateTimeImpl.ensureValid(this, localDateTime(temporal));
    //             return ChronoZonedDateTimeImpl.ofBest(cldt, zone, null);
    //         }
    //     } catch (DateTimeException ex) {
    //         throw new DateTimeException("Unable to obtain ChronoZonedDateTime from TemporalAccessor: " ~ typeid(temporal).stringof, ex);
    //     }
    // }

    /**
     * Obtains a {@code ChronoZonedDateTime} _in this chronology from an {@code Instant}.
     * !(p)
     * This obtains a zoned date-time with the same instant as that specified.
     *
     * @param instant  the instant to create the date-time from, not null
     * @param zone  the time-zone, not null
     * @return the zoned date-time, not null
     * @throws DateTimeException if the result exceeds the supported range
     */
     ChronoZonedDateTime!(ChronoLocalDate) zonedDateTime(Instant instant, ZoneId zone);
    //  ChronoZonedDateTime!(ChronoLocalDate) zonedDateTime(Instant instant, ZoneId zone) {
    //     return ChronoZonedDateTimeImpl.ofInstant(this, instant, zone);
    // }

    //-----------------------------------------------------------------------
    /**
     * Checks if the specified year is a leap year.
     * !(p)
     * A leap-year is a year of a longer length than normal.
     * The exact meaning is determined by the chronology according to the following constraints.
     * !(ul)
     * !(li)a leap-year must imply a year-length longer than a non leap-year.
     * !(li)a chronology that does not support the concept of a year must return false.
     * !(li)the correct result must be returned for all years within the
     *     valid range of years for the chronology.
     * </ul>
     * !(p)
     * Outside the range of valid years an implementation is free to return
     * either a best guess or false.
     * An implementation must not throw an exception, even if the year is
     * outside the range of valid years.
     *
     * @param prolepticYear  the proleptic-year to check, not validated for range
     * @return true if the year is a leap year
     */
    bool isLeapYear(long prolepticYear);

    /**
     * Calculates the proleptic-year given the era and year-of-era.
     * !(p)
     * This combines the era and year-of-era into the single proleptic-year field.
     * !(p)
     * If the chronology makes active use of eras, such as {@code JapaneseChronology}
     * then the year-of-era will be validated against the era.
     * For other chronologies, validation is optional.
     *
     * @param era  the era of the correct type for the chronology, not null
     * @param yearOfEra  the chronology year-of-era
     * @return the proleptic-year
     * @throws DateTimeException if unable to convert to a proleptic-year,
     *  such as if the year is invalid for the era
     * @throws ClassCastException if the {@code era} is not of the correct type for the chronology
     */
    int prolepticYear(Era era, int yearOfEra);

    /**
     * Creates the chronology era object from the numeric value.
     * !(p)
     * The era is, conceptually, the largest division of the time-line.
     * Most calendar systems have a single epoch dividing the time-line into two eras.
     * However, some have multiple eras, such as one for the reign of each leader.
     * The exact meaning is determined by the chronology according to the following constraints.
     * !(p)
     * The era _in use at 1970-01-01 must have the value 1.
     * Later eras must have sequentially higher values.
     * Earlier eras must have sequentially lower values.
     * Each chronology must refer to an enum or similar singleton to provide the era values.
     * !(p)
     * This method returns the singleton era of the correct type for the specified era value.
     *
     * @param eraValue  the era value
     * @return the calendar system era, not null
     * @throws DateTimeException if unable to create the era
     */
    Era eraOf(int eraValue);

    /**
     * Gets the list of eras for the chronology.
     * !(p)
     * Most calendar systems have an era, within which the year has meaning.
     * If the calendar system does not support the concept of eras, an empty
     * list must be returned.
     *
     * @return the list of eras for the chronology, may be immutable, not null
     */
    List!(Era) eras();

    //-----------------------------------------------------------------------
    /**
     * Gets the range of valid values for the specified field.
     * !(p)
     * All fields can be expressed as a {@code long} integer.
     * This method returns an object that describes the valid range for that value.
     * !(p)
     * Note that the result only describes the minimum and maximum valid values
     * and it is important not to read too much into them. For example, there
     * could be values within the range that are invalid for the field.
     * !(p)
     * This method will return a result whether or not the chronology supports the field.
     *
     * @param field  the field to get the range for, not null
     * @return the range of valid values for the field, not null
     * @throws DateTimeException if the range for the field cannot be obtained
     */
    ValueRange range(ChronoField field);

    //-----------------------------------------------------------------------
    /**
     * Gets the textual representation of this chronology.
     * !(p)
     * This returns the textual name used to identify the chronology,
     * suitable for presentation to the user.
     * The parameters control the style of the returned text and the locale.
     *
     * @implSpec
     * The  implementation behaves as though the formatter was used to
     * format the chronology textual name.
     *
     * @param style  the style of the text required, not null
     * @param locale  the locale to use, not null
     * @return the text value of the chronology, not null
     */
    //  string getDisplayName(TextStyle style, Locale locale);
    //  string getDisplayName(TextStyle style, Locale locale) {
    //     TemporalAccessor temporal = new class TemporalAccessor{
    //         override
    //         public bool isSupported(TemporalField field) {
    //             return false;
    //         }
    //         override
    //         public long getLong(TemporalField field) {
    //             throw new UnsupportedTemporalTypeException("Unsupported field: " ~ field);
    //         }
    //         /*@SuppressWarnings("unchecked")*/
    //         override
    //         public  R query(TemporalQuery!(R) query) {
    //             if (query == TemporalQueries.chronology()) {
    //                 return cast(R) /* Chronology. */this;
    //             }
    //             return /* TemporalAccessor. */super.query(query);
    //         }
    //     };
    //     return new DateTimeFormatterBuilder().appendChronologyText(style).toFormatter(locale).format(temporal);
    // }

    //-----------------------------------------------------------------------
    /**
     * Resolves parsed {@code ChronoField} values into a date during parsing.
     * !(p)
     * Most {@code TemporalField} implementations are resolved using the
     * resolve method on the field. By contrast, the {@code ChronoField} class
     * defines fields that only have meaning relative to the chronology.
     * As such, {@code ChronoField} date fields are resolved here _in the
     * context of a specific chronology.
     * !(p)
     * The  implementation, which explains typical resolve behaviour,
     * is provided _in {@link AbstractChronology}.
     *
     * @param fieldValues  the map of fields to values, which can be updated, not null
     * @param resolverStyle  the requested type of resolve, not null
     * @return the resolved date, null if insufficient information to create a date
     * @throws DateTimeException if the date cannot be resolved, typically
     *  because of a conflict _in the input data
     */
    ChronoLocalDate resolveDate(Map!(TemporalField, Long) fieldValues, ResolverStyle resolverStyle);

    //-----------------------------------------------------------------------
    /**
     * Obtains a period for this chronology based on years, months and days.
     * !(p)
     * This returns a period tied to this chronology using the specified
     * years, months and days.  All supplied chronologies use periods
     * based on years, months and days, however the {@code ChronoPeriod} API
     * allows the period to be represented using other units.
     *
     * @implSpec
     * The  implementation returns an implementation class suitable
     * for most calendar systems. It is based solely on the three units.
     * Normalization, addition and subtraction derive the number of months
     * _in a year from the {@link #range(ChronoField)}. If the number of
     * months within a year is fixed, then the calculation approach for
     * addition, subtraction and normalization is slightly different.
     * !(p)
     * If implementing an unusual calendar system that is not based on
     * years, months and days, or where you want direct control, then
     * the {@code ChronoPeriod} interface must be directly implemented.
     * !(p)
     * The returned period is immutable and thread-safe.
     *
     * @param years  the number of years, may be negative
     * @param months  the number of years, may be negative
     * @param days  the number of years, may be negative
     * @return the period _in terms of this chronology, not null
     */
     ChronoPeriod period(int years, int months, int days);
    //  ChronoPeriod period(int years, int months, int days) {
    //     return new ChronoPeriodImpl(this, years, months, days);
    // }

    //---------------------------------------------------------------------

    /**
     * Gets the number of seconds from the epoch of 1970-01-01T00:00:00Z.
     * !(p)
     * The number of seconds is calculated using the proleptic-year,
     * month, day-of-month, hour, minute, second, and zoneOffset.
     *
     * @param prolepticYear the chronology proleptic-year
     * @param month the chronology month-of-year
     * @param dayOfMonth the chronology day-of-month
     * @param hour the hour-of-day, from 0 to 23
     * @param minute the minute-of-hour, from 0 to 59
     * @param second the second-of-minute, from 0 to 59
     * @param zoneOffset the zone offset, not null
     * @return the number of seconds relative to 1970-01-01T00:00:00Z, may be negative
     * @throws DateTimeException if any of the values are _out of range
     * @since 9
     */
      long epochSecond(int prolepticYear, int month, int dayOfMonth,
                                    int hour, int minute, int second, ZoneOffset zoneOffset) ;
    // public  long epochSecond(int prolepticYear, int month, int dayOfMonth,
    //                                 int hour, int minute, int second, ZoneOffset zoneOffset) {
    //     assert(zoneOffset, "zoneOffset");
    //     HOUR_OF_DAY.checkValidValue(hour);
    //     MINUTE_OF_HOUR.checkValidValue(minute);
    //     SECOND_OF_MINUTE.checkValidValue(second);
    //     long daysInSec = Math.multiplyExact(date(prolepticYear, month, dayOfMonth).toEpochDay(), 86400);
    //     long timeinSec = (hour * 60 + minute) * 60 + second;
    //     return Math.addExact(daysInSec, timeinSec - zoneOffset.getTotalSeconds());
    // }

    /**
     * Gets the number of seconds from the epoch of 1970-01-01T00:00:00Z.
     * !(p)
     * The number of seconds is calculated using the era, year-of-era,
     * month, day-of-month, hour, minute, second, and zoneOffset.
     *
     * @param era  the era of the correct type for the chronology, not null
     * @param yearOfEra the chronology year-of-era
     * @param month the chronology month-of-year
     * @param dayOfMonth the chronology day-of-month
     * @param hour the hour-of-day, from 0 to 23
     * @param minute the minute-of-hour, from 0 to 59
     * @param second the second-of-minute, from 0 to 59
     * @param zoneOffset the zone offset, not null
     * @return the number of seconds relative to 1970-01-01T00:00:00Z, may be negative
     * @throws DateTimeException if any of the values are _out of range
     * @since 9
     */
     long epochSecond(Era era, int yearOfEra, int month, int dayOfMonth,
                                    int hour, int minute, int second, ZoneOffset zoneOffset);
    // public  long epochSecond(Era era, int yearOfEra, int month, int dayOfMonth,
    //                                 int hour, int minute, int second, ZoneOffset zoneOffset) {
    //     assert(era, "era");
    //     return epochSecond(prolepticYear(era, yearOfEra), month, dayOfMonth, hour, minute, second, zoneOffset);
    // }
    //-----------------------------------------------------------------------
    /**
     * Compares this chronology to another chronology.
     * !(p)
     * The comparison order first by the chronology ID string, then by any
     * additional information specific to the subclass.
     * It is "consistent with equals", as defined by {@link Comparable}.
     *
     * @param other  the other chronology to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     */
    // override
    int compareTo(Chronology other);

    /**
     * Checks if this chronology is equal to another chronology.
     * !(p)
     * The comparison is based on the entire state of the object.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other chronology
     */
    // override
    // bool opEquals(Object obj);

    // bool opEquals(const(Object) obj);

    /**
     * A hash code for this chronology.
     * !(p)
     * The hash code should be based on the entire state of the object.
     *
     * @return a suitable hash code
     */
    // override
    size_t toHash() @trusted nothrow ;
    // size_t toHash() @trusted nothrow;

    //-----------------------------------------------------------------------
    /**
     * Outputs this chronology as a {@code string}.
     * !(p)
     * The format should include the entire state of the object.
     *
     * @return a string representation of this chronology, not null
     */
    // override
    string toString();


}