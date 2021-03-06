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

module hunt.time.OffsetTime;

import hunt.time.LocalTime;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;

import hunt.Exceptions;
import hunt.stream.ObjectInput;
import hunt.stream.ObjectOutput;

//import hunt.io.ObjectInputStream;
import hunt.stream.Common;
// import hunt.time.format.DateTimeFormatter;
import hunt.time.format.DateTimeParseException;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAccessor;
import hunt.time.temporal.TemporalAdjuster;
import hunt.time.temporal.TemporalAmount;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.temporal.TemporalQuery;
import hunt.time.temporal.TemporalUnit;
import hunt.time.Exceptions;
import hunt.time.temporal.ValueRange;
import hunt.time.zone.ZoneRules;
import hunt.Functions;
import hunt.Long; 
import hunt.math.Helper;
import hunt.time.ZoneOffset;
import hunt.time.Instant;
import hunt.time.ZoneId;
import hunt.time.Clock;
import hunt.time.OffsetDateTime;
import hunt.time.LocalDate;
import hunt.time.Exceptions;
import hunt.time.Ser;
import hunt.time.util.Common;
import hunt.util.Common;
import hunt.util.Comparator;
// import hunt.serialization.JsonSerializer;

import std.conv;
import std.concurrency : initOnce;


/**
 * A time with an offset from UTC/Greenwich _in the ISO-8601 calendar system,
 * such as {@code 10:15:30+01:00}.
 * !(p)
 * {@code OffsetTime} is an immutable date-time object that represents a time, often
 * viewed as hour-minute-second-offset.
 * This class stores all time fields, to a precision of nanoseconds,
 * as well as a zone offset.
 * For example, the value "13:45:30.123456789+02:00" can be stored
 * _in an {@code OffsetTime}.
 *
 * !(p)
 * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
 * class; use of identity-sensitive operations (including reference equality
 * ({@code ==}), identity hash code, or synchronization) on instances of
 * {@code OffsetTime} may have unpredictable results and should be avoided.
 * The {@code equals} method should be used for comparisons.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
final class OffsetTime
        : Temporal, TemporalAdjuster, Comparable!(OffsetTime) { // , Serializable

    /**
     * The minimum supported {@code OffsetTime}, '00:00:00+18:00'.
     * This is the time of midnight at the start of the day _in the maximum offset
     * (larger offsets are earlier on the time-line).
     * This combines {@link LocalTime#MIN} and {@link ZoneOffset#MAX}.
     * This could be used by an application as a "far past" date.
     */
    static OffsetTime MIN() {
        __gshared OffsetTime _MIN;
        return initOnce!(_MIN)(LocalTime.MIN.atOffset(ZoneOffset.MAX));
    }

    /**
     * The maximum supported {@code OffsetTime}, '23:59:59.999999999-18:00'.
     * This is the time just before midnight at the end of the day _in the minimum offset
     * (larger negative offsets are later on the time-line).
     * This combines {@link LocalTime#MAX} and {@link ZoneOffset#MIN}.
     * This could be used by an application as a "far future" date.
     */
    static OffsetTime MAX() {
        __gshared OffsetTime _MAX;
        return initOnce!(_MAX)(LocalTime.MAX.atOffset(ZoneOffset.MIN));
    }

    /**
     * The local date-time.
     */
    private  LocalTime time;

    /**
     * The offset from UTC/Greenwich.
     */
    private  ZoneOffset offset;


    //-----------------------------------------------------------------------
    /**
     * Obtains the current time from the system clock _in the default time-zone.
     * !(p)
     * This will query the {@link Clock#systemDefaultZone() system clock} _in the default
     * time-zone to obtain the current time.
     * The offset will be calculated from the time-zone _in the clock.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @return the current time using the system clock and default time-zone, not null
     */
    static OffsetTime now() {
        return now(Clock.systemDefaultZone());
    }

    /**
     * Obtains the current time from the system clock _in the specified time-zone.
     * !(p)
     * This will query the {@link Clock#system(ZoneId) system clock} to obtain the current time.
     * Specifying the time-zone avoids dependence on the default time-zone.
     * The offset will be calculated from the specified time-zone.
     * !(p)
     * Using this method will prevent the ability to use an alternate clock for testing
     * because the clock is hard-coded.
     *
     * @param zone  the zone ID to use, not null
     * @return the current time using the system clock, not null
     */
    static OffsetTime now(ZoneId zone) {
        return now(Clock.system(zone));
    }

    /**
     * Obtains the current time from the specified clock.
     * !(p)
     * This will query the specified clock to obtain the current time.
     * The offset will be calculated from the time-zone _in the clock.
     * !(p)
     * Using this method allows the use of an alternate clock for testing.
     * The alternate clock may be introduced using {@link Clock dependency injection}.
     *
     * @param clock  the clock to use, not null
     * @return the current time, not null
     */
    static OffsetTime now(Clock clock) {
        assert(clock, "clock");
        Instant now = clock.instant();  // called once
        return ofInstant(now, clock.getZone().getRules().getOffset(now));
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code OffsetTime} from a local time and an offset.
     *
     * @param time  the local time, not null
     * @param offset  the zone offset, not null
     * @return the offset time, not null
     */
    static OffsetTime of(LocalTime time, ZoneOffset offset) {
        return new OffsetTime(time, offset);
    }

    /**
     * Obtains an instance of {@code OffsetTime} from an hour, minute, second and nanosecond.
     * !(p)
     * This creates an offset time with the four specified fields.
     * !(p)
     * This method exists primarily for writing test cases.
     * Non test-code will typically use other methods to create an offset time.
     * {@code LocalTime} has two additional convenience variants of the
     * equivalent factory method taking fewer arguments.
     * They are not provided here to reduce the footprint of the API.
     *
     * @param hour  the hour-of-day to represent, from 0 to 23
     * @param minute  the minute-of-hour to represent, from 0 to 59
     * @param second  the second-of-minute to represent, from 0 to 59
     * @param nanoOfSecond  the nano-of-second to represent, from 0 to 999,999,999
     * @param offset  the zone offset, not null
     * @return the offset time, not null
     * @throws DateTimeException if the value of any field is _out of range
     */
    static OffsetTime of(int hour, int minute, int second, int nanoOfSecond, ZoneOffset offset) {
        return new OffsetTime(LocalTime.of(hour, minute, second, nanoOfSecond), offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code OffsetTime} from an {@code Instant} and zone ID.
     * !(p)
     * This creates an offset time with the same instant as that specified.
     * Finding the offset from UTC/Greenwich is simple as there is only one valid
     * offset for each instant.
     * !(p)
     * The date component of the instant is dropped during the conversion.
     * This means that the conversion can never fail due to the instant being
     * _out of the valid range of dates.
     *
     * @param instant  the instant to create the time from, not null
     * @param zone  the time-zone, which may be an offset, not null
     * @return the offset time, not null
     */
    static OffsetTime ofInstant(Instant instant, ZoneId zone) {
        assert(instant, "instant");
        assert(zone, "zone");
        ZoneRules rules = zone.getRules();
        ZoneOffset offset = rules.getOffset(instant);
        long localSecond = instant.getEpochSecond() + offset.getTotalSeconds();  // overflow caught later
        int secsOfDay = MathHelper.floorMod(localSecond, LocalTime.SECONDS_PER_DAY);
        LocalTime time = LocalTime.ofNanoOfDay(secsOfDay * LocalTime.NANOS_PER_SECOND + instant.getNano());
        return new OffsetTime(time, offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code OffsetTime} from a temporal object.
     * !(p)
     * This obtains an offset time based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code OffsetTime}.
     * !(p)
     * The conversion extracts and combines the {@code ZoneOffset} and the
     * {@code LocalTime} from the temporal object.
     * Implementations are permitted to perform optimizations such as accessing
     * those fields that are equivalent to the relevant objects.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code OffsetTime::from}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the offset time, not null
     * @throws DateTimeException if unable to convert to an {@code OffsetTime}
     */
    static OffsetTime from(TemporalAccessor temporal) {
        if (cast(OffsetTime)(temporal) !is null) {
            return cast(OffsetTime) temporal;
        }
        try {
            LocalTime time = LocalTime.from(temporal);
            ZoneOffset offset = ZoneOffset.from(temporal);
            return new OffsetTime(time, offset);
        } catch (DateTimeException ex) {
            throw new DateTimeException("Unable to obtain OffsetTime from TemporalAccessor: " ~
                    typeid(temporal).name ~ " of type " ~ typeid(temporal).stringof, ex);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code OffsetTime} from a text string such as {@code 10:15:30+01:00}.
     * !(p)
     * The string must represent a valid time and is parsed using
     * {@link hunt.time.format.DateTimeFormatter#ISO_OFFSET_TIME}.
     *
     * @param text  the text to parse such as "10:15:30+01:00", not null
     * @return the parsed local time, not null
     * @throws DateTimeParseException if the text cannot be parsed
     */
    // static OffsetTime parse(string text) {
    //     return parse(text, DateTimeFormatter.ISO_OFFSET_TIME);
    // }

    /**
     * Obtains an instance of {@code OffsetTime} from a text string using a specific formatter.
     * !(p)
     * The text is parsed using the formatter, returning a time.
     *
     * @param text  the text to parse, not null
     * @param formatter  the formatter to use, not null
     * @return the parsed offset time, not null
     * @throws DateTimeParseException if the text cannot be parsed
     */
    // static OffsetTime parse(string text, DateTimeFormatter formatter) {
    //     assert(formatter, "formatter");
    //     return formatter.parse(text,  new class TemporalQuery!OffsetTime{
    //         OffsetTime queryFrom(TemporalAccessor temporal)
    //         {
    //             if (cast(OffsetTime)(temporal) !is null) {
    //                 return cast(OffsetTime) temporal;
    //             }
    //             try {
    //                 LocalTime time = LocalTime.from(temporal);
    //                 ZoneOffset offset = ZoneOffset.from(temporal);
    //                 return new OffsetTime(time, offset);
    //             } catch (DateTimeException ex) {
    //                 throw new DateTimeException("Unable to obtain OffsetTime from TemporalAccessor: " ~
    //                         typeid(temporal).name ~ " of type " ~ typeid(temporal).stringof, ex);
    //             }
    //         }
    //     });
    // }

    //-----------------------------------------------------------------------
    /**
     * Constructor.
     *
     * @param time  the local time, not null
     * @param offset  the zone offset, not null
     */
    private this(LocalTime time, ZoneOffset offset) {
        this.time = time;
        this.offset = offset;
    }

    /**
     * Returns a new time based on this one, returning {@code this} where possible.
     *
     * @param time  the time to create with, not null
     * @param offset  the zone offset to create with, not null
     */
    private OffsetTime _with(LocalTime time, ZoneOffset offset) {
        if (this.time == time && this.offset == (offset)) {
            return this;
        }
        return new OffsetTime(time, offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if the specified field is supported.
     * !(p)
     * This checks if this time can be queried for the specified field.
     * If false, then calling the {@link #range(TemporalField) range},
     * {@link #get(TemporalField) get} and {@link #_with(TemporalField, long)}
     * methods will throw an exception.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The supported fields are:
     * !(ul)
     * !(li){@code NANO_OF_SECOND}
     * !(li){@code NANO_OF_DAY}
     * !(li){@code MICRO_OF_SECOND}
     * !(li){@code MICRO_OF_DAY}
     * !(li){@code MILLI_OF_SECOND}
     * !(li){@code MILLI_OF_DAY}
     * !(li){@code SECOND_OF_MINUTE}
     * !(li){@code SECOND_OF_DAY}
     * !(li){@code MINUTE_OF_HOUR}
     * !(li){@code MINUTE_OF_DAY}
     * !(li){@code HOUR_OF_AMPM}
     * !(li){@code CLOCK_HOUR_OF_AMPM}
     * !(li){@code HOUR_OF_DAY}
     * !(li){@code CLOCK_HOUR_OF_DAY}
     * !(li){@code AMPM_OF_DAY}
     * !(li){@code OFFSET_SECONDS}
     * </ul>
     * All other {@code ChronoField} instances will return false.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.isSupportedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the field is supported is determined by the field.
     *
     * @param field  the field to check, null returns false
     * @return true if the field is supported on this time, false if not
     */
    override
    bool isSupported(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            return field.isTimeBased() || field == ChronoField.OFFSET_SECONDS;
        }
        return field !is null && field.isSupportedBy(this);
    }

    /**
     * Checks if the specified unit is supported.
     * !(p)
     * This checks if the specified unit can be added to, or subtracted from, this offset-time.
     * If false, then calling the {@link #plus(long, TemporalUnit)} and
     * {@link #minus(long, TemporalUnit) minus} methods will throw an exception.
     * !(p)
     * If the unit is a {@link ChronoUnit} then the query is implemented here.
     * The supported units are:
     * !(ul)
     * !(li){@code NANOS}
     * !(li){@code MICROS}
     * !(li){@code MILLIS}
     * !(li){@code SECONDS}
     * !(li){@code MINUTES}
     * !(li){@code HOURS}
     * !(li){@code HALF_DAYS}
     * </ul>
     * All other {@code ChronoUnit} instances will return false.
     * !(p)
     * If the unit is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.isSupportedBy(Temporal)}
     * passing {@code this} as the argument.
     * Whether the unit is supported is determined by the unit.
     *
     * @param unit  the unit to check, null returns false
     * @return true if the unit can be added/subtracted, false if not
     */
    override  // override for Javadoc
    bool isSupported(TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            return unit.isTimeBased();
        }
        return unit !is null && unit.isSupportedBy(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the range of valid values for the specified field.
     * !(p)
     * The range object expresses the minimum and maximum valid values for a field.
     * This time is used to enhance the accuracy of the returned range.
     * If it is not possible to return the range, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return
     * appropriate range instances.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.rangeRefinedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the range can be obtained is determined by the field.
     *
     * @param field  the field to query the range for, not null
     * @return the range of valid values for the field, not null
     * @throws DateTimeException if the range for the field cannot be obtained
     * @throws UnsupportedTemporalTypeException if the field is not supported
     */
    override
    ValueRange range(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            if (field == ChronoField.OFFSET_SECONDS) {
                return field.range();
            }
            return time.range(field);
        }
        return field.rangeRefinedBy(this);
    }

    /**
     * Gets the value of the specified field from this time as an {@code int}.
     * !(p)
     * This queries this time for the value of the specified field.
     * The returned value will always be within the valid range of values for the field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return valid
     * values based on this time, except {@code NANO_OF_DAY} and {@code MICRO_OF_DAY}
     * which are too large to fit _in an {@code int} and throw an {@code UnsupportedTemporalTypeException}.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.getFrom(TemporalAccessor)}
     * passing {@code this} as the argument. Whether the value can be obtained,
     * and what the value represents, is determined by the field.
     *
     * @param field  the field to get, not null
     * @return the value for the field
     * @throws DateTimeException if a value for the field cannot be obtained or
     *         the value is outside the range of valid values for the field
     * @throws UnsupportedTemporalTypeException if the field is not supported or
     *         the range of values exceeds an {@code int}
     * @throws ArithmeticException if numeric overflow occurs
     */
    override  // override for Javadoc
    int get(TemporalField field) {
        return /* Temporal. super.*/super_get(field);
    }
    int super_get(TemporalField field) {
        ValueRange range = range(field);
        if (range.isIntValue() == false) {
            throw new UnsupportedTemporalTypeException("Invalid field " ~ typeid(field).name ~ " for get() method, use getLong() instead");
        }
        long value = getLong(field);
        if (range.isValidValue(value) == false) {
            throw new DateTimeException("Invalid value for " ~ typeid(field).name ~ " (valid values " ~ range.toString ~ "): " ~ value.to!string);
        }
        return cast(int) value;
    }

    /**
     * Gets the value of the specified field from this time as a {@code long}.
     * !(p)
     * This queries this time for the value of the specified field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return valid
     * values based on this time.
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.getFrom(TemporalAccessor)}
     * passing {@code this} as the argument. Whether the value can be obtained,
     * and what the value represents, is determined by the field.
     *
     * @param field  the field to get, not null
     * @return the value for the field
     * @throws DateTimeException if a value for the field cannot be obtained
     * @throws UnsupportedTemporalTypeException if the field is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    long getLong(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            if (field == ChronoField.OFFSET_SECONDS) {
                return offset.getTotalSeconds();
            }
            return time.getLong(field);
        }
        return field.getFrom(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the zone offset, such as '+01:00'.
     * !(p)
     * This is the offset of the local time from UTC/Greenwich.
     *
     * @return the zone offset, not null
     */
    ZoneOffset getOffset() {
        return offset;
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the specified offset ensuring
     * that the result has the same local time.
     * !(p)
     * This method returns an object with the same {@code LocalTime} and the specified {@code ZoneOffset}.
     * No calculation is needed or performed.
     * For example, if this time represents {@code 10:30+02:00} and the offset specified is
     * {@code +03:00}, then this method will return {@code 10:30+03:00}.
     * !(p)
     * To take into account the difference between the offsets, and adjust the time fields,
     * use {@link #withOffsetSameInstant}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param offset  the zone offset to change to, not null
     * @return an {@code OffsetTime} based on this time with the requested offset, not null
     */
    OffsetTime withOffsetSameLocal(ZoneOffset offset) {
        return offset !is null && offset == (this.offset) ? this : new OffsetTime(time, offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the specified offset ensuring
     * that the result is at the same instant on an implied day.
     * !(p)
     * This method returns an object with the specified {@code ZoneOffset} and a {@code LocalTime}
     * adjusted by the difference between the two offsets.
     * This will result _in the old and new objects representing the same instant on an implied day.
     * This is useful for finding the local time _in a different offset.
     * For example, if this time represents {@code 10:30+02:00} and the offset specified is
     * {@code +03:00}, then this method will return {@code 11:30+03:00}.
     * !(p)
     * To change the offset without adjusting the local time use {@link #withOffsetSameLocal}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param offset  the zone offset to change to, not null
     * @return an {@code OffsetTime} based on this time with the requested offset, not null
     */
    OffsetTime withOffsetSameInstant(ZoneOffset offset) {
        if (offset == (this.offset)) {
            return this;
        }
        int difference = offset.getTotalSeconds() - this.offset.getTotalSeconds();
        LocalTime adjusted = time.plusSeconds(difference);
        return new OffsetTime(adjusted, offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the {@code LocalTime} part of this date-time.
     * !(p)
     * This returns a {@code LocalTime} with the same hour, minute, second and
     * nanosecond as this date-time.
     *
     * @return the time part of this date-time, not null
     */
    LocalTime toLocalTime() {
        return time;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the hour-of-day field.
     *
     * @return the hour-of-day, from 0 to 23
     */
    int getHour() {
        return time.getHour();
    }

    /**
     * Gets the minute-of-hour field.
     *
     * @return the minute-of-hour, from 0 to 59
     */
    int getMinute() {
        return time.getMinute();
    }

    /**
     * Gets the second-of-minute field.
     *
     * @return the second-of-minute, from 0 to 59
     */
    int getSecond() {
        return time.getSecond();
    }

    /**
     * Gets the nano-of-second field.
     *
     * @return the nano-of-second, from 0 to 999,999,999
     */
    int getNano() {
        return time.getNano();
    }

    //-----------------------------------------------------------------------
    /**
     * Returns an adjusted copy of this time.
     * !(p)
     * This returns an {@code OffsetTime}, based on this one, with the time adjusted.
     * The adjustment takes place using the specified adjuster strategy object.
     * Read the documentation of the adjuster to understand what adjustment will be made.
     * !(p)
     * A simple adjuster might simply set the one of the fields, such as the hour field.
     * A more complex adjuster might set the time to the last hour of the day.
     * !(p)
     * The classes {@link LocalTime} and {@link ZoneOffset} implement {@code TemporalAdjuster},
     * thus this method can be used to change the time or offset:
     * !(pre)
     *  result = offsetTime._with(time);
     *  result = offsetTime._with(offset);
     * </pre>
     * !(p)
     * The result of this method is obtained by invoking the
     * {@link TemporalAdjuster#adjustInto(Temporal)} method on the
     * specified adjuster passing {@code this} as the argument.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param adjuster the adjuster to use, not null
     * @return an {@code OffsetTime} based on {@code this} with the adjustment made, not null
     * @throws DateTimeException if the adjustment cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    OffsetTime _with(TemporalAdjuster adjuster) {
        // optimizations
        if (cast(LocalTime)(adjuster) !is null) {
            return _with(cast(LocalTime) adjuster, offset);
        } else if (cast(ZoneOffset)(adjuster) !is null) {
            return _with(time, cast(ZoneOffset) adjuster);
        } else if (cast(OffsetTime)(adjuster) !is null) {
            return cast(OffsetTime) adjuster;
        }
        return cast(OffsetTime) adjuster.adjustInto(this);
    }

    /**
     * Returns a copy of this time with the specified field set to a new value.
     * !(p)
     * This returns an {@code OffsetTime}, based on this one, with the value
     * for the specified field changed.
     * This can be used to change any supported field, such as the hour, minute or second.
     * If it is not possible to set the value, because the field is not supported or for
     * some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the adjustment is implemented here.
     * !(p)
     * The {@code OFFSET_SECONDS} field will return a time with the specified offset.
     * The local time is unaltered. If the new offset value is outside the valid range
     * then a {@code DateTimeException} will be thrown.
     * !(p)
     * The other {@link #isSupported(TemporalField) supported fields} will behave as per
     * the matching method on {@link LocalTime#_with(TemporalField, long)} LocalTime}.
     * In this case, the offset is not part of the calculation and will be unchanged.
     * !(p)
     * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.adjustInto(Temporal, long)}
     * passing {@code this} as the argument. In this case, the field determines
     * whether and how to adjust the instant.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param field  the field to set _in the result, not null
     * @param newValue  the new value of the field _in the result
     * @return an {@code OffsetTime} based on {@code this} with the specified field set, not null
     * @throws DateTimeException if the field cannot be set
     * @throws UnsupportedTemporalTypeException if the field is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    OffsetTime _with(TemporalField field, long newValue) {
        if (cast(ChronoField)(field) !is null) {
            if (field == ChronoField.OFFSET_SECONDS) {
                ChronoField f = cast(ChronoField) field;
                return _with(time, ZoneOffset.ofTotalSeconds(f.checkValidIntValue(newValue)));
            }
            return _with(time._with(field, newValue), offset);
        }
        return cast(OffsetTime)(field.adjustInto(this, newValue));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code OffsetTime} with the hour-of-day altered.
     * !(p)
     * The offset does not affect the calculation and will be the same _in the result.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param hour  the hour-of-day to set _in the result, from 0 to 23
     * @return an {@code OffsetTime} based on this time with the requested hour, not null
     * @throws DateTimeException if the hour value is invalid
     */
    OffsetTime withHour(int hour) {
        return _with(time.withHour(hour), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the minute-of-hour altered.
     * !(p)
     * The offset does not affect the calculation and will be the same _in the result.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param minute  the minute-of-hour to set _in the result, from 0 to 59
     * @return an {@code OffsetTime} based on this time with the requested minute, not null
     * @throws DateTimeException if the minute value is invalid
     */
    OffsetTime withMinute(int minute) {
        return _with(time.withMinute(minute), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the second-of-minute altered.
     * !(p)
     * The offset does not affect the calculation and will be the same _in the result.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param second  the second-of-minute to set _in the result, from 0 to 59
     * @return an {@code OffsetTime} based on this time with the requested second, not null
     * @throws DateTimeException if the second value is invalid
     */
    OffsetTime withSecond(int second) {
        return _with(time.withSecond(second), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the nano-of-second altered.
     * !(p)
     * The offset does not affect the calculation and will be the same _in the result.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanoOfSecond  the nano-of-second to set _in the result, from 0 to 999,999,999
     * @return an {@code OffsetTime} based on this time with the requested nanosecond, not null
     * @throws DateTimeException if the nanos value is invalid
     */
    OffsetTime withNano(int nanoOfSecond) {
        return _with(time.withNano(nanoOfSecond), offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code OffsetTime} with the time truncated.
     * !(p)
     * Truncation returns a copy of the original time with fields
     * smaller than the specified unit set to zero.
     * For example, truncating with the {@link ChronoUnit#MINUTES minutes} unit
     * will set the second-of-minute and nano-of-second field to zero.
     * !(p)
     * The unit must have a {@linkplain TemporalUnit#getDuration() duration}
     * that divides into the length of a standard day without remainder.
     * This includes all supplied time units on {@link ChronoUnit} and
     * {@link ChronoUnit#DAYS DAYS}. Other units throw an exception.
     * !(p)
     * The offset does not affect the calculation and will be the same _in the result.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param unit  the unit to truncate to, not null
     * @return an {@code OffsetTime} based on this time with the time truncated, not null
     * @throws DateTimeException if unable to truncate
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     */
    OffsetTime truncatedTo(TemporalUnit unit) {
        return _with(time.truncatedTo(unit), offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this time with the specified amount added.
     * !(p)
     * This returns an {@code OffsetTime}, based on this one, with the specified amount added.
     * The amount is typically {@link Duration} but may be any other type implementing
     * the {@link TemporalAmount} interface.
     * !(p)
     * The calculation is delegated to the amount object by calling
     * {@link TemporalAmount#addTo(Temporal)}. The amount implementation is free
     * to implement the addition _in any way it wishes, however it typically
     * calls back to {@link #plus(long, TemporalUnit)}. Consult the documentation
     * of the amount implementation to determine if it can be successfully added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToAdd  the amount to add, not null
     * @return an {@code OffsetTime} based on this time with the addition made, not null
     * @throws DateTimeException if the addition cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    OffsetTime plus(TemporalAmount amountToAdd) {
        return cast(OffsetTime) amountToAdd.addTo(this);
    }

    /**
     * Returns a copy of this time with the specified amount added.
     * !(p)
     * This returns an {@code OffsetTime}, based on this one, with the amount
     * _in terms of the unit added. If it is not possible to add the amount, because the
     * unit is not supported or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoUnit} then the addition is implemented by
     * {@link LocalTime#plus(long, TemporalUnit)}.
     * The offset is not part of the calculation and will be unchanged _in the result.
     * !(p)
     * If the field is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.addTo(Temporal, long)}
     * passing {@code this} as the argument. In this case, the unit determines
     * whether and how to perform the addition.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToAdd  the amount of the unit to add to the result, may be negative
     * @param unit  the unit of the amount to add, not null
     * @return an {@code OffsetTime} based on this time with the specified amount added, not null
     * @throws DateTimeException if the addition cannot be made
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    OffsetTime plus(long amountToAdd, TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            return _with(time.plus(amountToAdd, unit), offset);
        }
        return cast(OffsetTime)(unit.addTo(this, amountToAdd));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code OffsetTime} with the specified number of hours added.
     * !(p)
     * This adds the specified number of hours to this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param hours  the hours to add, may be negative
     * @return an {@code OffsetTime} based on this time with the hours added, not null
     */
    OffsetTime plusHours(long hours) {
        return _with(time.plusHours(hours), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the specified number of minutes added.
     * !(p)
     * This adds the specified number of minutes to this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param minutes  the minutes to add, may be negative
     * @return an {@code OffsetTime} based on this time with the minutes added, not null
     */
    OffsetTime plusMinutes(long minutes) {
        return _with(time.plusMinutes(minutes), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the specified number of seconds added.
     * !(p)
     * This adds the specified number of seconds to this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param seconds  the seconds to add, may be negative
     * @return an {@code OffsetTime} based on this time with the seconds added, not null
     */
    OffsetTime plusSeconds(long seconds) {
        return _with(time.plusSeconds(seconds), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the specified number of nanoseconds added.
     * !(p)
     * This adds the specified number of nanoseconds to this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanos  the nanos to add, may be negative
     * @return an {@code OffsetTime} based on this time with the nanoseconds added, not null
     */
    OffsetTime plusNanos(long nanos) {
        return _with(time.plusNanos(nanos), offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this time with the specified amount subtracted.
     * !(p)
     * This returns an {@code OffsetTime}, based on this one, with the specified amount subtracted.
     * The amount is typically {@link Duration} but may be any other type implementing
     * the {@link TemporalAmount} interface.
     * !(p)
     * The calculation is delegated to the amount object by calling
     * {@link TemporalAmount#subtractFrom(Temporal)}. The amount implementation is free
     * to implement the subtraction _in any way it wishes, however it typically
     * calls back to {@link #minus(long, TemporalUnit)}. Consult the documentation
     * of the amount implementation to determine if it can be successfully subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToSubtract  the amount to subtract, not null
     * @return an {@code OffsetTime} based on this time with the subtraction made, not null
     * @throws DateTimeException if the subtraction cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    OffsetTime minus(TemporalAmount amountToSubtract) {
        return cast(OffsetTime) amountToSubtract.subtractFrom(this);
    }

    /**
     * Returns a copy of this time with the specified amount subtracted.
     * !(p)
     * This returns an {@code OffsetTime}, based on this one, with the amount
     * _in terms of the unit subtracted. If it is not possible to subtract the amount,
     * because the unit is not supported or for some other reason, an exception is thrown.
     * !(p)
     * This method is equivalent to {@link #plus(long, TemporalUnit)} with the amount negated.
     * See that method for a full description of how addition, and thus subtraction, works.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToSubtract  the amount of the unit to subtract from the result, may be negative
     * @param unit  the unit of the amount to subtract, not null
     * @return an {@code OffsetTime} based on this time with the specified amount subtracted, not null
     * @throws DateTimeException if the subtraction cannot be made
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    OffsetTime minus(long amountToSubtract, TemporalUnit unit) {
        return (amountToSubtract == Long.MIN_VALUE ? plus(Long.MAX_VALUE, unit).plus(1, unit) : plus(-amountToSubtract, unit));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code OffsetTime} with the specified number of hours subtracted.
     * !(p)
     * This subtracts the specified number of hours from this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param hours  the hours to subtract, may be negative
     * @return an {@code OffsetTime} based on this time with the hours subtracted, not null
     */
    OffsetTime minusHours(long hours) {
        return _with(time.minusHours(hours), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the specified number of minutes subtracted.
     * !(p)
     * This subtracts the specified number of minutes from this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param minutes  the minutes to subtract, may be negative
     * @return an {@code OffsetTime} based on this time with the minutes subtracted, not null
     */
    OffsetTime minusMinutes(long minutes) {
        return _with(time.minusMinutes(minutes), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the specified number of seconds subtracted.
     * !(p)
     * This subtracts the specified number of seconds from this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param seconds  the seconds to subtract, may be negative
     * @return an {@code OffsetTime} based on this time with the seconds subtracted, not null
     */
    OffsetTime minusSeconds(long seconds) {
        return _with(time.minusSeconds(seconds), offset);
    }

    /**
     * Returns a copy of this {@code OffsetTime} with the specified number of nanoseconds subtracted.
     * !(p)
     * This subtracts the specified number of nanoseconds from this time, returning a new time.
     * The calculation wraps around midnight.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanos  the nanos to subtract, may be negative
     * @return an {@code OffsetTime} based on this time with the nanoseconds subtracted, not null
     */
    OffsetTime minusNanos(long nanos) {
        return _with(time.minusNanos(nanos), offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Queries this time using the specified query.
     * !(p)
     * This queries this time using the specified query strategy object.
     * The {@code TemporalQuery} object defines the logic to be used to
     * obtain the result. Read the documentation of the query to understand
     * what the result of this method will be.
     * !(p)
     * The result of this method is obtained by invoking the
     * {@link TemporalQuery#queryFrom(TemporalAccessor)} method on the
     * specified query passing {@code this} as the argument.
     *
     * @param !(R) the type of the result
     * @param query  the query to invoke, not null
     * @return the query result, null may be returned (defined by the query)
     * @throws DateTimeException if unable to query (defined by the query)
     * @throws ArithmeticException if numeric overflow occurs (defined by the query)
     */
    /*@SuppressWarnings("unchecked")*/
    // override
    R query(R)(TemporalQuery!(R) query) {
        if (query == TemporalQueries.offset() || query == TemporalQueries.zone()) {
            return cast(R) offset;
        } else if (((query == TemporalQueries.zoneId()) | (query == TemporalQueries.chronology())) || query == TemporalQueries.localDate()) {
            return null;
        } else if (query == TemporalQueries.localTime()) {
            return cast(R) time;
        } else if (query == TemporalQueries.precision()) {
            return cast(R) (ChronoUnit.NANOS);
        }
        // inline TemporalAccessor.super.query(query) as an optimization
        // non-JDK classes are not permitted to make this optimization
        return query.queryFrom(this);
    }

    /**
     * Adjusts the specified temporal object to have the same offset and time
     * as this object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with the offset and time changed to be the same as this.
     * !(p)
     * The adjustment is equivalent to using {@link Temporal#_with(TemporalField, long)}
     * twice, passing {@link ChronoField#NANO_OF_DAY} and
     * {@link ChronoField#OFFSET_SECONDS} as the fields.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisOffsetTime.adjustInto(temporal);
     *   temporal = temporal._with(thisOffsetTime);
     * </pre>
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the target object to be adjusted, not null
     * @return the adjusted object, not null
     * @throws DateTimeException if unable to make the adjustment
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    Temporal adjustInto(Temporal temporal) {
        return temporal
                ._with(ChronoField.NANO_OF_DAY, time.toNanoOfDay())
                ._with(ChronoField.OFFSET_SECONDS, offset.getTotalSeconds());
    }

    /**
     * Calculates the amount of time until another time _in terms of the specified unit.
     * !(p)
     * This calculates the amount of time between two {@code OffsetTime}
     * objects _in terms of a single {@code TemporalUnit}.
     * The start and end points are {@code this} and the specified time.
     * The result will be negative if the end is before the start.
     * For example, the amount _in hours between two times can be calculated
     * using {@code startTime.until(endTime, HOURS)}.
     * !(p)
     * The {@code Temporal} passed to this method is converted to a
     * {@code OffsetTime} using {@link #from(TemporalAccessor)}.
     * If the offset differs between the two times, then the specified
     * end time is normalized to have the same offset as this time.
     * !(p)
     * The calculation returns a whole number, representing the number of
     * complete units between the two times.
     * For example, the amount _in hours between 11:30Z and 13:29Z will only
     * be one hour as it is one minute short of two hours.
     * !(p)
     * There are two equivalent ways of using this method.
     * The first is to invoke this method.
     * The second is to use {@link TemporalUnit#between(Temporal, Temporal)}:
     * !(pre)
     *   // these two lines are equivalent
     *   amount = start.until(end, MINUTES);
     *   amount = MINUTES.between(start, end);
     * </pre>
     * The choice should be made based on which makes the code more readable.
     * !(p)
     * The calculation is implemented _in this method for {@link ChronoUnit}.
     * The units {@code NANOS}, {@code MICROS}, {@code MILLIS}, {@code SECONDS},
     * {@code MINUTES}, {@code HOURS} and {@code HALF_DAYS} are supported.
     * Other {@code ChronoUnit} values will throw an exception.
     * !(p)
     * If the unit is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.between(Temporal, Temporal)}
     * passing {@code this} as the first argument and the converted input temporal
     * as the second argument.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param endExclusive  the end time, exclusive, which is converted to an {@code OffsetTime}, not null
     * @param unit  the unit to measure the amount _in, not null
     * @return the amount of time between this time and the end time
     * @throws DateTimeException if the amount cannot be calculated, or the end
     *  temporal cannot be converted to an {@code OffsetTime}
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    long until(Temporal endExclusive, TemporalUnit unit) {
        OffsetTime end = OffsetTime.from(endExclusive);
        if (cast(ChronoUnit)(unit) !is null) {
            long nanosUntil = end.toEpochNano() - toEpochNano();  // no overflow
            auto f = cast(ChronoUnit) unit;
            {
                if( f ==  ChronoUnit.NANOS) return nanosUntil;
                if( f ==  ChronoUnit.MICROS) return nanosUntil / 1000;
                if( f ==  ChronoUnit.MILLIS) return nanosUntil / 1000_000;
                if( f ==  ChronoUnit.SECONDS) return nanosUntil / LocalTime.NANOS_PER_SECOND;
                if( f ==  ChronoUnit.MINUTES) return nanosUntil / LocalTime.NANOS_PER_MINUTE;
                if( f ==  ChronoUnit.HOURS) return nanosUntil / LocalTime.NANOS_PER_HOUR;
                if( f ==  ChronoUnit.HALF_DAYS) return nanosUntil / (12 * LocalTime.NANOS_PER_HOUR);
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit : " ~ f.toString);
        }
        return unit.between(this, end);
    }

    /**
     * Formats this time using the specified formatter.
     * !(p)
     * This time will be passed to the formatter to produce a string.
     *
     * @param formatter  the formatter to use, not null
     * @return the formatted time string, not null
     * @throws DateTimeException if an error occurs during printing
     */
    // string format(DateTimeFormatter formatter) {
    //     assert(formatter, "formatter");
    //     return formatter.format(this);
    // }

    //-----------------------------------------------------------------------
    /**
     * Combines this time with a date to create an {@code OffsetDateTime}.
     * !(p)
     * This returns an {@code OffsetDateTime} formed from this time and the specified date.
     * All possible combinations of date and time are valid.
     *
     * @param date  the date to combine with, not null
     * @return the offset date-time formed from this time and the specified date, not null
     */
    OffsetDateTime atDate(LocalDate date) {
        return OffsetDateTime.of(date, time, offset);
    }

    //-----------------------------------------------------------------------
    /**
     * Converts this time to epoch nanos based on 1970-01-01Z.
     *
     * @return the epoch nanos value
     */
    private long toEpochNano() {
        long nod = time.toNanoOfDay();
        long offsetNanos = offset.getTotalSeconds() * LocalTime.NANOS_PER_SECOND;
        return nod - offsetNanos;
    }

    /**
     * Converts this {@code OffsetTime} to the number of seconds since the epoch
     * of 1970-01-01T00:00:00Z.
     * !(p)
     * This combines this offset time with the specified date to calculate the
     * epoch-second value, which is the number of elapsed seconds from
     * 1970-01-01T00:00:00Z.
     * Instants on the time-line after the epoch are positive, earlier
     * are negative.
     *
     * @param date the localdate, not null
     * @return the number of seconds since the epoch of 1970-01-01T00:00:00Z, may be negative
     * @since 9
     */
    long toEpochSecond(LocalDate date) {
        assert(date, "date");
        long epochDay = date.toEpochDay();
        long secs = epochDay * 86400 + time.toSecondOfDay();
        secs -= offset.getTotalSeconds();
        return secs;
    }

    //-----------------------------------------------------------------------
    /**
     * Compares this {@code OffsetTime} to another time.
     * !(p)
     * The comparison is based first on the UTC equivalent instant, then on the local time.
     * It is "consistent with equals", as defined by {@link Comparable}.
     * !(p)
     * For example, the following is the comparator order:
     * !(ol)
     * !(li){@code 10:30+01:00}</li>
     * !(li){@code 11:00+01:00}</li>
     * !(li){@code 12:00+02:00}</li>
     * !(li){@code 11:30+01:00}</li>
     * !(li){@code 12:00+01:00}</li>
     * !(li){@code 12:30+01:00}</li>
     * </ol>
     * Values #2 and #3 represent the same instant on the time-line.
     * When two values represent the same instant, the local time is compared
     * to distinguish them. This step is needed to make the ordering
     * consistent with {@code equals()}.
     * !(p)
     * To compare the underlying local time of two {@code TemporalAccessor} instances,
     * use {@link ChronoField#NANO_OF_DAY} as a comparator.
     *
     * @param other  the other time to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     */
    // override
    int compareTo(OffsetTime other) {
        if (offset == (other.offset)) {
            return time.compareTo(other.time);
        }
        int compare = compare(toEpochNano(), other.toEpochNano());
        if (compare == 0) {
            compare = time.compareTo(other.time);
        }
        return compare;
    }

    override int opCmp(OffsetTime other) {
        if (offset == (other.offset)) {
            return time.compareTo(other.time);
        }
        int compare = compare(toEpochNano(), other.toEpochNano());
        if (compare == 0) {
            compare = time.compareTo(other.time);
        }
        return compare;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if the instant of this {@code OffsetTime} is after that of the
     * specified time applying both times to a common date.
     * !(p)
     * This method differs from the comparison _in {@link #compareTo} _in that it
     * only compares the instant of the time. This is equivalent to converting both
     * times to an instant using the same date and comparing the instants.
     *
     * @param other  the other time to compare to, not null
     * @return true if this is after the instant of the specified time
     */
    bool isAfter(OffsetTime other) {
        return toEpochNano() > other.toEpochNano();
    }

    /**
     * Checks if the instant of this {@code OffsetTime} is before that of the
     * specified time applying both times to a common date.
     * !(p)
     * This method differs from the comparison _in {@link #compareTo} _in that it
     * only compares the instant of the time. This is equivalent to converting both
     * times to an instant using the same date and comparing the instants.
     *
     * @param other  the other time to compare to, not null
     * @return true if this is before the instant of the specified time
     */
    bool isBefore(OffsetTime other) {
        return toEpochNano() < other.toEpochNano();
    }

    /**
     * Checks if the instant of this {@code OffsetTime} is equal to that of the
     * specified time applying both times to a common date.
     * !(p)
     * This method differs from the comparison _in {@link #compareTo} and {@link #equals}
     * _in that it only compares the instant of the time. This is equivalent to converting both
     * times to an instant using the same date and comparing the instants.
     *
     * @param other  the other time to compare to, not null
     * @return true if this is equal to the instant of the specified time
     */
    bool isEqual(OffsetTime other) {
        return toEpochNano() == other.toEpochNano();
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this time is equal to another time.
     * !(p)
     * The comparison is based on the local-time and the offset.
     * To compare for the same instant on the time-line, use {@link #isEqual(OffsetTime)}.
     * !(p)
     * Only objects of type {@code OffsetTime} are compared, other types return false.
     * To compare the underlying local time of two {@code TemporalAccessor} instances,
     * use {@link ChronoField#NANO_OF_DAY} as a comparator.
     *
     * @param obj  the object to check, null returns false
     * @return true if this is equal to the other time
     */
    override
    bool opEquals(Object obj) {
        if (this is obj) {
            return true;
        }
        if (cast(OffsetTime)(obj) !is null) {
            OffsetTime other = cast(OffsetTime) obj;
            return time == (other.time) && offset == (other.offset);
        }
        return false;
    }

    /**
     * A hash code for this time.
     *
     * @return a suitable hash code
     */
    override
    size_t toHash() @trusted nothrow {
        return time.toHash() ^ offset.toHash();
    }

    //-----------------------------------------------------------------------
    /**
     * Outputs this time as a {@code string}, such as {@code 10:15:30+01:00}.
     * !(p)
     * The output will be one of the following ISO-8601 formats:
     * !(ul)
     * !(li){@code HH:mmXXXXX}</li>
     * !(li){@code HH:mm:ssXXXXX}</li>
     * !(li){@code HH:mm:ss.SSSXXXXX}</li>
     * !(li){@code HH:mm:ss.SSSSSSXXXXX}</li>
     * !(li){@code HH:mm:ss.SSSSSSSSSXXXXX}</li>
     * </ul>
     * The format used will be the shortest that outputs the full value of
     * the time where the omitted parts are implied to be zero.
     *
     * @return a string representation of this time, not null
     */
    override
    string toString() {
        return time.toString() ~ offset.toString();
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(9);  // identifies an OffsetTime
     *  // the <a href="{@docRoot}/serialized-form.html#hunt.time.LocalTime">time</a> excluding the one byte header
     *  // the <a href="{@docRoot}/serialized-form.html#hunt.time.ZoneOffset">offset</a> excluding the one byte header
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.OFFSET_TIME_TYPE, this);
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

    // void writeExternal(ObjectOutput _out) /*throws IOException*/ {
    //     time.writeExternal(_out);
    //     offset.writeExternal(_out);
    // }

    // static OffsetTime readExternal(ObjectInput _in) /*throws IOException, ClassNotFoundException*/ {
    //     LocalTime time = LocalTime.readExternal(_in);
    //     ZoneOffset offset = ZoneOffset.readExternal(_in);
    //     return OffsetTime.of(time, offset);
    // }


    // mixin SerializationMember!(typeof(this));
}
