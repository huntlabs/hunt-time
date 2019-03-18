module hunt.time.format.ReducedPrinterParser;

import hunt.time.Exceptions;
import hunt.time.LocalDate;

import hunt.time.chrono.Chronology;
import hunt.time.chrono.ChronoLocalDate;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.NumberPrinterParser;
import hunt.time.format.SignStyle;
import hunt.time.temporal.TemporalField;
import hunt.time.util.Common;
import hunt.text.StringBuilder;

import hunt.Exceptions;
import hunt.Integer;
import hunt.math.Helper;
import hunt.Functions;

import std.conv;

//-----------------------------------------------------------------------
/**
 * Prints and parses a reduced numeric date-time field.
 */
final class ReducedPrinterParser : NumberPrinterParser
{
    /**
     * The base date for reduced value parsing.
     */
    // __gshared LocalDate BASE_DATE;

    private int baseValue;
    private ChronoLocalDate baseDate;

    // shared static this()
    // {
    //     BASE_DATE = LocalDate.of(2000, 1, 1);
        mixin(MakeGlobalVar!(LocalDate)("BASE_DATE",`LocalDate.of(2000, 1, 1)`));
    // }

    /**
     * Constructor.
     *
     * @param field  the field to format, validated not null
     * @param minWidth  the minimum field width, from 1 to 10
     * @param maxWidth  the maximum field width, from 1 to 10
     * @param baseValue  the base value
     * @param baseDate  the base date
     */
    this(TemporalField field, int minWidth, int maxWidth, int baseValue,
            ChronoLocalDate baseDate)
    {
        this(field, minWidth, maxWidth, baseValue, baseDate, 0);
        if (minWidth < 1 || minWidth > 10)
        {
            throw new IllegalArgumentException(
                    "The minWidth must be from 1 to 10 inclusive but was " ~ minWidth
                    .to!string);
        }
        if (maxWidth < 1 || maxWidth > 10)
        {
            throw new IllegalArgumentException(
                    "The maxWidth must be from 1 to 10 inclusive but was " ~ minWidth
                    .to!string);
        }
        if (maxWidth < minWidth)
        {
            throw new IllegalArgumentException("Maximum width must exceed or equal the minimum width but "
                    ~ maxWidth.to!string ~ " < " ~ minWidth.to!string);
        }
        if (baseDate is null)
        {
            if (field.range().isValidValue(baseValue) == false)
            {
                throw new IllegalArgumentException(
                        "The base value must be within the range of the field");
            }
            if (((cast(long) baseValue) + EXCEED_POINTS[maxWidth]) > Integer.MAX_VALUE)
            {
                throw new DateTimeException(
                        "Unable to add printer-parser as the range exceeds the capacity of an int");
            }
        }
    }

    /**
     * Constructor.
     * The arguments have already been checked.
     *
     * @param field  the field to format, validated not null
     * @param minWidth  the minimum field width, from 1 to 10
     * @param maxWidth  the maximum field width, from 1 to 10
     * @param baseValue  the base value
     * @param baseDate  the base date
     * @param subsequentWidth the subsequentWidth for this instance
     */
    package this(TemporalField field, int minWidth, int maxWidth,
            int baseValue, ChronoLocalDate baseDate, int subsequentWidth)
    {
        super(field, minWidth, maxWidth, SignStyle.NOT_NEGATIVE, subsequentWidth);
        this.baseValue = baseValue;
        this.baseDate = baseDate;
    }

    override long getValue(DateTimePrintContext context, long value)
    {
        long absValue = MathHelper.abs(value);
        int baseValue = this.baseValue;
        if (baseDate !is null)
        {
            Chronology chrono = Chronology.from(context.getTemporal());
            baseValue = chrono.date(baseDate).get(field);
        }
        if (value >= baseValue && value < baseValue + EXCEED_POINTS[minWidth])
        {
            // Use the reduced value if it fits _in minWidth
            return absValue % EXCEED_POINTS[minWidth];
        }
        // Otherwise truncate to fit _in maxWidth
        return absValue % EXCEED_POINTS[maxWidth];
    }

    override int setValue(DateTimeParseContext context, long value, int errorPos, int successPos)
    {
        int baseValue = this.baseValue;
        if (baseDate !is null)
        {
            Chronology chrono = context.getEffectiveChronology();
            baseValue = chrono.date(baseDate).get(field);

            // In case the Chronology is changed later, add a callback when/if it changes
            long initialValue = value;
            context.addChronoChangedListener( (Chronology t) {
                /* Repeat the set of the field using the current Chronology
                 * The success/error position is ignored because the value is
                 * intentionally being overwritten.
                 */
                setValue(context, initialValue, errorPos, successPos);
            });
        }
        int parseLen = successPos - errorPos;
        if (parseLen == minWidth && value >= 0)
        {
            long range = EXCEED_POINTS[minWidth];
            long lastPart = baseValue % range;
            long basePart = baseValue - lastPart;
            if (baseValue > 0)
            {
                value = basePart + value;
            }
            else
            {
                value = basePart - value;
            }
            if (value < baseValue)
            {
                value += range;
            }
        }
        return context.setParsedField(field, value, errorPos, successPos);
    }

    /**
 * Returns a new instance with fixed width flag set.
 *
 * @return a new updated printer-parser, not null
 */
    override ReducedPrinterParser withFixedWidth()
    {
        if (subsequentWidth == -1)
        {
            return this;
        }
        return new ReducedPrinterParser(field, minWidth, maxWidth,
                baseValue, baseDate, -1);
    }

    /**
 * Returns a new instance with an updated subsequent width.
 *
 * @param subsequentWidth  the width of subsequent non-negative numbers, 0 or greater
 * @return a new updated printer-parser, not null
 */
    override ReducedPrinterParser withSubsequentWidth(int subsequentWidth)
    {
        return new ReducedPrinterParser(field, minWidth, maxWidth,
                baseValue, baseDate, this.subsequentWidth + subsequentWidth);
    }

    /**
 * For a ReducedPrinterParser, fixed width is false if the mode is strict,
 * otherwise it is set as for NumberPrinterParser.
 * @param context the context
 * @return if the field is fixed width
 * @see DateTimeFormatterBuilder#appendValueReduced(hunt.time.temporal.TemporalField, int, int, int)
 */
    override bool isFixedWidth(DateTimeParseContext context)
    {
        if (context.isStrict() == false)
        {
            return false;
        }
        return super.isFixedWidth(context);
    }

    override public string toString()
    {
        return "ReducedValue(" ~ typeid(field)
            .name ~ "," ~ minWidth.to!string ~ "," ~ maxWidth.to!string ~ "," ~ typeid(baseDate)
            .name ~ ")";
    }
}
