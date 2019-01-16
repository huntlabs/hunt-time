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

hunt.time.Duration;

import hunt.time.LocalTime;
import hunt.time.Ser;

import hunt.io.DataInput;
import hunt.io.DataOutput;
import hunt.lang.exception;
// //import hunt.io.ObjectInputStream;
import hunt.io.common;
import hunt.math.BigDecimal;
import hunt.math.BigInteger;
import hunt.time.DateTimeException;
import hunt.time.format.DateTimeParseException;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.ChronoUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalAmount;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.UnsupportedTemporalTypeException;
import hunt.container;
import hunt.lang.common;
import hunt.lang;
import hunt.string.common;
import std.regex;
import std.string;
import std.conv;
import hunt.string.StringBuilder;
import hunt.util.Comparator;
import hunt.time.util.common;
// import hunt.util.regex.Matcher;
// import hunt.util.regex.Pattern;

/**
 * A time-based amount of time, such as '34.5 seconds'.
 * !(p)
 * This class models a quantity or amount of time _in terms of seconds and nanoseconds.
 * It can be accessed using other duration-based units, such as minutes and hours.
 * In addition, the {@link ChronoUnit#DAYS DAYS} unit can be used and is treated as
 * exactly equal to 24 hours, thus ignoring daylight savings effects.
 * See {@link Period} for the date-based equivalent to this class.
 * !(p)
 * A physical duration could be of infinite length.
 * For practicality, the duration is stored with constraints similar to {@link Instant}.
 * The duration uses nanosecond resolution with a maximum value of the seconds that can
 * be held _in a {@code long}. This is greater than the current estimated age of the universe.
 * !(p)
 * The range of a duration requires the storage of a number larger than a {@code long}.
 * To achieve this, the class stores a {@code long} representing seconds and an {@code int}
 * representing nanosecond-of-second, which will always be between 0 and 999,999,999.
 * The model is of a directed duration, meaning that the duration may be negative.
 * !(p)
 * The duration is measured _in "seconds", but these are not necessarily identical to
 * the scientific "SI second" definition based on atomic clocks.
 * This difference only impacts durations measured near a leap-second and should not affect
 * most applications.
 * See {@link Instant} for a discussion as to the meaning of the second and time-scales.
 *
 * !(p)
 * This is a <a href="{@docRoot}/java.base/java/lang/doc-files/ValueBased.html">value-based</a>
 * class; use of identity-sensitive operations (including reference equality
 * ({@code ==}), identity hash code, or synchronization) on instances of
 * {@code Duration} may have unpredictable results and should be avoided.
 * The {@code equals} method should be used for comparisons.
 *
 * @implSpec
 * This class is immutable and thread-safe.
 *
 * @since 1.8
 */
public final class Duration
        : TemporalAmount, Comparable!(Duration), Serializable {

    /**
     * Constant for a duration of zero.
     */
    // public __gshared Duration ZERO;
    /**
     * Serialization version.
     */
    private enum long serialVersionUID = 3078945930695997490L;
    /**
     * Constant for nanos per second.
     */
    // __gshared BigInteger BI_NANOS_PER_SECOND;

    // shared static this()
    // {
    //     // ZERO = new Duration(0, 0);
        mixin(MakeGlobalVar!(Duration)("ZERO",`new Duration(0, 0)`));
        // BI_NANOS_PER_SECOND = BigInteger.valueOf(LocalTime.NANOS_PER_SECOND);
        mixin(MakeGlobalVar!(BigInteger)("BI_NANOS_PER_SECOND",`BigInteger.valueOf(LocalTime.NANOS_PER_SECOND)`));

    // }
    /**
     * The pattern for parsing.
     */
    private static class Lazy {
        enum string PATTERN =
            "([-+]?)P(?:([-+]?[0-9]+)D)?" ~
                    "(T(?:([-+]?[0-9]+)H)?(?:([-+]?[0-9]+)M)?(?:([-+]?[0-9]+)(?:[.,]([0-9]{0,9}))?S)?)?";
    }

    /**
     * The number of seconds _in the duration.
     */
    private  long seconds;
    /**
     * The number of nanoseconds _in the duration, expressed as a fraction of the
     * number of seconds. This is always positive, and never exceeds 999,999,999.
     */
    private  int nanos;

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Duration} representing a number of standard 24 hour days.
     * !(p)
     * The seconds are calculated based on the standard definition of a day,
     * where each day is 86400 seconds which implies a 24 hour day.
     * The nanosecond _in second field is set to zero.
     *
     * @param days  the number of days, positive or negative
     * @return a {@code Duration}, not null
     * @throws ArithmeticException if the input days exceeds the capacity of {@code Duration}
     */
    public static Duration ofDays(long days) {
        return create(Math.multiplyExact(days , LocalTime.SECONDS_PER_DAY), 0);
    }

    /**
     * Obtains a {@code Duration} representing a number of standard hours.
     * !(p)
     * The seconds are calculated based on the standard definition of an hour,
     * where each hour is 3600 seconds.
     * The nanosecond _in second field is set to zero.
     *
     * @param hours  the number of hours, positive or negative
     * @return a {@code Duration}, not null
     * @throws ArithmeticException if the input hours exceeds the capacity of {@code Duration}
     */
    public static Duration ofHours(long hours) {
        return create(Math.multiplyExact(hours, LocalTime.SECONDS_PER_HOUR), 0);
    }

    /**
     * Obtains a {@code Duration} representing a number of standard minutes.
     * !(p)
     * The seconds are calculated based on the standard definition of a minute,
     * where each minute is 60 seconds.
     * The nanosecond _in second field is set to zero.
     *
     * @param minutes  the number of minutes, positive or negative
     * @return a {@code Duration}, not null
     * @throws ArithmeticException if the input minutes exceeds the capacity of {@code Duration}
     */
    public static Duration ofMinutes(long minutes) {
        return create(Math.multiplyExact(minutes, LocalTime.SECONDS_PER_MINUTE), 0);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Duration} representing a number of seconds.
     * !(p)
     * The nanosecond _in second field is set to zero.
     *
     * @param seconds  the number of seconds, positive or negative
     * @return a {@code Duration}, not null
     */
    public static Duration ofSeconds(long seconds) {
        return create(seconds, 0);
    }

    /**
     * Obtains a {@code Duration} representing a number of seconds and an
     * adjustment _in nanoseconds.
     * !(p)
     * This method allows an arbitrary number of nanoseconds to be passed _in.
     * The factory will alter the values of the second and nanosecond _in order
     * to ensure that the stored nanosecond is _in the range 0 to 999,999,999.
     * For example, the following will result _in exactly the same duration:
     * !(pre)
     *  Duration.ofSeconds(3, 1);
     *  Duration.ofSeconds(4, -999_999_999);
     *  Duration.ofSeconds(2, 1000_000_001);
     * </pre>
     *
     * @param seconds  the number of seconds, positive or negative
     * @param nanoAdjustment  the nanosecond adjustment to the number of seconds, positive or negative
     * @return a {@code Duration}, not null
     * @throws ArithmeticException if the adjustment causes the seconds to exceed the capacity of {@code Duration}
     */
    public static Duration ofSeconds(long seconds, long nanoAdjustment) {
        long secs = Math.addExact(seconds , Math.floorDiv(nanoAdjustment , LocalTime.NANOS_PER_SECOND));
        int nos = cast(int) (Math.floorMod(nanoAdjustment, LocalTime.NANOS_PER_SECOND));
        return create(secs, nos);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Duration} representing a number of milliseconds.
     * !(p)
     * The seconds and nanoseconds are extracted from the specified milliseconds.
     *
     * @param millis  the number of milliseconds, positive or negative
     * @return a {@code Duration}, not null
     */
    public static Duration ofMillis(long millis) {
        long secs = millis / 1000;
        int mos = cast(int) (millis % 1000);
        if (mos < 0) {
            mos += 1000;
            secs--;
        }
        return create(secs, mos * 1000_000);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Duration} representing a number of nanoseconds.
     * !(p)
     * The seconds and nanoseconds are extracted from the specified nanoseconds.
     *
     * @param nanos  the number of nanoseconds, positive or negative
     * @return a {@code Duration}, not null
     */
    public static Duration ofNanos(long nanos) {
        long secs = nanos / LocalTime.NANOS_PER_SECOND;
        int nos = cast(int) (nanos % LocalTime.NANOS_PER_SECOND);
        if (nos < 0) {
            nos += LocalTime.NANOS_PER_SECOND;
            secs--;
        }
        return create(secs, nos);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Duration} representing an amount _in the specified unit.
     * !(p)
     * The parameters represent the two parts of a phrase like '6 Hours'. For example:
     * !(pre)
     *  Duration.of(3, SECONDS);
     *  Duration.of(465, HOURS);
     * </pre>
     * Only a subset of units are accepted by this method.
     * The unit must either have an {@linkplain TemporalUnit#isDurationEstimated() exact duration} or
     * be {@link ChronoUnit#DAYS} which is treated as 24 hours. Other units throw an exception.
     *
     * @param amount  the amount of the duration, measured _in terms of the unit, positive or negative
     * @param unit  the unit that the duration is measured _in, must have an exact duration, not null
     * @return a {@code Duration}, not null
     * @throws DateTimeException if the period unit has an estimated duration
     * @throws ArithmeticException if a numeric overflow occurs
     */
    public static Duration of(long amount, TemporalUnit unit) {
        return ZERO.plus(amount, unit);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Duration} from a temporal amount.
     * !(p)
     * This obtains a duration based on the specified amount.
     * A {@code TemporalAmount} represents an  amount of time, which may be
     * date-based or time-based, which this factory extracts to a duration.
     * !(p)
     * The conversion loops around the set of units from the amount and uses
     * the {@linkplain TemporalUnit#getDuration() duration} of the unit to
     * calculate the total {@code Duration}.
     * Only a subset of units are accepted by this method. The unit must either
     * have an {@linkplain TemporalUnit#isDurationEstimated() exact duration}
     * or be {@link ChronoUnit#DAYS} which is treated as 24 hours.
     * If any other units are found then an exception is thrown.
     *
     * @param amount  the temporal amount to convert, not null
     * @return the equivalent duration, not null
     * @throws DateTimeException if unable to convert to a {@code Duration}
     * @throws ArithmeticException if numeric overflow occurs
     */
    public static Duration from(TemporalAmount amount) {
        assert(amount, "amount");
        Duration duration = ZERO;
        foreach(TemporalUnit unit ; amount.getUnits()) {
            duration = duration.plus(amount.get(unit), unit);
        }
        return duration;
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Duration} from a text string such as {@code PnDTnHnMn.nS}.
     * !(p)
     * This will parse a textual representation of a duration, including the
     * string produced by {@code toString()}. The formats accepted are based
     * on the ISO-8601 duration format {@code PnDTnHnMn.nS} with days
     * considered to be exactly 24 hours.
     * !(p)
     * The string starts with an optional sign, denoted by the ASCII negative
     * or positive symbol. If negative, the whole period is negated.
     * The ASCII letter "P" is next _in upper or lower case.
     * There are then four sections, each consisting of a number and a suffix.
     * The sections have suffixes _in ASCII of "D", "H", "M" and "S" for
     * days, hours, minutes and seconds, accepted _in upper or lower case.
     * The suffixes must occur _in order. The ASCII letter "T" must occur before
     * the first occurrence, if any, of an hour, minute or second section.
     * At least one of the four sections must be present, and if "T" is present
     * there must be at least one section after the "T".
     * The number part of each section must consist of one or more ASCII digits.
     * The number may be prefixed by the ASCII negative or positive symbol.
     * The number of days, hours and minutes must parse to a {@code long}.
     * The number of seconds must parse to a {@code long} with optional fraction.
     * The decimal point may be either a dot or a comma.
     * The fractional part may have from zero to 9 digits.
     * !(p)
     * The leading plus/minus sign, and negative values for other units are
     * not part of the ISO-8601 standard.
     * !(p)
     * Examples:
     * !(pre)
     *    "PT20.345S" -- parses as "20.345 seconds"
     *    "PT15M"     -- parses as "15 minutes" (where a minute is 60 seconds)
     *    "PT10H"     -- parses as "10 hours" (where an hour is 3600 seconds)
     *    "P2D"       -- parses as "2 days" (where a day is 24 hours or 86400 seconds)
     *    "P2DT3H4M"  -- parses as "2 days, 3 hours and 4 minutes"
     *    "PT-6H3M"    -- parses as "-6 hours and +3 minutes"
     *    "-PT6H3M"    -- parses as "-6 hours and -3 minutes"
     *    "-PT-6H+3M"  -- parses as "+6 hours and -3 minutes"
     * </pre>
     *
     * @param text  the text to parse, not null
     * @return the parsed duration, not null
     * @throws DateTimeParseException if the text cannot be parsed to a duration
     */
    public static Duration parse(string text) {
        assert(text, "text");
        auto matchers = matchAll(text,Lazy.PATTERN);
        if (!matchers.empty()) {
            // check for letter T but no time sections
            auto matcher = matchers.front();
            if (!charMatch(text, matcher.captures[2], 'T')) {
                bool negate = charMatch(text, matcher.captures[0], '-');

                string dayStart = matcher.captures[1];
                string hourStart = matcher.captures[3];
                string minuteStart = matcher.captures[4];
                string secondStart = matcher.captures[5];
                string fractionStart = matcher.captures[6];

                if (dayStart.length >= 0 || hourStart.length >= 0 || minuteStart.length >= 0 || secondStart.length >= 0) {
                    long daysAsSecs = parseNumber(text, dayStart, LocalTime.SECONDS_PER_DAY, "days");
                    long hoursAsSecs = parseNumber(text, hourStart, LocalTime.SECONDS_PER_HOUR, "hours");
                    long minsAsSecs = parseNumber(text, minuteStart, LocalTime.SECONDS_PER_MINUTE, "minutes");
                    long seconds = parseNumber(text, secondStart, 1, "seconds");
                    bool negativeSecs = secondStart.length >= 0 && secondStart[0] == '-';
                    int nanos = parseFraction(text, fractionStart, negativeSecs ? -1 : 1);
                    try {
                        return create(negate, daysAsSecs, hoursAsSecs, minsAsSecs, seconds, nanos);
                    } catch (ArithmeticException ex) {
                        throw cast(DateTimeParseException) new DateTimeParseException("Text cannot be parsed to a Duration: overflow", text, 0)/* .initCause(ex) */;
                    }
                }
            }
        }
        throw new DateTimeParseException("Text cannot be parsed to a Duration", text, 0);
    }

    private static bool charMatch(string text, string m, char c) {
        return (m.length == 1 &&  m[0] == c);
    }

    private static long parseNumber(string text, string data, int multiplier, string errorText) {
        // regex limits to [-+]?[0-9]+
        if (!isNumeric(data) || data.length == 0) {
            return 0;
        }
        try {
            long val = to!long(data);
            return Math.multiplyExact(val , multiplier);
        } catch (Exception ex) {
            throw new Exception("Text cannot be parsed to a Duration: " ~  ex.msg);
        }
    }

    private static int parseFraction(string text, string data, int negate) {
        // regex limits to [0-9]{0,9}
        if (!isNumeric(data) || data.length == 0) {
            return 0;
        }
        try {
            int fraction = to!int(data);

            // for number strings smaller than 9 digits, interpret as if there
            // were trailing zeros
            for (int i = cast(int)(data.length); i < 9; i++) {
                fraction *= 10;
            }
            return fraction * negate;
        } catch (Exception ex) {
            throw new Exception("Text cannot be parsed to a Duration: fraction , " ,ex.msg);
        }
    }

    private static Duration create(bool negate, long daysAsSecs, long hoursAsSecs, long minsAsSecs, long secs, int nanos) {
        long seconds = Math.addExact(daysAsSecs , Math.addExact(hoursAsSecs ,  Math.addExact(minsAsSecs , secs)));
        if (negate) {
            return ofSeconds(seconds, nanos).negated();
        }
        return ofSeconds(seconds, nanos);
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains a {@code Duration} representing the duration between two temporal objects.
     * !(p)
     * This calculates the duration between two temporal objects. If the objects
     * are of different types, then the duration is calculated based on the type
     * of the first object. For example, if the first argument is a {@code LocalTime}
     * then the second argument is converted to a {@code LocalTime}.
     * !(p)
     * The specified temporal objects must support the {@link ChronoUnit#SECONDS SECONDS} unit.
     * For full accuracy, either the {@link ChronoUnit#NANOS NANOS} unit or the
     * {@link ChronoField#NANO_OF_SECOND NANO_OF_SECOND} field should be supported.
     * !(p)
     * The result of this method can be a negative period if the end is before the start.
     * To guarantee to obtain a positive duration call {@link #abs()} on the result.
     *
     * @param startInclusive  the start instant, inclusive, not null
     * @param endExclusive  the end instant, exclusive, not null
     * @return a {@code Duration}, not null
     * @throws DateTimeException if the seconds between the temporals cannot be obtained
     * @throws ArithmeticException if the calculation exceeds the capacity of {@code Duration}
     */
    public static Duration between(Temporal startInclusive, Temporal endExclusive) {
        try {
            return ofNanos(startInclusive.until(endExclusive, ChronoUnit.NANOS));
        } catch (DateTimeException  ex) {
            long secs = startInclusive.until(endExclusive, ChronoUnit.SECONDS);
            long nanos;
            try {
                nanos = endExclusive.getLong(ChronoField.NANO_OF_SECOND) - startInclusive.getLong(ChronoField.NANO_OF_SECOND);
                if (secs > 0 && nanos < 0) {
                    secs++;
                } else if (secs < 0 && nanos > 0) {
                    secs--;
                }
            } catch (DateTimeException ex2) {
                nanos = 0;
            }
            return ofSeconds(secs, nanos);
        }
    }

    //-----------------------------------------------------------------------
    /**
     * Obtains an instance of {@code Duration} using seconds and nanoseconds.
     *
     * @param seconds  the length of the duration _in seconds, positive or negative
     * @param nanoAdjustment  the nanosecond adjustment within the second, from 0 to 999,999,999
     */
    private static Duration create(long seconds, int nanoAdjustment) {
        if ((seconds | nanoAdjustment) == 0) {
            return ZERO;
        }
        return new Duration(seconds, nanoAdjustment);
    }

    /**
     * Constructs an instance of {@code Duration} using seconds and nanoseconds.
     *
     * @param seconds  the length of the duration _in seconds, positive or negative
     * @param nanos  the nanoseconds within the second, from 0 to 999,999,999
     */
    this(long seconds, int nanos) {
        // super();///@gxc
        this.seconds = seconds;
        this.nanos = nanos;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the value of the requested unit.
     * !(p)
     * This returns a value for each of the two supported units,
     * {@link ChronoUnit#SECONDS SECONDS} and {@link ChronoUnit#NANOS NANOS}.
     * All other units throw an exception.
     *
     * @param unit the {@code TemporalUnit} for which to return the value
     * @return the long value of the unit
     * @throws DateTimeException if the unit is not supported
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     */
    override
    public long get(TemporalUnit unit) {
        if (unit == ChronoUnit.SECONDS) {
            return seconds;
        } else if (unit == ChronoUnit.NANOS) {
            return nanos;
        } else {
            throw new UnsupportedTemporalTypeException("Unsupported unit: " ~ typeid(unit).stringof);
        }
    }

    /**
     * Gets the set of units supported by this duration.
     * !(p)
     * The supported units are {@link ChronoUnit#SECONDS SECONDS},
     * and {@link ChronoUnit#NANOS NANOS}.
     * They are returned _in the order seconds, nanos.
     * !(p)
     * This set can be used _in conjunction with {@link #get(TemporalUnit)}
     * to access the entire state of the duration.
     *
     * @return a list containing the seconds and nanos units, not null
     */
    override
    public List!(TemporalUnit) getUnits() {
        return DurationUnits.UNITS;
    }

    /**
     * Private class to delay initialization of this list until needed.
     * The circular dependency between Duration and ChronoUnit prevents
     * the simple initialization _in Duration.
     */
     static class DurationUnits {
        __gshared List!(TemporalUnit) _UNITS;
        public static ref List!(TemporalUnit) UNITS()
        {
            if(_UNITS is null)
            {
                _UNITS = new ArrayList!(TemporalUnit)();
            
                _UNITS.add(ChronoUnit.SECONDS);
                _UNITS.add(ChronoUnit.NANOS);
            }
            return _UNITS;
        }
        // shared static this()
        // {
        //     UNITS = new ArrayList!(TemporalUnit)();
            
        //     UNITS.add(ChronoUnit.SECONDS);
        //     UNITS.add(ChronoUnit.NANOS);
        // }
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this duration is zero length.
     * !(p)
     * A {@code Duration} represents a directed distance between two points on
     * the time-line and can therefore be positive, zero or negative.
     * This method checks whether the length is zero.
     *
     * @return true if this duration has a total length equal to zero
     */
    public bool isZero() {
        return (seconds | nanos) == 0;
    }

    /**
     * Checks if this duration is negative, excluding zero.
     * !(p)
     * A {@code Duration} represents a directed distance between two points on
     * the time-line and can therefore be positive, zero or negative.
     * This method checks whether the length is less than zero.
     *
     * @return true if this duration has a total length less than zero
     */
    public bool isNegative() {
        return seconds < 0;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the number of seconds _in this duration.
     * !(p)
     * The length of the duration is stored using two fields - seconds and nanoseconds.
     * The nanoseconds part is a value from 0 to 999,999,999 that is an adjustment to
     * the length _in seconds.
     * The total duration is defined by calling this method and {@link #getNano()}.
     * !(p)
     * A {@code Duration} represents a directed distance between two points on the time-line.
     * A negative duration is expressed by the negative sign of the seconds part.
     * A duration of -1 nanosecond is stored as -1 seconds plus 999,999,999 nanoseconds.
     *
     * @return the whole seconds part of the length of the duration, positive or negative
     */
    public long getSeconds() {
        return seconds;
    }

    /**
     * Gets the number of nanoseconds within the second _in this duration.
     * !(p)
     * The length of the duration is stored using two fields - seconds and nanoseconds.
     * The nanoseconds part is a value from 0 to 999,999,999 that is an adjustment to
     * the length _in seconds.
     * The total duration is defined by calling this method and {@link #getSeconds()}.
     * !(p)
     * A {@code Duration} represents a directed distance between two points on the time-line.
     * A negative duration is expressed by the negative sign of the seconds part.
     * A duration of -1 nanosecond is stored as -1 seconds plus 999,999,999 nanoseconds.
     *
     * @return the nanoseconds within the second part of the length of the duration, from 0 to 999,999,999
     */
    public int getNano() {
        return nanos;
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this duration with the specified amount of seconds.
     * !(p)
     * This returns a duration with the specified seconds, retaining the
     * nano-of-second part of this duration.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param seconds  the seconds to represent, may be negative
     * @return a {@code Duration} based on this period with the requested seconds, not null
     */
    public Duration withSeconds(long seconds) {
        return create(seconds, nanos);
    }

    /**
     * Returns a copy of this duration with the specified nano-of-second.
     * !(p)
     * This returns a duration with the specified nano-of-second, retaining the
     * seconds part of this duration.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanoOfSecond  the nano-of-second to represent, from 0 to 999,999,999
     * @return a {@code Duration} based on this period with the requested nano-of-second, not null
     * @throws DateTimeException if the nano-of-second is invalid
     */
    public Duration withNanos(int nanoOfSecond) {
        ChronoField.NANO_OF_SECOND.checkValidIntValue(nanoOfSecond);
        return create(seconds, nanoOfSecond);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this duration with the specified duration added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param duration  the duration to add, positive or negative, not null
     * @return a {@code Duration} based on this duration with the specified duration added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration plus(Duration duration) {
        return plus(duration.getSeconds(), duration.getNano());
     }

    /**
     * Returns a copy of this duration with the specified duration added.
     * !(p)
     * The duration amount is measured _in terms of the specified unit.
     * Only a subset of units are accepted by this method.
     * The unit must either have an {@linkplain TemporalUnit#isDurationEstimated() exact duration} or
     * be {@link ChronoUnit#DAYS} which is treated as 24 hours. Other units throw an exception.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToAdd  the amount to add, measured _in terms of the unit, positive or negative
     * @param unit  the unit that the amount is measured _in, must have an exact duration, not null
     * @return a {@code Duration} based on this duration with the specified duration added, not null
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration plus(long amountToAdd, TemporalUnit unit) {
        assert(unit, "unit");
        if (unit == ChronoUnit.DAYS) {
            return plus(Math.multiplyExact(amountToAdd , LocalTime.SECONDS_PER_DAY), 0);
        }
        if (unit.isDurationEstimated()) {
            throw new UnsupportedTemporalTypeException("Unit must not have an estimated duration");
        }
        if (amountToAdd == 0) {
            return this;
        }
        if (cast(ChronoUnit)(unit) !is null) {
             {
                if ((cast(ChronoUnit) unit).toString == ChronoUnit.NANOS.toString) return plusNanos(amountToAdd);
                if ((cast(ChronoUnit) unit).toString == ChronoUnit.MICROS.toString) return plusSeconds((amountToAdd / (1000_000L * 1000)) * 1000).plusNanos((amountToAdd % (1000_000L * 1000)) * 1000);
                if ((cast(ChronoUnit) unit).toString == ChronoUnit.MILLIS.toString) return plusMillis(amountToAdd);
                if ((cast(ChronoUnit) unit).toString == ChronoUnit.SECONDS.toString ) return plusSeconds(amountToAdd);
            }
            return plusSeconds(Math.multiplyExact(unit.getDuration().seconds , amountToAdd));
        }
        Duration duration = unit.getDuration().multipliedBy(amountToAdd);
        return plusSeconds(duration.getSeconds()).plusNanos(duration.getNano());
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this duration with the specified duration _in standard 24 hour days added.
     * !(p)
     * The number of days is multiplied by 86400 to obtain the number of seconds to add.
     * This is based on the standard definition of a day as 24 hours.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param daysToAdd  the days to add, positive or negative
     * @return a {@code Duration} based on this duration with the specified days added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration plusDays(long daysToAdd) {
        return plus(Math.multiplyExact(daysToAdd  , LocalTime.SECONDS_PER_DAY), 0);
    }

    /**
     * Returns a copy of this duration with the specified duration _in hours added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param hoursToAdd  the hours to add, positive or negative
     * @return a {@code Duration} based on this duration with the specified hours added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration plusHours(long hoursToAdd) {
        return plus(Math.multiplyExact(hoursToAdd , LocalTime.SECONDS_PER_HOUR), 0);
    }

    /**
     * Returns a copy of this duration with the specified duration _in minutes added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param minutesToAdd  the minutes to add, positive or negative
     * @return a {@code Duration} based on this duration with the specified minutes added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration plusMinutes(long minutesToAdd) {
        return plus(Math.multiplyExact(minutesToAdd , LocalTime.SECONDS_PER_MINUTE), 0);
    }

    /**
     * Returns a copy of this duration with the specified duration _in seconds added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param secondsToAdd  the seconds to add, positive or negative
     * @return a {@code Duration} based on this duration with the specified seconds added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration plusSeconds(long secondsToAdd) {
        return plus(secondsToAdd, 0);
    }

    /**
     * Returns a copy of this duration with the specified duration _in milliseconds added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param millisToAdd  the milliseconds to add, positive or negative
     * @return a {@code Duration} based on this duration with the specified milliseconds added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration plusMillis(long millisToAdd) {
        return plus(millisToAdd / 1000, (millisToAdd % 1000) * 1000_000);
    }

    /**
     * Returns a copy of this duration with the specified duration _in nanoseconds added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanosToAdd  the nanoseconds to add, positive or negative
     * @return a {@code Duration} based on this duration with the specified nanoseconds added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration plusNanos(long nanosToAdd) {
        return plus(0, nanosToAdd);
    }

    /**
     * Returns a copy of this duration with the specified duration added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param secondsToAdd  the seconds to add, positive or negative
     * @param nanosToAdd  the nanos to add, positive or negative
     * @return a {@code Duration} based on this duration with the specified seconds added, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    private Duration plus(long secondsToAdd, long nanosToAdd) {
        if ((secondsToAdd | nanosToAdd) == 0) {
            return this;
        }
        long epochSec = Math.addExact(seconds , secondsToAdd);
        epochSec = Math.addExact(epochSec , nanosToAdd / LocalTime.NANOS_PER_SECOND);
        nanosToAdd = nanosToAdd % LocalTime.NANOS_PER_SECOND;
        long nanoAdjustment = nanos + nanosToAdd;  // safe int+NANOS_PER_SECOND
        return ofSeconds(epochSec, nanoAdjustment);
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this duration with the specified duration subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param duration  the duration to subtract, positive or negative, not null
     * @return a {@code Duration} based on this duration with the specified duration subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration minus(Duration duration) {
        long secsToSubtract = duration.getSeconds();
        int nanosToSubtract = duration.getNano();
        if (secsToSubtract == Long.MIN_VALUE) {
            return plus(Long.MAX_VALUE, -nanosToSubtract).plus(1, 0);
        }
        return plus(-secsToSubtract, -nanosToSubtract);
     }

    /**
     * Returns a copy of this duration with the specified duration subtracted.
     * !(p)
     * The duration amount is measured _in terms of the specified unit.
     * Only a subset of units are accepted by this method.
     * The unit must either have an {@linkplain TemporalUnit#isDurationEstimated() exact duration} or
     * be {@link ChronoUnit#DAYS} which is treated as 24 hours. Other units throw an exception.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param amountToSubtract  the amount to subtract, measured _in terms of the unit, positive or negative
     * @param unit  the unit that the amount is measured _in, must have an exact duration, not null
     * @return a {@code Duration} based on this duration with the specified duration subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration minus(long amountToSubtract, TemporalUnit unit) {
        return (amountToSubtract == Long.MIN_VALUE ? plus(Long.MAX_VALUE, unit).plus(1, unit) : plus(-amountToSubtract, unit));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this duration with the specified duration _in standard 24 hour days subtracted.
     * !(p)
     * The number of days is multiplied by 86400 to obtain the number of seconds to subtract.
     * This is based on the standard definition of a day as 24 hours.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param daysToSubtract  the days to subtract, positive or negative
     * @return a {@code Duration} based on this duration with the specified days subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration minusDays(long daysToSubtract) {
        return (daysToSubtract == Long.MIN_VALUE ? plusDays(Long.MAX_VALUE).plusDays(1) : plusDays(-daysToSubtract));
    }

    /**
     * Returns a copy of this duration with the specified duration _in hours subtracted.
     * !(p)
     * The number of hours is multiplied by 3600 to obtain the number of seconds to subtract.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param hoursToSubtract  the hours to subtract, positive or negative
     * @return a {@code Duration} based on this duration with the specified hours subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration minusHours(long hoursToSubtract) {
        return (hoursToSubtract == Long.MIN_VALUE ? plusHours(Long.MAX_VALUE).plusHours(1) : plusHours(-hoursToSubtract));
    }

    /**
     * Returns a copy of this duration with the specified duration _in minutes subtracted.
     * !(p)
     * The number of hours is multiplied by 60 to obtain the number of seconds to subtract.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param minutesToSubtract  the minutes to subtract, positive or negative
     * @return a {@code Duration} based on this duration with the specified minutes subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration minusMinutes(long minutesToSubtract) {
        return (minutesToSubtract == Long.MIN_VALUE ? plusMinutes(Long.MAX_VALUE).plusMinutes(1) : plusMinutes(-minutesToSubtract));
    }

    /**
     * Returns a copy of this duration with the specified duration _in seconds subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param secondsToSubtract  the seconds to subtract, positive or negative
     * @return a {@code Duration} based on this duration with the specified seconds subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration minusSeconds(long secondsToSubtract) {
        return (secondsToSubtract == Long.MIN_VALUE ? plusSeconds(Long.MAX_VALUE).plusSeconds(1) : plusSeconds(-secondsToSubtract));
    }

    /**
     * Returns a copy of this duration with the specified duration _in milliseconds subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param millisToSubtract  the milliseconds to subtract, positive or negative
     * @return a {@code Duration} based on this duration with the specified milliseconds subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration minusMillis(long millisToSubtract) {
        return (millisToSubtract == Long.MIN_VALUE ? plusMillis(Long.MAX_VALUE).plusMillis(1) : plusMillis(-millisToSubtract));
    }

    /**
     * Returns a copy of this duration with the specified duration _in nanoseconds subtracted.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param nanosToSubtract  the nanoseconds to subtract, positive or negative
     * @return a {@code Duration} based on this duration with the specified nanoseconds subtracted, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration minusNanos(long nanosToSubtract) {
        return (nanosToSubtract == Long.MIN_VALUE ? plusNanos(Long.MAX_VALUE).plusNanos(1) : plusNanos(-nanosToSubtract));
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this duration multiplied by the scalar.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param multiplicand  the value to multiply the duration by, positive or negative
     * @return a {@code Duration} based on this duration multiplied by the specified scalar, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration multipliedBy(long multiplicand) {
        if (multiplicand == 0) {
            return ZERO;
        }
        if (multiplicand == 1) {
            return this;
        }
        return null /* create(toBigDecimalSeconds().multiply(BigDecimal.valueOf(multiplicand))) */;
     }

    /**
     * Returns a copy of this duration divided by the specified value.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param divisor  the value to divide the duration by, positive or negative, not zero
     * @return a {@code Duration} based on this duration divided by the specified divisor, not null
     * @throws ArithmeticException if the divisor is zero or if numeric overflow occurs
     */
     ///@gxc
    // public Duration dividedBy(long divisor) {
    //     if (divisor == 0) {
    //         throw new ArithmeticException("Cannot divide by zero");
    //     }
    //     if (divisor == 1) {
    //         return this;
    //     }
    //     return create(toBigDecimalSeconds().divide(BigDecimal.valueOf(divisor), RoundingMode.DOWN.oldMode()));
    //  }

    /**
     * Returns number of whole times a specified Duration occurs within this Duration.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param divisor the value to divide the duration by, positive or negative, not null
     * @return number of whole times, rounded toward zero, a specified
     *         {@code Duration} occurs within this Duration, may be negative
     * @throws ArithmeticException if the divisor is zero, or if numeric overflow occurs
     * @since 9
     */
     ///@gxc
    // public long dividedBy(Duration divisor) {
    //     assert(divisor, "divisor");
    //     BigDecimal dividendBigD = toBigDecimalSeconds();
    //     BigDecimal divisorBigD = divisor.toBigDecimalSeconds();
    //     return dividendBigD.divideToIntegralValue(divisorBigD).longValueExact();
    // }

    /**
     * Converts this duration to the total length _in seconds and
     * fractional nanoseconds expressed as a {@code BigDecimal}.
     *
     * @return the total length of the duration _in seconds, with a scale of 9, not null
     */
     ///@gxc
    // private BigDecimal toBigDecimalSeconds() {
    //     return BigDecimal.valueOf(seconds).add(BigDecimal.valueOf(nanos, 9));
    // }

    /**
     * Creates an instance of {@code Duration} from a number of seconds.
     *
     * @param seconds  the number of seconds, up to scale 9, positive or negative
     * @return a {@code Duration}, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    private static Duration create(BigDecimal seconds) {
        BigInteger nanos = seconds.movePointRight(9).toBigIntegerExact();
        BigInteger[] divRem = nanos.divideAndRemainder(BI_NANOS_PER_SECOND);
        if (divRem[0].bitLength() > 63) {
            throw new ArithmeticException("Exceeds capacity of Duration: " ~ nanos.toString);
        }
        return ofSeconds(divRem[0].longValue(), divRem[1].intValue());
    }

    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this duration with the length negated.
     * !(p)
     * This method swaps the sign of the total length of this duration.
     * For example, {@code PT1.3S} will be returned as {@code PT-1.3S}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return a {@code Duration} based on this duration with the amount negated, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration negated() {
        return multipliedBy(-1);
    }

    /**
     * Returns a copy of this duration with a positive length.
     * !(p)
     * This method returns a positive duration by effectively removing the sign from any negative total length.
     * For example, {@code PT-1.3S} will be returned as {@code PT1.3S}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return a {@code Duration} based on this duration with an absolute length, not null
     * @throws ArithmeticException if numeric overflow occurs
     */
    public Duration abs() {
        return isNegative() ? negated() : this;
    }

    //-------------------------------------------------------------------------
    /**
     * Adds this duration to the specified temporal object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with this duration added.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#plus(TemporalAmount)}.
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   dateTime = thisDuration.addTo(dateTime);
     *   dateTime = dateTime.plus(thisDuration);
     * </pre>
     * !(p)
     * The calculation will add the seconds, then nanos.
     * Only non-zero amounts will be added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the temporal object to adjust, not null
     * @return an object of the same type with the adjustment made, not null
     * @throws DateTimeException if unable to add
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Temporal addTo(Temporal temporal) {
        if (seconds != 0) {
            temporal = temporal.plus(seconds, ChronoUnit.SECONDS);
        }
        if (nanos != 0) {
            temporal = temporal.plus(nanos, ChronoUnit.NANOS);
        }
        return temporal;
    }

    /**
     * Subtracts this duration from the specified temporal object.
     * !(p)
     * This returns a temporal object of the same observable type as the input
     * with this duration subtracted.
     * !(p)
     * In most cases, it is clearer to reverse the calling pattern by using
     * {@link Temporal#minus(TemporalAmount)}.
     * !(pre)
     *   // these two lines are equivalent, but the second approach is recommended
     *   dateTime = thisDuration.subtractFrom(dateTime);
     *   dateTime = dateTime.minus(thisDuration);
     * </pre>
     * !(p)
     * The calculation will subtract the seconds, then nanos.
     * Only non-zero amounts will be added.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param temporal  the temporal object to adjust, not null
     * @return an object of the same type with the adjustment made, not null
     * @throws DateTimeException if unable to subtract
     * @throws ArithmeticException if numeric overflow occurs
     */
    override
    public Temporal subtractFrom(Temporal temporal) {
        if (seconds != 0) {
            temporal = temporal.minus(seconds, ChronoUnit.SECONDS);
        }
        if (nanos != 0) {
            temporal = temporal.minus(nanos, ChronoUnit.NANOS);
        }
        return temporal;
    }

    //-----------------------------------------------------------------------
    /**
     * Gets the number of days _in this duration.
     * !(p)
     * This returns the total number of days _in the duration by dividing the
     * number of seconds by 86400.
     * This is based on the standard definition of a day as 24 hours.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the number of days _in the duration, may be negative
     */
    public long toDays() {
        return seconds / LocalTime.SECONDS_PER_DAY;
    }

    /**
     * Gets the number of hours _in this duration.
     * !(p)
     * This returns the total number of hours _in the duration by dividing the
     * number of seconds by 3600.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the number of hours _in the duration, may be negative
     */
    public long toHours() {
        return seconds / LocalTime.SECONDS_PER_HOUR;
    }

    /**
     * Gets the number of minutes _in this duration.
     * !(p)
     * This returns the total number of minutes _in the duration by dividing the
     * number of seconds by 60.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the number of minutes _in the duration, may be negative
     */
    public long toMinutes() {
        return seconds / LocalTime.SECONDS_PER_MINUTE;
    }

    /**
     * Gets the number of seconds _in this duration.
     * !(p)
     * This returns the total number of whole seconds _in the duration.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the whole seconds part of the length of the duration, positive or negative
     * @since 9
     */
    public long toSeconds() {
        return seconds;
    }

    /**
     * Converts this duration to the total length _in milliseconds.
     * !(p)
     * If this duration is too large to fit _in a {@code long} milliseconds, then an
     * exception is thrown.
     * !(p)
     * If this duration has greater than millisecond precision, then the conversion
     * will drop any excess precision information as though the amount _in nanoseconds
     * was subject to integer division by one million.
     *
     * @return the total length of the duration _in milliseconds
     * @throws ArithmeticException if numeric overflow occurs
     */
    public long toMillis() {
        long tempSeconds = seconds;
        long tempNanos = nanos;
        if (tempSeconds < 0) {
            // change the seconds and nano value to
            // handle Long.MIN_VALUE case
            tempSeconds = tempSeconds + 1;
            tempNanos = tempNanos - LocalTime.NANOS_PER_SECOND;
        }
        long millis = Math.multiplyExact(tempSeconds , 1000);
        millis = Math.addExact(millis, tempNanos / LocalTime.NANOS_PER_MILLI);
        return millis;
    }

    /**
     * Converts this duration to the total length _in nanoseconds expressed as a {@code long}.
     * !(p)
     * If this duration is too large to fit _in a {@code long} nanoseconds, then an
     * exception is thrown.
     *
     * @return the total length of the duration _in nanoseconds
     * @throws ArithmeticException if numeric overflow occurs
     */
    public long toNanos() {
        long tempSeconds = seconds;
        long tempNanos = nanos;
        if (tempSeconds < 0) {
            // change the seconds and nano value to
            // handle Long.MIN_VALUE case
            tempSeconds = tempSeconds + 1;
            tempNanos = tempNanos - LocalTime.NANOS_PER_SECOND;
        }
        long totalNanos = Math.multiplyExact(tempSeconds , LocalTime.NANOS_PER_SECOND);
        totalNanos = Math.addExact(totalNanos , tempNanos);
        return totalNanos;
    }

    /**
     * Extracts the number of days _in the duration.
     * !(p)
     * This returns the total number of days _in the duration by dividing the
     * number of seconds by 86400.
     * This is based on the standard definition of a day as 24 hours.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the number of days _in the duration, may be negative
     * @since 9
     */
    public long toDaysPart(){
        return seconds / LocalTime.SECONDS_PER_DAY;
    }

    /**
     * Extracts the number of hours part _in the duration.
     * !(p)
     * This returns the number of remaining hours when dividing {@link #toHours}
     * by hours _in a day.
     * This is based on the standard definition of a day as 24 hours.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the number of hours part _in the duration, may be negative
     * @since 9
     */
    public int toHoursPart(){
        return cast(int) (toHours() % 24);
    }

    /**
     * Extracts the number of minutes part _in the duration.
     * !(p)
     * This returns the number of remaining minutes when dividing {@link #toMinutes}
     * by minutes _in an hour.
     * This is based on the standard definition of an hour as 60 minutes.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the number of minutes parts _in the duration, may be negative
     * @since 9
     */
    public int toMinutesPart(){
        return cast(int) (toMinutes() % LocalTime.MINUTES_PER_HOUR);
    }

    /**
     * Extracts the number of seconds part _in the duration.
     * !(p)
     * This returns the remaining seconds when dividing {@link #toSeconds}
     * by seconds _in a minute.
     * This is based on the standard definition of a minute as 60 seconds.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the number of seconds parts _in the duration, may be negative
     * @since 9
     */
    public int toSecondsPart(){
        return cast(int) (seconds % LocalTime.SECONDS_PER_MINUTE);
    }

    /**
     * Extracts the number of milliseconds part of the duration.
     * !(p)
     * This returns the milliseconds part by dividing the number of nanoseconds by 1,000,000.
     * The length of the duration is stored using two fields - seconds and nanoseconds.
     * The nanoseconds part is a value from 0 to 999,999,999 that is an adjustment to
     * the length _in seconds.
     * The total duration is defined by calling {@link #getNano()} and {@link #getSeconds()}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the number of milliseconds part of the duration.
     * @since 9
     */
    public int toMillisPart(){
        return nanos / 1000_000;
    }

    /**
     * Get the nanoseconds part within seconds of the duration.
     * !(p)
     * The length of the duration is stored using two fields - seconds and nanoseconds.
     * The nanoseconds part is a value from 0 to 999,999,999 that is an adjustment to
     * the length _in seconds.
     * The total duration is defined by calling {@link #getNano()} and {@link #getSeconds()}.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @return the nanoseconds within the second part of the length of the duration, from 0 to 999,999,999
     * @since 9
     */
    public int toNanosPart(){
        return nanos;
    }


    //-----------------------------------------------------------------------
    /**
     * Returns a copy of this {@code Duration} truncated to the specified unit.
     * !(p)
     * Truncating the duration returns a copy of the original with conceptual fields
     * smaller than the specified unit set to zero.
     * For example, truncating with the {@link ChronoUnit#MINUTES MINUTES} unit will
     * round down towards zero to the nearest minute, setting the seconds and
     * nanoseconds to zero.
     * !(p)
     * The unit must have a {@linkplain TemporalUnit#getDuration() duration}
     * that divides into the length of a standard day without remainder.
     * This includes all
     * {@linkplain ChronoUnit#isTimeBased() time-based units on {@code ChronoUnit}}
     * and {@link ChronoUnit#DAYS DAYS}. Other ChronoUnits throw an exception.
     * !(p)
     * This instance is immutable and unaffected by this method call.
     *
     * @param unit the unit to truncate to, not null
     * @return a {@code Duration} based on this duration with the time truncated, not null
     * @throws DateTimeException if the unit is invalid for truncation
     * @throws UnsupportedTemporalTypeException if the unit is not supported
     * @since 9
     */
    public Duration truncatedTo(TemporalUnit unit) {
        assert(unit, "unit");
        if (unit == ChronoUnit.SECONDS && (seconds >= 0 || nanos == 0)) {
            return new Duration(seconds, 0);
        } else if (unit == ChronoUnit.NANOS) {
            return this;
        }
        Duration unitDur = unit.getDuration();
        if (unitDur.getSeconds() > LocalTime.SECONDS_PER_DAY) {
            throw new UnsupportedTemporalTypeException("Unit is too large to be used for truncation");
        }
        long dur = unitDur.toNanos();
        if ((LocalTime.NANOS_PER_DAY % dur) != 0) {
            throw new UnsupportedTemporalTypeException("Unit must divide into a standard day without remainder");
        }
        long nod = (seconds % LocalTime.SECONDS_PER_DAY) * LocalTime.NANOS_PER_SECOND + nanos;
        long result = (nod / dur) * dur;
        return plusNanos(result - nod);
    }

    //-----------------------------------------------------------------------
    /**
     * Compares this duration to the specified {@code Duration}.
     * !(p)
     * The comparison is based on the total length of the durations.
     * It is "consistent with equals", as defined by {@link Comparable}.
     *
     * @param otherDuration the other duration to compare to, not null
     * @return the comparator value, negative if less, positive if greater
     */
    // override
    public int compareTo(Duration otherDuration) {
        import hunt.util.Comparator;

        int cmp = compare(seconds, otherDuration.seconds);
        if (cmp != 0) {
            return cmp;
        }
        return nanos - otherDuration.nanos;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this duration is equal to the specified {@code Duration}.
     * !(p)
     * The comparison is based on the total length of the durations.
     *
     * @param otherDuration the other duration, null returns false
     * @return true if the other duration is equal to this one
     */
    override
    public bool opEquals(Object otherDuration) {
        if (this == otherDuration) {
            return true;
        }
        if (cast(Duration)(otherDuration) !is null) {
            Duration other = cast(Duration) otherDuration;
            return this.seconds == other.seconds &&
                   this.nanos == other.nanos;
        }
        return false;
    }

    /**
     * A hash code for this duration.
     *
     * @return a suitable hash code
     */
    override
    public size_t toHash() @trusted nothrow {
        return (cast(int) (seconds ^ (seconds >>> 32))) + (51 * nanos);
    }

    //-----------------------------------------------------------------------
    /**
     * A string representation of this duration using ISO-8601 seconds
     * based representation, such as {@code PT8H6M12.345S}.
     * !(p)
     * The format of the returned string will be {@code PTnHnMnS}, where n is
     * the relevant hours, minutes or seconds part of the duration.
     * Any fractional seconds are placed after a decimal point _in the seconds section.
     * If a section has a zero value, it is omitted.
     * The hours, minutes and seconds will all have the same sign.
     * !(p)
     * Examples:
     * !(pre)
     *    "20.345 seconds"                 -- "PT20.345S
     *    "15 minutes" (15 * 60 seconds)   -- "PT15M"
     *    "10 hours" (10 * 3600 seconds)   -- "PT10H"
     *    "2 days" (2 * 86400 seconds)     -- "PT48H"
     * </pre>
     * Note that multiples of 24 hours are not output as days to avoid confusion
     * with {@code Period}.
     *
     * @return an ISO-8601 representation of this duration, not null
     */
    override
    public string toString() {
        if (this == ZERO) {
            return "PT0S";
        }
        long effectiveTotalSecs = seconds;
        if (seconds < 0 && nanos > 0) {
            effectiveTotalSecs++;
        }
        long hours = effectiveTotalSecs / LocalTime.SECONDS_PER_HOUR;
        int minutes = cast(int) ((effectiveTotalSecs % LocalTime.SECONDS_PER_HOUR) / LocalTime.SECONDS_PER_MINUTE);
        int secs = cast(int) (effectiveTotalSecs % LocalTime.SECONDS_PER_MINUTE);
        StringBuilder buf = new StringBuilder(24);
        buf.append("PT");
        if (hours != 0) {
            buf.append(hours).append('H');
        }
        if (minutes != 0) {
            buf.append(minutes).append('M');
        }
        if (secs == 0 && nanos == 0 && buf.length() > 2) {
            return buf.toString();
        }
        if (seconds < 0 && nanos > 0) {
            if (secs == 0) {
                buf.append("-0");
            } else {
                buf.append(secs);
            }
        } else {
            buf.append(secs);
        }
        if (nanos > 0) {
            int pos = buf.length();
            if (seconds < 0) {
                buf.append(2 * LocalTime.NANOS_PER_SECOND - nanos);
            } else {
                buf.append(nanos + LocalTime.NANOS_PER_SECOND);
            }
            while (buf.charAt(buf.length() - 1) == '0') {
                buf.setLength(buf.length() - 1);
            }
            buf.setCharAt(pos, '.');
        }
        buf.append('S');
        return buf.toString();
    }

    //-----------------------------------------------------------------------
    /**
     * Writes the object using a
     * <a href="{@docRoot}/serialized-form.html#hunt.time.Ser">dedicated serialized form</a>.
     * @serialData
     * !(pre)
     *  _out.writeByte(1);  // identifies a Duration
     *  _out.writeLong(seconds);
     *  _out.writeInt(nanos);
     * </pre>
     *
     * @return the instance of {@code Ser}, not null
     */
    private Object writeReplace() {
        return new Ser(Ser.DURATION_TYPE, this);
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

    static Duration readExternal(DataInput _in) /*throws IOException*/ {
        long seconds = _in.readLong();
        int nanos = _in.readInt();
        return Duration.ofSeconds(seconds, nanos);
    }

    override int opCmp(Duration o)
    {
        auto res = compare(this.seconds,o.seconds);
        if(res == 0)
            res = compare(this.nanos,o.nanos);
        return res;
    }
}
