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

module hunt.time.temporal.ChronoUnit;

import hunt.time.Duration;
import hunt.time.temporal.TemporalUnit;
import hunt.time.temporal.Temporal;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.ValueRange;

import hunt.Exceptions;
import hunt.Enum;
import hunt.Long;
import hunt.time.util.Common;
import hunt.util.Comparator;

import std.concurrency : initOnce;

/**
 * A standard set of date periods units.
 * !(p)
 * This set of units provide unit-based access to manipulate a date, time or date-time.
 * The standard set of units can be extended by implementing {@link TemporalUnit}.
 * !(p)
 * These units are intended to be applicable _in multiple calendar systems.
 * For example, most non-ISO calendar systems define units of years, months and days,
 * just with slightly different rules.
 * The documentation of each unit explains how it operates.
 *
 * @implSpec
 * This is a final, immutable and thread-safe enum.
 *
 * @since 1.8
 */
class ChronoUnit : TemporalUnit
{

    /**
     * Unit that represents the concept of a nanosecond, the smallest supported unit of time.
     * For the ISO calendar system, it is equal to the 1,000,000,000th part of the second unit.
     */
    static ChronoUnit NANOS() {
        __gshared ChronoUnit _NANOS;
        return initOnce!(_NANOS)(new ChronoUnit("Nanos", 0, Duration.ofNanos(1)));
    }

    /**
     * Unit that represents the concept of a microsecond.
     * For the ISO calendar system, it is equal to the 1,000,000th part of the second unit.
     */
    static ChronoUnit MICROS() {
        __gshared ChronoUnit _MICROS;
        return initOnce!(_MICROS)(new ChronoUnit("Micros", 1, Duration.ofNanos(1000)));
    }

    /**
     * Unit that represents the concept of a millisecond.
     * For the ISO calendar system, it is equal to the 1000th part of the second unit.
     */
    static ChronoUnit MILLIS() {
        __gshared ChronoUnit _MILLIS;
        return initOnce!(_MILLIS)(new ChronoUnit("Millis", 2, Duration.ofNanos(1000_000)));
    }

    /**
     * Unit that represents the concept of a second.
     * For the ISO calendar system, it is equal to the second _in the SI system
     * of units, except around a leap-second.
     */
    static ChronoUnit SECONDS() {
        __gshared ChronoUnit _SECONDS;
        return initOnce!(_SECONDS)(new ChronoUnit("Seconds", 3, Duration.ofSeconds(1)));
    }

    /**
     * Unit that represents the concept of a minute.
     * For the ISO calendar system, it is equal to 60 seconds.
     */
    static ChronoUnit MINUTES() {
        __gshared ChronoUnit _MINUTES;
        return initOnce!(_MINUTES)(new ChronoUnit("Minutes", 4, Duration.ofSeconds(60)));
    }

    /**
     * Unit that represents the concept of an hour.
     * For the ISO calendar system, it is equal to 60 minutes.
     */
    static ChronoUnit HOURS() {
        __gshared ChronoUnit _HOURS;
        return initOnce!(_HOURS)(new ChronoUnit("Hours", 5, Duration.ofSeconds(3600)));
    }

    /**
     * Unit that represents the concept of half a day, as used _in AM/PM.
     * For the ISO calendar system, it is equal to 12 hours.
     */
    static ChronoUnit HALF_DAYS() {
        __gshared ChronoUnit _HALF_DAYS;
        return initOnce!(_HALF_DAYS)(new ChronoUnit("HalfDays", 6, Duration.ofSeconds(43200)));
    }

    /**
     * Unit that represents the concept of a day.
     * For the ISO calendar system, it is the standard day from midnight to midnight.
     * The estimated duration of a day is {@code 24 Hours}.
     * !(p)
     * When used with other calendar systems it must correspond to the day defined by
     * the rising and setting of the Sun on Earth. It is not required that days begin
     * at midnight - when converting between calendar systems, the date should be
     * equivalent at midday.
     */
    static ChronoUnit DAYS() {
        __gshared ChronoUnit _DAYS;
        return initOnce!(_DAYS)(new ChronoUnit("Days", 7, Duration.ofSeconds(86400)));
    }

    /**
     * Unit that represents the concept of a week.
     * For the ISO calendar system, it is equal to 7 days.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days.
     */
    static ChronoUnit WEEKS() {
        __gshared ChronoUnit _WEEKS;
        return initOnce!(_WEEKS)(new ChronoUnit("Weeks", 8, Duration.ofSeconds(7 * 86400L)));
    }

    /**
     * Unit that represents the concept of a month.
     * For the ISO calendar system, the length of the month varies by month-of-year.
     * The estimated duration of a month is one twelfth of {@code 365.2425 Days}.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days.
     */
    static ChronoUnit MONTHS() {
        __gshared ChronoUnit _MONTHS;
        return initOnce!(_MONTHS)(new ChronoUnit("Months", 9, Duration.ofSeconds(31556952L / 12)));
    }

    /**
     * Unit that represents the concept of a year.
     * For the ISO calendar system, it is equal to 12 months.
     * The estimated duration of a year is {@code 365.2425 Days}.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days
     * or months roughly equal to a year defined by the passage of the Earth around the Sun.
     */
    static ChronoUnit YEARS() {
        __gshared ChronoUnit _YEARS;
        return initOnce!(_YEARS)(new ChronoUnit("Years", 10, Duration.ofSeconds(31556952L)));
    }

    /**
     * Unit that represents the concept of a decade.
     * For the ISO calendar system, it is equal to 10 years.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days
     * and is normally an integral number of years.
     */
    static ChronoUnit DECADES() {
        __gshared ChronoUnit _DECADES;
        return initOnce!(_DECADES)(new ChronoUnit("Decades", 11, Duration.ofSeconds(31556952L * 10L)));
    }

    /**
     * Unit that represents the concept of a century.
     * For the ISO calendar system, it is equal to 100 years.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days
     * and is normally an integral number of years.
     */
    static ChronoUnit CENTURIES() {
        __gshared ChronoUnit _CENTURIES;
        return initOnce!(_CENTURIES)(new ChronoUnit("Centuries", 12, Duration.ofSeconds(31556952L * 100L)));
    }

    /**
     * Unit that represents the concept of a millennium.
     * For the ISO calendar system, it is equal to 1000 years.
     * !(p)
     * When used with other calendar systems it must correspond to an integral number of days
     * and is normally an integral number of years.
     */
    static ChronoUnit MILLENNIA() {
        __gshared ChronoUnit _MILLENNIA;
        return initOnce!(_MILLENNIA)(new ChronoUnit("Millennia", 13, Duration.ofSeconds(31556952L * 1000L)));
    }

    /**
     * Unit that represents the concept of an era.
     * The ISO calendar system doesn't have eras thus it is impossible to add
     * an era to a date or date-time.
     * The estimated duration of the era is artificially defined as {@code 1,000,000,000 Years}.
     * !(p)
     * When used with other calendar systems there are no restrictions on the unit.
     */
    static ChronoUnit ERAS() {
        __gshared ChronoUnit _ERAS;
        return initOnce!(_ERAS)(new ChronoUnit("Eras", 14, Duration.ofSeconds(31556952L * 1000_000_000L)));
    }

    /**
     * Artificial unit that represents the concept of forever.
     * This is primarily used with {@link TemporalField} to represent unbounded fields
     * such as the year or era.
     * The estimated duration of this unit is artificially defined as the largest duration
     * supported by {@link Duration}.
     */
    static ChronoUnit FOREVER() {
        __gshared ChronoUnit _FOREVER;
        return initOnce!(_FOREVER)(new ChronoUnit("Forever", 15, Duration.ofSeconds(Long.MAX_VALUE, 999_999_999)));
    }


    private Duration duration;

    protected this(string name, int ordinal,  Duration estimatedDuration)
    {
        super(name, ordinal);
        this.duration = estimatedDuration;
    }


    //-----------------------------------------------------------------------
    /**
     * Gets the estimated duration of this unit _in the ISO calendar system.
     * !(p)
     * All of the units _in this class have an estimated duration.
     * Days vary due to daylight saving time, while months have different lengths.
     *
     * @return the estimated duration of this unit, not null
     */
    override Duration getDuration()
    {
        return duration;
    }

    /**
     * Checks if the duration of the unit is an estimate.
     * !(p)
     * All time units _in this class are considered to be accurate, while all date
     * units _in this class are considered to be estimated.
     * !(p)
     * This definition ignores leap seconds, but considers that Days vary due to
     * daylight saving time and months have different lengths.
     *
     * @return true if the duration is estimated, false if accurate
     */
    override bool isDurationEstimated()
    {
        return this.opCmp(DAYS) >= 0;
    }

    //-----------------------------------------------------------------------
    /**
     * Checks if this unit is a date unit.
     * !(p)
     * All units from days to eras inclusive are date-based.
     * Time-based units and {@code FOREVER} return false.
     *
     * @return true if a date unit, false if a time unit
     */
    override bool isDateBased()
    {
        return this.opCmp(DAYS) >= 0 && this != FOREVER;
    }

    /**
     * Checks if this unit is a time unit.
     * !(p)
     * All units from nanos to half-days inclusive are time-based.
     * Date-based units and {@code FOREVER} return false.
     *
     * @return true if a time unit, false if a date unit
     */
    override bool isTimeBased()
    {
        return this.opCmp(DAYS) < 0;
    }

    //-----------------------------------------------------------------------
    override bool isSupportedBy(Temporal temporal)
    {
        return temporal.isSupported(this);
    }

    /*@SuppressWarnings("unchecked")*/
    override Temporal addTo(Temporal temporal, long amount) /* if(is(R : Temporal)) */
    {
        return cast(Temporal) temporal.plus(amount, this);
    }

    //-----------------------------------------------------------------------
    override long between(Temporal temporal1Inclusive, Temporal temporal2Exclusive)
    {
        return temporal1Inclusive.until(temporal2Exclusive, this);
    }

    //-----------------------------------------------------------------------
    // override string toString()
    // {
    //     return name;
    // }

    // bool opEquals(ref const ChronoUnit h) nothrow
    // {
    //     return name == h.name;
    // }

    // override bool opEquals(Object obj)
    // {
    //     if (this is obj)
    //     {
    //         return true;
    //     }
    //     if (cast(ChronoUnit)(obj) !is null)
    //     {
    //         ChronoUnit other = cast(ChronoUnit) obj;
    //         return name == other.name;
    //     }
    //     return false;
    // }

    // int compareTo(ChronoUnit obj)
    // {
    //     return compare(this.name, obj.name);
    // }
}
