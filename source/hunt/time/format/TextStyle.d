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

module hunt.time.format.TextStyle;

import hunt.time.util.Calendar;
import hunt.Enum;
import std.concurrency;

/**
 * Enumeration of the style of text formatting and parsing.
 * !(p)
 * Text styles define three sizes for the formatted text - 'full', 'short' and 'narrow'.
 * Each of these three sizes is available _in both 'standard' and 'stand-alone' variations.
 * !(p)
 * The difference between the three sizes is obvious _in most languages.
 * For example, _in English the 'full' month is 'January', the 'short' month is 'Jan'
 * and the 'narrow' month is 'J'. Note that the narrow size is often not unique.
 * For example, 'January', 'June' and 'July' all have the 'narrow' text 'J'.
 * !(p)
 * The difference between the 'standard' and 'stand-alone' forms is trickier to describe
 * as there is no difference _in English. However, _in other languages there is a difference
 * _in the word used when the text is used alone, as opposed to _in a complete date.
 * For example, the word used for a month when used alone _in a date picker is different
 * to the word used for month _in association with a day and year _in a date.
 *
 * @implSpec
 * This is immutable and thread-safe enum.
 *
 * @since 1.8
 */
class TextStyle : AbstractEnum!TextStyle {
    // ordered from large to small
    // ordered so that bit 0 of the ordinal indicates stand-alone.

    /**
     * Full text, typically the full description.
     * For example, day-of-week Monday might output "Monday".
     */
    static TextStyle FULL() {
        __gshared TextStyle t;
        return initOnce!t(new TextStyle(Calendar.LONG_FORMAT, 0, "FULL", 0));
    }
    /**
     * Full text for stand-alone use, typically the full description.
     * For example, day-of-week Monday might output "Monday".
     */
    static TextStyle FULL_STANDALONE() {
        __gshared TextStyle t;
        return initOnce!t(new TextStyle(Calendar.LONG_STANDALONE, 0, "FULL_STANDALONE", 1));
    }
    /**
     * Short text, typically an abbreviation.
     * For example, day-of-week Monday might output "Mon".
     */
    static TextStyle SHORT() {
        __gshared TextStyle t;
        return initOnce!t(new TextStyle(Calendar.SHORT_FORMAT, 1, "SHORT", 2));
    }
    /**
     * Short text for stand-alone use, typically an abbreviation.
     * For example, day-of-week Monday might output "Mon".
     */
    static TextStyle SHORT_STANDALONE() {
        __gshared TextStyle t;
        return initOnce!t(new TextStyle(Calendar.SHORT_STANDALONE, 1, "SHORT_STANDALONE", 3));
    }
    /**
     * Narrow text, typically a single letter.
     * For example, day-of-week Monday might output "M".
     */
    static TextStyle NARROW() {
        __gshared TextStyle t;
        return initOnce!t(new TextStyle(Calendar.NARROW_FORMAT, 1, "NARROW", 4));
    }
    /**
     * Narrow text for stand-alone use, typically a single letter.
     * For example, day-of-week Monday might output "M".
     */
    static TextStyle NARROW_STANDALONE() {
        __gshared TextStyle t;
        return initOnce!t(new TextStyle(Calendar.NARROW_STANDALONE, 1, "NARROW_STANDALONE", 5));
    }

    private int _calendarStyle;
    private int _zoneNameStyleIndex;

    protected this(int calendarStyle, int zoneNameStyleIndex, string name, int ordinal) {
        super(name, ordinal);
        this._calendarStyle = calendarStyle;
        this._zoneNameStyleIndex = zoneNameStyleIndex;
    }

    static TextStyle[] values() {
        __gshared TextStyle[] d;
        return initOnce!d({
            TextStyle[] arr;
            arr ~= FULL();
            arr ~= FULL_STANDALONE();
            arr ~= SHORT();
            arr ~= SHORT_STANDALONE();
            arr ~= NARROW();
            arr ~= NARROW_STANDALONE();
            return arr;
        }());
    }
    /**
     * Returns true if the Style is a stand-alone style.
     * @return true if the style is a stand-alone style.
     */
    bool isStandalone() {
        return (ordinal() & 1) == 1;
    }

    /**
     * Returns the stand-alone style with the same size.
     * @return the stand-alone style with the same size
     */
    TextStyle asStandalone() {
        return values()[ordinal() | 1];
    }

    /**
     * Returns the normal style with the same size.
     *
     * @return the normal style with the same size
     */
    TextStyle asNormal() {
        return values()[ordinal() & ~1];
    }

    /**
     * Returns the {@code Calendar} style corresponding to this {@code TextStyle}.
     *
     * @return the corresponding {@code Calendar} style
     */
    int toCalendarStyle() {
        return _calendarStyle;
    }

    /**
     * Returns the relative index value to an element of the {@link
     * java.text.DateFormatSymbols#getZoneStrings() DateFormatSymbols.getZoneStrings()}
     * value, 0 for long names and 1 for short names (abbreviations). Note that these values
     * do !(em)not</em> correspond to the {@link java.util.TimeZone#LONG} and {@link
     * java.util.TimeZone#SHORT} values.
     *
     * @return the relative index value to time zone names array
     */
    int zoneNameStyleIndex() {
        return _zoneNameStyleIndex;
    }
}
