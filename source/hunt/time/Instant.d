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

module hunt.time.Instant;

import hunt.time.LocalTime;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;
import hunt.util.Comparator;
import hunt.stream.DataInput;
import hunt.stream.DataOutput;
import hunt.Exceptions;
import hunt.Long;
import hunt.math.Helper;
import hunt.util.Common;
import hunt.time.Exceptions;
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
import hunt.time.OffsetDateTime;
// import hunt.time.Duration;
import hunt.time.Ser;
import hunt.time.Year;
import hunt.time.Exceptions;
import std.math;
/**
 * An instantaneous point on the time-line.
 * !(p)
 * This class models a single instantaneous point on the time-line.
 * This might be used to record event time-stamps _in the application.
 * !(p)
 * The range of an instant requires the storage of a number larger than a {@code long}.
 * To achieve this, the class stores a {@code long} representing epoch-seconds and an
 * {@code int} representing nanosecond-of-second, which will always be between 0 and 999,999,999.
 * The epoch-seconds are measured from the standard Java epoch of {@code 1970-01-01T00:00:00Z}
 * where instants after the epoch have positive values, and earlier instants have negative values.
 * For both the epoch-second and nanosecond parts, a larger value is always later on the time-line
 * than a smaller value.
 *
 * !(h3)Time-scale</h3>
 * !(p)
 * The length of the solar day is the standard way that humans measure time.
 * This has traditionally been subdivided into 24 hours of 60 minutes of 60 seconds,
 * forming a 86400 second day.
 * !(p)
 * Modern timekeeping is based on atomic clocks which precisely define an SI second
 * relative to the transitions of a Caesium atom. The length of an SI second was defined
 * to be very close to the 86400th fraction of a day.
 * !(p)
 * Unfortunately, as the Earth rotates the length of the day varies.
 * In addition, over time the average length of the day is getting longer as the Earth slows.
 * As a result, the length of a solar day _in 2012 is slightly longer than 86400 SI seconds.
 * The actual length of any given day and the amount by which the Earth is slowing
 * are not predictable and can only be determined by measurement.
 * The UT1 time-scale captures the accurate length of day, but is only available some
 * time after the day has completed.
 * !(p)
 * The UTC time-scale is a standard approach to bundle up all the additional fractions
 * of a second from UT1 into whole seconds, known as !(i)leap-seconds</i>.
 * A leap-second may be added or removed depending on the Earth's rotational changes.
 * As such, UTC permits a day to have 86399 SI seconds or 86401 SI seconds where
 * necessary _in order to keep the day aligned with the Sun.
 * !(p)
 * The modern UTC time-scale was introduced _in 1972, introducing the concept of whole leap-seconds.
 * Between 1958 and 1972, the definition of UTC was complex, with minor sub-second leaps and
 * alterations to the length of the notional second. As of 2012, discussions are underway
 * to change the definition of UTC again, with the potential to remove leap seconds or
 * introduce other changes.
 * !(p)
 * Given the complexity of accurate timekeeping described above, this Java API defines
 * its own time-scale, the !(i)Java Time-Scale</i>.
 * !(p)
 * The Java Time-Scale divides each calendar day into exactly 86400
 * subdivisions, known as seconds.  These seconds may differ from the
 * SI second.  It closely matches the de facto international civil time
 * scale, the definition of which changes from time to time.
 * !(p)
 * The Java Time-Scale has slightly different definitions for different
 * segments of the time-line, each based on the consensus international
 * time scale that is used as the basis for civil time. Whenever the
 * internationally-agreed time scale is modified or replaced, a new
 * segment of the Java Time-Scale must be defined for it.  Each segment
 * must meet these requirements:
 * !(ul)
 * !(li)the Java Time-Scale shall closely match the underlying international
 *  civil time scale;</li>
 * !(li)the Java Time-Scale shall exactly match the international civil
 *  time scale at noon each day;</li>
 * !(li)the Java Time-Scale shall have a precisely-defined relationship to
 *  the international civil time scale.</li>
 * </ul>
 * There are currently, as of 2013, two segments _in the Java time-scale.
 * !(p)
 * For the segment from 1972-11-03 (exact boundary discussed below) until
 * further notice, the consensus international time scale is UTC (with
 * leap seconds).  In this segment, the Java Time-Scale is identical to
 * <a href="http://www.cl.cam.ac.uk/~mgk25/time/utc-sls/">UTC-SLS</a>.
 * This is identical to UTC on days that do not have a leap second.
 * On days that do have a leap second, the leap second is spread equally
 * over the last 1000 seconds of the day, maintaining the appearance of
 * exactly 86400 seconds per day.
 * !(p)
 * For the segment prior to 1972-11-03, extending back arbitrarily far,
 * the consensus international time scale is defined to be UT1, applied
 * proleptically, which is equivalent to the (mean) solar time on the
 * prime meridian (Greenwich). In this segment, the Java Time-Scale is
 * identical to the consensus international time scale. The exact
 * boundary between the two segments is the instant where UT1 = UTC
 * between 1972-11-03T00:00 and 1972-11-04T12:00.
 * !(p)
 * Implementations of the Java time-scale using the JSR-310 API are not
 * required to provide any clock that is sub-second accurate, or that
 * progresses monotonically or smoothly. Implementations are therefore
 * not required to actually perform the UTC-SLS slew or to otherwise be
 * aware of leap seconds. JSR-310 does, however, require that
 * implementations must document the approach they use when defining a
 * clock representing the current instant.
 * See {@link Clock} for details on the available clocks.
 * !(p)
 * The Java time-scale is used for all date-time classes.
 * This includes {@code Instant}, {@code LocalDate}, {@code LocalTime}, {@code OffsetDateTime},
 * {@code ZonedDateTime} and {@code Duration}.
 *
 * !(p)
 * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
 * class; use of identity-sensitive operations (including reference equality
 * ({@code ==}), identity hash code, or synchronization) on instances of
 * {@code Instant} may have unpredictable results and should be avoided.
 * The {@code equals} method should be used for comparisons.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */

import hunt.Functions;
import hunt.time.Clock;
import hunt.time.ZoneOffset;
import hunt.time.ZonedDateTime;
import hunt.time.ZoneId;
import hunt.time.util.Common;

import std.concurrency : initOnce;

final class Instant
        : Temporal, TemporalAdjuster, Comparable!(Instant) { // , Serializable

    /**
     * The minimum supported epoch second.
     */
     enum long MIN_SECOND = -31557014167219200L;

    /**
     * The maximum supported epoch second.
     */
     enum long MAX_SECOND = 31556889864403199L;

    /**
     * Constant for the 1970-01-01T00:00:00Z epoch instant.
     */
    static Instant EPOCH() {
        __gshared Instant _EPOCH;
        return initOnce!(_EPOCH)(new Instant(0, 0));
    }

    /**
     * The minimum supported {@code Instant}, '-1000000000-01-01T00:00Z'.
     * This could be used by an application as a "far past" instant.
     * !(p)
     * This is one year earlier than the minimum {@code LocalDateTime}.
     * This provides sufficient values to handle the range of {@code ZoneOffset}
     * which affect the instant _in addition to the local date-time.
     * The value is also chosen such that the value of the year fits _in
     * an {@code int}.
     */
    static Instant MIN() {
        __gshared Instant _MIN;
        return initOnce!(_MIN)(Instant.ofEpochSecond(MIN_SECOND, 0));
    }    
    
    /**
     * The maximum supported {@code Instant}, '1000000000-12-31T23:59:59.999999999Z'.
     * This could be used by an application as a "far future" instant.
     * !(p)
     * This is one year later than the maximum {@code LocalDateTime}.
     * This provides sufficient values to handle the range of {@code ZoneOffset}
     * which affect the instant _in addition to the local date-time.
     * The value is also chosen such that the value of the year fits _in
     * an {@code int}.
     */
    static Instant MAX() {
        __gshared Instant _MAX;
        return initOnce!(_MAX)(Instant.ofEpochSecond(MAX_SECOND, 999_999_999));
    }    

    /**
     * The number of seconds from the epoch of 1970-01-01T00:00:00Z.
     */
    private  long seconds;
    /**
     * The number of nanoseconds, later along the time-line, from the seconds field.
     * This is always positive, and never exceeds 999,999,999.
     */
    private  int nanos;


    //-----------------------------------------------------------------------
    /**
     * Obtains the current instant from the system clock.
     * !(p)
     * This will query the {@link Clock#systemUTC() system UTC clock} to
     * obtain the current instant.
     * !(p)
     * Using this method will prevent the ability to use an alternate time-source for
     * testing because the clock is effectively hard-coded.
     *
     * @return the current instant using the system clock, not null
     */
    static Instant now() {
        return Clock.systemUTC().instant();
    }

    /**
     * Obtains the current instant from the specified clock.
     * !(p)
     * This will query the specified clock to obtain the current time.
     * !(p)
     * Using this method allows the use of an alternate clock for testing.
     * The alternate clock may be introduced using {@link Clock dependency injection}.
     *
     * @param clock  the clock to use, not null
     * @return the current instant, not null
     */
    static Instant now(Clock clock) {
        assert(clock, "clock");
        return clock.instant();
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Instant} using seconds from the
     * epoch of 1970-01-01T00:00:00Z.
     * !(p)
     * The nanosecond field is set to zero.
     *
     * @param epochSecond  the number of seconds from 1970-01-01T00:00:00Z
     * @return an instant, not null
     * @throws DateTimeException if the instant exceeds the maximum or minimum instant
     */
    static Instant ofEpochSecond(long epochSecond) {
        return create(epochSecond, 0);
    }

    /**
     * Obtains an instance of {@code Instant} using seconds from the
     * epoch of 1970-01-01T00:00:00Z and nanosecond fraction of second.
     * !(p)
     * This method allows an arbitrary number of nanoseconds to be passed _in.
     * The factory will alter the values of the second and nanosecond _in order
     * to ensure that the stored nanosecond is _in the range 0 to 999,999,999.
     * For example, the following will result _in exactly the same instant:
     * !(pre)
     *  Instant.ofEpochSecond(3, 1);
     *  Instant.ofEpochSecond(4, -999_999_999);
     *  Instant.ofEpochSecond(2, 1000_000_001);
     * </pre>
     *
     * @param epochSecond  the number of seconds from 1970-01-01T00:00:00Z
     * @param nanoAdjustment  the nanosecond adjustment to the number of seconds, positive or negative
     * @return an instant, not null
     * @throws DateTimeException if the instant exceeds the maximum or minimum instant
     * @throws ArithmeticException if numeric overflow occurs
     */
    static Instant ofEpochSecond(long epochSecond, long nanoAdjustment) {
        long secs = MathHelper.addExact(epochSecond , MathHelper.floorDiv(nanoAdjustment , LocalTime.NANOS_PER_SECOND));
        int nos = cast(int)(MathHelper.floorMod(nanoAdjustment , LocalTime.NANOS_PER_SECOND));
        return create(secs, nos);
    }

    /**
     * Obtains an instance of {@code Instant} using milliseconds from the
     * epoch of 1970-01-01T00:00:00Z.
     * !(p)
     * The seconds and nanoseconds are extracted from the specified milliseconds.
     *
     * @param epochMilli  the number of milliseconds from 1970-01-01T00:00:00Z
     * @return an instant, not null
     * @throws DateTimeException if the instant exceeds the maximum or minimum instant
     */
    static Instant ofEpochMilli(long epochMilli) {
        long secs = MathHelper.floorDiv(epochMilli , 1000);
        int mos = MathHelper.floorMod(epochMilli , 1000);
        return create(secs, mos * 1000_000);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Instant} from a temporal object.
     * !(p)
     * This obtains an instant based on the specified temporal.
     * A {@code TemporalAccessor} represents an arbitrary set of date and time information,
     * which this factory converts to an instance of {@code Instant}.
     * !(p)
     * The conversion extracts the {@link ChronoField#INSTANT_SECONDS INSTANT_SECONDS}
     * and {@link ChronoField#NANO_OF_SECOND NANO_OF_SECOND} fields.
     * !(p)
     * This method matches the signature of the functional interface {@link TemporalQuery}
     * allowing it to be used as a query via method reference, {@code Instant::from}.
     *
     * @param temporal  the temporal object to convert, not null
     * @return the instant, not null
     * @throws DateTimeException if unable to convert to an {@code Instant}
     */
    static Instant from(TemporalAccessor temporal) {
        if (cast(Instant)(temporal) !is null) {
            return cast(Instant) temporal;
        }
        assert(temporal, "temporal");
        try {
            long instantSecs = temporal.getLong(ChronoField.INSTANT_SECONDS);
            int nanoOfSecond = temporal.get(ChronoField.NANO_OF_SECOND);
            return Instant.ofEpochSecond(instantSecs, nanoOfSecond);
        } catch (DateTimeException ex) {
            throw new DateTimeException("Unable to obtain Instant from TemporalAccessor: " ~
                    typeid(temporal).stringof ~ " of type " ~ typeid(temporal).stringof, ex);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Instant} from a text string such as
     * {@code 2007-12-03T10:15:30.00Z}.
     * !(p)
     * The string must represent a valid instant _in UTC and is parsed using
     * {@link DateTimeFormatter#ISO_INSTANT}.
     *
     * @param text  the text to parse, not null
     * @return the parsed instant, not null
     * @throws DateTimeParseException if the text cannot be parsed
     */
    // static Instant parse(const string text) {
    //     return DateTimeFormatter.ISO_INSTANT.parse!Instant(text, new class TemporalQuery!Instant{
    //          Instant queryFrom(TemporalAccessor temporal)
    //          {
    //                  if (cast(Instant)(temporal) !is null) {
    //                     return cast(Instant) temporal;
    //                 }
    //                 assert(temporal, "temporal");
    //                 try {
    //                     long instantSecs = temporal.getLong(ChronoField.INSTANT_SECONDS);
    //                     int nanoOfSecond = temporal.get(ChronoField.NANO_OF_SECOND);
    //                     return Instant.ofEpochSecond(instantSecs, nanoOfSecond);
    //                 } catch (DateTimeException ex) {
    //                     throw new DateTimeException("Unable to obtain Instant from TemporalAccessor: " ~
    //                             typeid(temporal).stringof ~ " of type " ~ typeid(temporal).stringof, ex);
    //                 }
    //          }
    //     });
    // }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Instant} using seconds and nanoseconds.
     *
     * @param seconds  the length of the duration _in seconds
     * @param nanoOfSecond  the nano-of-second, from 0 to 999,999,999
     * @throws DateTimeException if the instant exceeds the maximum or minimum instant
     */
    private static Instant create(long seconds, int nanoOfSecond) {
        if ((seconds | nanoOfSecond) == 0) {
            return EPOCH;
        }
        if (seconds < MIN_SECOND || seconds > MAX_SECOND) {
            throw new DateTimeException("Instant exceeds minimum or maximum instant");
        }
        return new Instant(seconds, nanoOfSecond);
    }

    /**
     * Constructs an instance of {@code Instant} using seconds from the epoch of
     * 1970-01-01T00:00:00Z and nanosecond fraction of second.
     *
     * @param epochSecond  the number of seconds from 1970-01-01T00:00:00Z
     * @param nanos  the nanoseconds within the second, must be positive
     */
    this(long epochSecond, int nanos = 0) {
        // super();
        this.seconds = epochSecond;
        this.nanos = nanos;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if the specified field is supported.
     * !(p)
     * This checks if this instant can be queried for the specified field.
     * If false, then calling the {@link #range(TemporalField) range},
     * {@link #get(TemporalField) get} and {@link #_with(TemporalField, long)}
     * methods will throw an exception.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The supported fields are:
     * !(ul)
     * !(li){@code NANO_OF_SECOND}
     * !(li){@code MICRO_OF_SECOND}
     * !(li){@code MILLI_OF_SECOND}
     * !(li){@code INSTANT_SECONDS}
     * </ul>
     * All other {@code ChronoField} instances will return false.
     * !(p)
     * If the field is not a {@code ChronoField}, then the result of this method
     * is obtained by invoking {@code TemporalField.isSupportedBy(TemporalAccessor)}
     * passing {@code this} as the argument.
     * Whether the field is supported is determined by the field.
     *
     * @param field  the field to check, null returns false
     * @return true if the field is supported on this instant, false if not
     */
    override
    bool isSupported(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            return field == ChronoField.INSTANT_SECONDS || field == ChronoField.NANO_OF_SECOND || field == ChronoField.MICRO_OF_SECOND || field == ChronoField.MILLI_OF_SECOND;
        }
        return field !is null && field.isSupportedBy(this);
    }

    /**
     * Checks if the specified unit is supported.
     * !(p)
     * This checks if the specified unit can be added to, or subtracted from, this date-time.
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
     * !(li){@code DAYS}
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
    override
    bool isSupported(TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            return unit.isTimeBased() || unit == ChronoUnit.DAYS;
        }
        return unit !is null && unit.isSupportedBy(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the range of valid values for the specified field.
     * !(p)
     * The range object expresses the minimum and maximum valid values for a field.
     * This instant is used to enhance the accuracy of the returned range.
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
    override  // override for Javadoc
    ValueRange range(TemporalField field) {
        return /* Temporal. super.*/super_range(field);
    }

      ValueRange super_range(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            if (isSupported(field)) {
                return field.range();
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).stringof);
        }
        assert(field, "field");
        return field.rangeRefinedBy(this);
    }
    /**
     * Gets the value of the specified field from this instant as an {@code int}.
     * !(p)
     * This queries this instant for the value of the specified field.
     * The returned value will always be within the valid range of values for the field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return valid
     * values based on this date-time, except {@code INSTANT_SECONDS} which is too
     * large to fit _in an {@code int} and throws a {@code DateTimeException}.
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
    override  // override for Javadoc and performance
    int get(TemporalField field) {
        if (cast(ChronoField)(field) !is null) {
            auto name = (cast(ChronoField) field).toString;
             {
                if(name == ChronoField.NANO_OF_SECOND.toString) return nanos;
                if(name == ChronoField.MICRO_OF_SECOND.toString) return nanos / 1000;
                if(name == ChronoField.MILLI_OF_SECOND.toString) return nanos / 1000_000;
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).stringof);
        }
        return range(field).checkValidIntValue(field.getFrom(this), field);
    }

    /**
     * Gets the value of the specified field from this instant as a {@code long}.
     * !(p)
     * This queries this instant for the value of the specified field.
     * If it is not possible to return the value, because the field is not supported
     * or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the query is implemented here.
     * The {@link #isSupported(TemporalField) supported fields} will return valid
     * values based on this date-time.
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
            auto name = (cast(ChronoField) field).toString;
            {
                if(name == ChronoField.NANO_OF_SECOND.toString) return nanos;
                if(name == ChronoField.MICRO_OF_SECOND.toString) return nanos / 1000;
                if(name == ChronoField.MILLI_OF_SECOND.toString) return nanos / 1000_000;
                if(name == ChronoField.INSTANT_SECONDS.toString) return seconds;
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).stringof);
        }
        return field.getFrom(this);
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the number of seconds from the Java epoch of 1970-01-01T00:00:00Z.
     * !(p)
     * The epoch second count is a simple incrementing count of seconds where
     * second 0 is 1970-01-01T00:00:00Z.
     * The nanosecond part is returned by {@link #getNano}.
     *
     * @return the seconds from the epoch of 1970-01-01T00:00:00Z
     */
    long getEpochSecond() {
        return seconds;
    }

    /**
     * Gets the number of nanoseconds, later along the time-line, from the start
     * of the second.
     * !(p)
     * The nanosecond-of-second value measures the total number of nanoseconds from
     * the second returned by {@link #getEpochSecond}.
     *
     * @return the nanoseconds within the second, always positive, never exceeds 999,999,999
     */
    int getNano() {
        return nanos;
    }

    //-------------------------------------------------------------------------
    /**
     * Returns an adjusted copy of this instant.
     * !(p)
     * This returns an {@code Instant}, based on this one, with the instant adjusted.
     * The adjustment takes place using the specified adjuster strategy object.
     * Read the documentation of the adjuster to understand what adjustment will be made.
     * !(p)
     * The result of this method is obtained by invoking the
     * {@link TemporalAdjuster#adjustInto(Temporal)} method on the
     * specified adjuster passing {@code this} as the argument.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param adjuster the adjuster to use, not null
     * @return an {@code Instant} based on {@code this} with the adjustment made, not null
     * @throws DateTimeException if the adjustment cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    Instant _with(TemporalAdjuster adjuster) {
        return cast(Instant) adjuster.adjustInto(this);
    }

    /**
     * Returns a copy of this instant with the specified field set to a new value.
     * !(p)
     * This returns an {@code Instant}, based on this one, with the value
     * for the specified field changed.
     * If it is not possible to set the value, because the field is not supported or for
     * some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoField} then the adjustment is implemented here.
     * The supported fields behave as follows:
     * !(ul)
     * !(li){@code NANO_OF_SECOND} -
     *  Returns an {@code Instant} with the specified nano-of-second.
     *  The epoch-second will be unchanged.
     * !(li){@code MICRO_OF_SECOND} -
     *  Returns an {@code Instant} with the nano-of-second replaced by the specified
     *  micro-of-second multiplied by 1,000. The epoch-second will be unchanged.
     * !(li){@code MILLI_OF_SECOND} -
     *  Returns an {@code Instant} with the nano-of-second replaced by the specified
     *  milli-of-second multiplied by 1,000,000. The epoch-second will be unchanged.
     * !(li){@code INSTANT_SECONDS} -
     *  Returns an {@code Instant} with the specified epoch-second.
     *  The nano-of-second will be unchanged.
     * </ul>
     * !(p)
     * In all cases, if the new value is outside the valid range of values for the field
     * then a {@code DateTimeException} will be thrown.
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
     * @return an {@code Instant} based on {@code this} with the specified field set, not null
     * @throws DateTimeException if the field cannot be set
     * @throws UnsupportedTemporalTypeException if the field is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    Instant _with(TemporalField field, long newValue) {
        if (cast(ChronoField)(field) !is null) {
            ChronoField f = cast(ChronoField) field;
            f.checkValidValue(newValue);
            auto name = f.toString;
             {
                if(name == ChronoField.MILLI_OF_SECOND.toString) {
                    int nval = cast(int) newValue * 1000_000;
                    return (nval != nanos ? create(seconds, nval) : this);
                }
                if(name == ChronoField.MICRO_OF_SECOND.toString) {
                    int nval = cast(int) newValue * 1000;
                    return (nval != nanos ? create(seconds, nval) : this);
                }
                if(name == ChronoField.NANO_OF_SECOND.toString) return (newValue != nanos ? create(seconds, cast(int) newValue) : this);
                if(name == ChronoField.INSTANT_SECONDS.toString) return (newValue != seconds ? create(newValue, nanos) : this);
            }
            throw new UnsupportedTemporalTypeException("Unsupported field: " ~ typeid(field).stringof);
        }
        return cast(Instant)(field.adjustInto(this, newValue));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code Instant} truncated to the specified unit.
     * !(p)
     * Truncating the instant returns a copy of the original with fields
     * smaller than the specified unit set to zero.
     * The fields are calculated on the basis of using a UTC offset as seen
     * _in {@code toString}.
     * For example, truncating with the {@link ChronoUnit#MINUTES MINUTES} unit will
     * round down to the nearest minute, setting the seconds and nanoseconds to zero.
     * !(p)
     * The unit must have a {@linkplain TemporalUnit#getDuration() duration}
     * that divides into the length of a standard day without remainder.
     * This includes all supplied time units on {@link ChronoUnit} and
     * {@link ChronoUnit#DAYS DAYS}. Other units throw an exception.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param unit  the unit to truncate to, not null
     * @return an {@code Instant} based on this instant with the time truncated, not null
     * @throws DateTimeException if the unit is invalid for truncation
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     */
    // Instant truncatedTo(TemporalUnit unit) {
    //     if (unit == ChronoUnit.NANOS) {
    //         return this;
    //     }
    //     Duration unitDur = unit.getDuration();
    //     if (unitDur.getSeconds() > LocalTime.SECONDS_PER_DAY) {
    //         throw new UnsupportedTemporalTypeException("Unit is too large to be used for truncation");
    //     }
    //     long dur = unitDur.toNanos();
    //     if ((LocalTime.NANOS_PER_DAY % dur) != 0) {
    //         throw new UnsupportedTemporalTypeException("Unit must divide into a standard day without remainder");
    //     }
    //     long nod = (seconds % LocalTime.SECONDS_PER_DAY) * LocalTime.NANOS_PER_SECOND + nanos;
    //     long result =/*  MathHelper.floorDiv */(nod / (dur)) * dur;
    //     return plusNanos(result - nod);
    // }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this instant with the specified amount added.
     * !(p)
     * This returns an {@code Instant}, based on this one, with the specified amount added.
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
     * @return an {@code Instant} based on this instant with the addition made, not null
     * @throws DateTimeException if the addition cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    Instant plus(TemporalAmount amountToAdd) {
        return cast(Instant) amountToAdd.addTo(this);
    }

    /**
     * Returns a copy of this instant with the specified amount added.
     * !(p)
     * This returns an {@code Instant}, based on this one, with the amount
     * _in terms of the unit added. If it is not possible to add the amount, because the
     * unit is not supported or for some other reason, an exception is thrown.
     * !(p)
     * If the field is a {@link ChronoUnit} then the addition is implemented here.
     * The supported fields behave as follows:
     * !(ul)
     * !(li){@code NANOS} -
     *  Returns an {@code Instant} with the specified number of nanoseconds added.
     *  This is equivalent to {@link #plusNanos(long)}.
     * !(li){@code MICROS} -
     *  Returns an {@code Instant} with the specified number of microseconds added.
     *  This is equivalent to {@link #plusNanos(long)} with the amount
     *  multiplied by 1,000.
     * !(li){@code MILLIS} -
     *  Returns an {@code Instant} with the specified number of milliseconds added.
     *  This is equivalent to {@link #plusNanos(long)} with the amount
     *  multiplied by 1,000,000.
     * !(li){@code SECONDS} -
     *  Returns an {@code Instant} with the specified number of seconds added.
     *  This is equivalent to {@link #plusSeconds(long)}.
     * !(li){@code MINUTES} -
     *  Returns an {@code Instant} with the specified number of minutes added.
     *  This is equivalent to {@link #plusSeconds(long)} with the amount
     *  multiplied by 60.
     * !(li){@code HOURS} -
     *  Returns an {@code Instant} with the specified number of hours added.
     *  This is equivalent to {@link #plusSeconds(long)} with the amount
     *  multiplied by 3,600.
     * !(li){@code HALF_DAYS} -
     *  Returns an {@code Instant} with the specified number of half-days added.
     *  This is equivalent to {@link #plusSeconds(long)} with the amount
     *  multiplied by 43,200 (12 hours).
     * !(li){@code DAYS} -
     *  Returns an {@code Instant} with the specified number of days added.
     *  This is equivalent to {@link #plusSeconds(long)} with the amount
     *  multiplied by 86,400 (24 hours).
     * </ul>
     * !(p)
     * All other {@code ChronoUnit} instances will throw an {@code UnsupportedTemporalTypeException}.
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
     * @return an {@code Instant} based on this instant with the specified amount added, not null
     * @throws DateTimeException if the addition cannot be made
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    Instant plus(long amountToAdd, TemporalUnit unit) {
        if (cast(ChronoUnit)(unit) !is null) {
            auto name = (cast(ChronoUnit) unit).toString;
             {
                if(name ==  ChronoUnit.NANOS.toString) return plusNanos(amountToAdd);
                if(name ==  ChronoUnit.MICROS.toString) return plus(amountToAdd / 1000_000, (amountToAdd % 1000_000) * 1000);
                if(name ==  ChronoUnit.MILLIS.toString) return plusMillis(amountToAdd);
                if(name ==  ChronoUnit.SECONDS.toString) return plusSeconds(amountToAdd);
                if(name ==  ChronoUnit.MINUTES.toString) return plusSeconds(MathHelper.multiplyExact(amountToAdd , LocalTime.SECONDS_PER_MINUTE));
                if(name ==  ChronoUnit.HOURS.toString) return plusSeconds(MathHelper.multiplyExact(amountToAdd , LocalTime.SECONDS_PER_HOUR));
                if(name ==  ChronoUnit.HALF_DAYS.toString) return plusSeconds(MathHelper.multiplyExact(amountToAdd , LocalTime.SECONDS_PER_DAY / 2));
                if(name ==  ChronoUnit.DAYS.toString) return plusSeconds(MathHelper.multiplyExact(amountToAdd , LocalTime.SECONDS_PER_DAY));
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ typeid(unit).stringof);
        }
        return cast(Instant)(unit.addTo(this, amountToAdd));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this instant with the specified duration _in seconds added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param secondsToAdd  the seconds to add, positive or negative
     * @return an {@code Instant} based on this instant with the specified seconds added, not null
     * @throws DateTimeException if the result exceeds the maximum or minimum instant
     * @throws ArithmeticException if numeric overflow occurs
     */
    Instant plusSeconds(long secondsToAdd) {
        return plus(secondsToAdd, 0);
    }

    /**
     * Returns a copy of this instant with the specified duration _in milliseconds added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param millisToAdd  the milliseconds to add, positive or negative
     * @return an {@code Instant} based on this instant with the specified milliseconds added, not null
     * @throws DateTimeException if the result exceeds the maximum or minimum instant
     * @throws ArithmeticException if numeric overflow occurs
     */
    Instant plusMillis(long millisToAdd) {
        return plus(millisToAdd / 1000, (millisToAdd % 1000) * 1000_000);
    }

    /**
     * Returns a copy of this instant with the specified duration _in nanoseconds added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanosToAdd  the nanoseconds to add, positive or negative
     * @return an {@code Instant} based on this instant with the specified nanoseconds added, not null
     * @throws DateTimeException if the result exceeds the maximum or minimum instant
     * @throws ArithmeticException if numeric overflow occurs
     */
    Instant plusNanos(long nanosToAdd) {
        return plus(0, nanosToAdd);
    }

    /**
     * Returns a copy of this instant with the specified duration added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param secondsToAdd  the seconds to add, positive or negative
     * @param nanosToAdd  the nanos to add, positive or negative
     * @return an {@code Instant} based on this instant with the specified seconds added, not null
     * @throws DateTimeException if the result exceeds the maximum or minimum instant
     * @throws ArithmeticException if numeric overflow occurs
     */
    private Instant plus(long secondsToAdd, long nanosToAdd) {
        if ((secondsToAdd | nanosToAdd) == 0) {
            return this;
        }
        long epochSec = MathHelper.addExact(seconds , secondsToAdd);
        epochSec = MathHelper.addExact(epochSec , nanosToAdd / LocalTime.NANOS_PER_SECOND);
        nanosToAdd = nanosToAdd % LocalTime.NANOS_PER_SECOND;
        long nanoAdjustment = nanos + nanosToAdd;  // safe int+NANOS_PER_SECOND
        return ofEpochSecond(epochSec, nanoAdjustment);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this instant with the specified amount subtracted.
     * !(p)
     * This returns an {@code Instant}, based on this one, with the specified amount subtracted.
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
     * @return an {@code Instant} based on this instant with the subtraction made, not null
     * @throws DateTimeException if the subtraction cannot be made
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    Instant minus(TemporalAmount amountToSubtract) {
        return cast(Instant) amountToSubtract.subtractFrom(this);
    }

    /**
     * Returns a copy of this instant with the specified amount subtracted.
     * !(p)
     * This returns an {@code Instant}, based on this one, with the amount
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
     * @return an {@code Instant} based on this instant with the specified amount subtracted, not null
     * @throws DateTimeException if the subtraction cannot be made
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    Instant minus(long amountToSubtract, TemporalUnit unit) {
        return (amountToSubtract == Long.MIN_VALUE ? plus(Long.MAX_VALUE, unit).plus(1, unit) : plus(-amountToSubtract, unit));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this instant with the specified duration _in seconds subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param secondsToSubtract  the seconds to subtract, positive or negative
     * @return an {@code Instant} based on this instant with the specified seconds subtracted, not null
     * @throws DateTimeException if the result exceeds the maximum or minimum instant
     * @throws ArithmeticException if numeric overflow occurs
     */
    Instant minusSeconds(long secondsToSubtract) {
        if (secondsToSubtract == Long.MIN_VALUE) {
            return plusSeconds(Long.MAX_VALUE).plusSeconds(1);
        }
        return plusSeconds(-secondsToSubtract);
    }

    /**
     * Returns a copy of this instant with the specified duration _in milliseconds subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param millisToSubtract  the milliseconds to subtract, positive or negative
     * @return an {@code Instant} based on this instant with the specified milliseconds subtracted, not null
     * @throws DateTimeException if the result exceeds the maximum or minimum instant
     * @throws ArithmeticException if numeric overflow occurs
     */
    Instant minusMillis(long millisToSubtract) {
        if (millisToSubtract == Long.MIN_VALUE) {
            return plusMillis(Long.MAX_VALUE).plusMillis(1);
        }
        return plusMillis(-millisToSubtract);
    }

    /**
     * Returns a copy of this instant with the specified duration _in nanoseconds subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanosToSubtract  the nanoseconds to subtract, positive or negative
     * @return an {@code Instant} based on this instant with the specified nanoseconds subtracted, not null
     * @throws DateTimeException if the result exceeds the maximum or minimum instant
     * @throws ArithmeticException if numeric overflow occurs
     */
    Instant minusNanos(long nanosToSubtract) {
        if (nanosToSubtract == Long.MIN_VALUE) {
            return plusNanos(Long.MAX_VALUE).plusNanos(1);
        }
        return plusNanos(-nanosToSubtract);
    }

    //-------------------------------------------------------------------------
    /**
     * Queries this instant using the specified query.
     * !(p)
     * This queries this instant using the specified query strategy object.
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
        if (query == TemporalQueries.precision()) {
            return cast(R) (ChronoUnit.NANOS);
        }
        // inline TemporalAccessor.super.query(query) as an optimization
        if (query == TemporalQueries.chronology() || query == TemporalQueries.zoneId() ||
                query == TemporalQueries.zone() || query == TemporalQueries.offset() ||
                query == TemporalQueries.localDate() || query == TemporalQueries.localTime()) {
            return null;
        }
        return query.queryFrom(this);
    }

    /**
     * Adjusts the specified temporal object to have this instant.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with the instant changed to be the same as this.
     * !(p)
     * The adjustment is equivalent to using {@link Temporal#_with(TemporalField, long)}
     * twice, passing {@link ChronoField#INSTANT_SECONDS} and
     * {@link ChronoField#NANO_OF_SECOND} as the fields.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#_with(TemporalAdjuster)}:
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   temporal = thisInstant.adjustInto(temporal);
     *   temporal = temporal._with(thisInstant);
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
        return temporal._with(ChronoField.INSTANT_SECONDS, seconds)._with(ChronoField.NANO_OF_SECOND, nanos);
    }

    /**
     * Calculates the amount of time until another instant _in terms of the specified unit.
     * !(p)
     * This calculates the amount of time between two {@code Instant}
     * objects _in terms of a single {@code TemporalUnit}.
     * The start and end points are {@code this} and the specified instant.
     * The result will be negative if the end is before the start.
     * The calculation returns a whole number, representing the number of
     * complete units between the two instants.
     * The {@code Temporal} passed to this method is converted to a
     * {@code Instant} using {@link #from(TemporalAccessor)}.
     * For example, the amount _in seconds between two dates can be calculated
     * using {@code startInstant.until(endInstant, SECONDS)}.
     * !(p)
     * There are two equivalent ways of using this method.
     * The first is to invoke this method.
     * The second is to use {@link TemporalUnit#between(Temporal, Temporal)}:
     * !(pre)
     *   // these two lines are equivalent
     *   amount = start.until(end, SECONDS);
     *   amount = SECONDS.between(start, end);
     * </pre>
     * The choice should be made based on which makes the code more readable.
     * !(p)
     * The calculation is implemented _in this method for {@link ChronoUnit}.
     * The units {@code NANOS}, {@code MICROS}, {@code MILLIS}, {@code SECONDS},
     * {@code MINUTES}, {@code HOURS}, {@code HALF_DAYS} and {@code DAYS}
     * are supported. Other {@code ChronoUnit} values will throw an exception.
     * !(p)
     * If the unit is not a {@code ChronoUnit}, then the result of this method
     * is obtained by invoking {@code TemporalUnit.between(Temporal, Temporal)}
     * passing {@code this} as the first argument and the converted input temporal
     * as the second argument.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param endExclusive  the end date, exclusive, which is converted to an {@code Instant}, not null
     * @param unit  the unit to measure the amount _in, not null
     * @return the amount of time between this instant and the end instant
     * @throws DateTimeException if the amount cannot be calculated, or the end
     *  temporal cannot be converted to an {@code Instant}
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    long until(Temporal endExclusive, TemporalUnit unit) {
        Instant end = Instant.from(endExclusive);
        if (cast(ChronoUnit)(unit) !is null) {
            auto name = (cast(ChronoUnit) unit).toString;
             {
                if(name == ChronoUnit.NANOS.toString) return nanosUntil(end);
                if(name == ChronoUnit.MICROS.toString) return nanosUntil(end) / 1000;
                if(name == ChronoUnit.MILLIS.toString) return MathHelper.subtractExact(end.toEpochMilli() , toEpochMilli());
                if(name == ChronoUnit.SECONDS.toString) return secondsUntil(end);
                if(name == ChronoUnit.MINUTES.toString) return secondsUntil(end) / LocalTime.SECONDS_PER_MINUTE;
                if(name == ChronoUnit.HOURS.toString) return secondsUntil(end) / LocalTime.SECONDS_PER_HOUR;
                if(name == ChronoUnit.HALF_DAYS.toString) return secondsUntil(end) / (12 * LocalTime.SECONDS_PER_HOUR);
                if(name == ChronoUnit.DAYS.toString) return secondsUntil(end) / (LocalTime.SECONDS_PER_DAY);
            }
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ name);
        }
        return unit.between(this, end);
    }

    private long nanosUntil(Instant end) {
        long secsDiff = MathHelper.subtractExact(end.seconds , seconds);
        long totalNanos = MathHelper.multiplyExact(secsDiff , LocalTime.NANOS_PER_SECOND);
        return MathHelper.addExact(totalNanos , end.nanos - nanos);
    }

    private long secondsUntil(Instant end) {
        long secsDiff = MathHelper.subtractExact(end.seconds , seconds);
        long nanosDiff = end.nanos - nanos;
        if (secsDiff > 0 && nanosDiff < 0) {
            secsDiff--;
        } else if (secsDiff < 0 && nanosDiff > 0) {
            secsDiff++;
        }
        return secsDiff;
    }

    //-----------------------------------------------------------------------
    /**
     * Combines this instant with an offset to create an {@code OffsetDateTime}.
     * !(p)
     * This returns an {@code OffsetDateTime} formed from this instant at the
     * specified offset from UTC/Greenwich. An exception will be thrown if the
     * instant is too large to fit into an offset date-time.
     * !(p)
     * This method is equivalent to
     * {@link OffsetDateTime#ofInstant(Instant, ZoneId) OffsetDateTime.ofInstant(this, offset)}.
     *
     * @param offset  the offset to combine with, not null
     * @return the offset date-time formed from this instant and the specified offset, not null
     * @throws DateTimeException if the result exceeds the supported range
     */
    OffsetDateTime atOffset(ZoneOffset offset) {
        return OffsetDateTime.ofInstant(this, offset);
    }

    /**
     * Combines this instant with a time-zone to create a {@code ZonedDateTime}.
     * !(p)
     * This returns an {@code ZonedDateTime} formed from this instant at the
     * specified time-zone. An exception will be thrown if the instant is too
     * large to fit into a zoned date-time.
     * !(p)
     * This method is equivalent to
     * {@link ZonedDateTime#ofInstant(Instant, ZoneId) ZonedDateTime.ofInstant(this, zone)}.
     *
     * @param zone  the zone to combine with, not null
     * @return the zoned date-time formed from this instant and the specified zone, not null
     * @throws DateTimeException if the result exceeds the supported range
     */
    ZonedDateTime atZone(ZoneId zone) {
        return ZonedDateTime.ofInstant(this, zone);
    }

    //-----------------------------------------------------------------------
    /**
     * Converts this instant to the number of milliseconds from the epoch
     * of 1970-01-01T00:00:00Z.
     * !(p)
     * If this instant represents a point on the time-line too far _in the future
     * or past to fit _in a {@code long} milliseconds, then an exception is thrown.
     * !(p)
     * If this instant has greater than millisecond precision, then the conversion
     * will drop any excess precision information as though the amount _in nanoseconds
     * was subject to integer division by one million.
     *
     * @return the number of milliseconds since the epoch of 1970-01-01T00:00:00Z
     * @throws ArithmeticException if numeric overflow occurs
     */
    long toEpochMilli() {
        if (seconds < 0 && nanos > 0) {
            long millis = MathHelper.multiplyExact((seconds+1) , 1000);
            long adjustment = nanos / 1000_000 - 1000;
            return MathHelper.addExact(millis , adjustment);
        } else {
            long millis = MathHelper.multiplyExact(seconds , 1000);
            return MathHelper.addExact(millis , nanos / 1000_000);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Compares this instant to the specified instant.
     * !(p)
     * The comparison is based on the time-line position of the instants.
     * It is "consistent with equals", as defined by {@link Comparable}.
     *
     * @param otherInstant  the other instant to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     * @throws NullPointerException if otherInstant is null
     */
    // override
    int compareTo(Instant otherInstant) {
        int cmp = compare(seconds, otherInstant.seconds);
        if (cmp != 0) {
            return cmp;
        }
        return nanos - otherInstant.nanos;
    }

    /**
     * Checks if this instant is after the specified instant.
     * !(p)
     * The comparison is based on the time-line position of the instants.
     *
     * @param otherInstant  the other instant to compare to, not null
     * @return true if this instant is after the specified instant
     * @throws NullPointerException if otherInstant is null
     */
    bool isAfter(Instant otherInstant) {
        return compareTo(otherInstant) > 0;
    }

    /**
     * Checks if this instant is before the specified instant.
     * !(p)
     * The comparison is based on the time-line position of the instants.
     *
     * @param otherInstant  the other instant to compare to, not null
     * @return true if this instant is before the specified instant
     * @throws NullPointerException if otherInstant is null
     */
    bool isBefore(Instant otherInstant) {
        return compareTo(otherInstant) < 0;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this instant is equal to the specified instant.
     * !(p)
     * The comparison is based on the time-line position of the instants.
     *
     * @param otherInstant  the other instant, null returns false
     * @return true if the other instant is equal to this one
     */
    override
    bool opEquals(Object otherInstant) {
        if (this == otherInstant) {
            return true;
        }
        if (cast(Instant)(otherInstant) !is null) {
            Instant other = cast(Instant) otherInstant;
            return this.seconds == other.seconds &&
                   this.nanos == other.nanos;
        }
        return false;
    }

    /**
     * Returns a hash code for this instant.
     *
     * @return a suitable hash code
     */
    override
    size_t toHash() @trusted nothrow {
        return (cast(int) (seconds ^ (seconds >>> 32))) + 51 * nanos;
    }

    //-----------------------------------------------------------------------
    /**
     * A string representation of this instant using ISO-8601 representation.
     * !(p)
     * The format used is the same as {@link DateTimeFormatter#ISO_INSTANT}.
     *
     * @return an ISO-8601 representation of this instant, not null
     */
    override
    string toString() {
        // TODO: Tasks pending completion -@zxp at 12/27/2018, 8:05:39 PM
        // 
        return "TODO";
        // return DateTimeFormatter.ISO_INSTANT.format(this);
    }

    // -----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(2);  // identifies an Instant
     *  _out.writeLong(seconds);
     *  _out.writeInt(nanos);
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.INSTANT_TYPE, this);
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

    void writeExternal(DataOutput _out) /*throws IOException*/ {
        _out.writeLong(seconds);
        _out.writeInt(nanos);
    }

    static Instant readExternal(DataInput _in) /*throws IOException*/ {
        long seconds = _in.readLong();
        int nanos = _in.readInt();
        return Instant.ofEpochSecond(seconds, nanos);
    }

    override int opCmp(Instant o)
    {
        auto res = compare(this.seconds,o.seconds);
        if(res == 0)
            res = compare(this.nanos,o.nanos);
        return res;
    }

}
