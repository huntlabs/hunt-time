module hunt.time.format.FractionPrinterParser;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.DecimalStyle;
import hunt.time.format.NumberPrinterParser;
import hunt.time.format.SignStyle;
import hunt.time.temporal.TemporalField;
import hunt.util.StringBuilder;

import hunt.Exceptions;
import hunt.Long;
import hunt.math.BigDecimal;
import hunt.math.Helper;
import hunt.text.Common;

import std.conv;


//-----------------------------------------------------------------------
/**
* Prints and parses a numeric date-time field with optional padding.
*/
static final class FractionPrinterParser : NumberPrinterParser
{
    private bool decimalPoint;

    /**
 * Constructor.
 *
 * @param field  the field to output, not null
 * @param minWidth  the minimum width to output, from 0 to 9
 * @param maxWidth  the maximum width to output, from 0 to 9
 * @param decimalPoint  whether to output the localized decimal point symbol
 */
    this(TemporalField field, int minWidth, int maxWidth, bool decimalPoint)
    {
        this(field, minWidth, maxWidth, decimalPoint, 0);
        assert(field, "field");
        if (field.range().isFixed() == false)
        {
            throw new IllegalArgumentException(
                    "Field must have a fixed set of values: " ~ typeid(field).name);
        }
        if (minWidth < 0 || minWidth > 9)
        {
            throw new IllegalArgumentException(
                    "Minimum width must be from 0 to 9 inclusive but was "
                    ~ minWidth.to!string);
        }
        if (maxWidth < 1 || maxWidth > 9)
        {
            throw new IllegalArgumentException(
                    "Maximum width must be from 1 to 9 inclusive but was "
                    ~ maxWidth.to!string);
        }
        if (maxWidth < minWidth)
        {
            throw new IllegalArgumentException("Maximum width must exceed or equal the minimum width but "
                    ~ maxWidth.to!string ~ " < " ~ minWidth.to!string);
        }
    }

    /**
 * Constructor.
 *
 * @param field  the field to output, not null
 * @param minWidth  the minimum width to output, from 0 to 9
 * @param maxWidth  the maximum width to output, from 0 to 9
 * @param decimalPoint  whether to output the localized decimal point symbol
 * @param subsequentWidth the subsequentWidth for this instance
 */
    this(TemporalField field, int minWidth, int maxWidth,
            bool decimalPoint, int subsequentWidth)
    {
        super(field, minWidth, maxWidth, SignStyle.NOT_NEGATIVE, subsequentWidth);
        this.decimalPoint = decimalPoint;
    }

    /**
 * Returns a new instance with fixed width flag set.
 *
 * @return a new updated printer-parser, not null
 */
    override FractionPrinterParser withFixedWidth()
    {
        if (subsequentWidth == -1)
        {
            return this;
        }
        return new FractionPrinterParser(field, minWidth, maxWidth, decimalPoint, -1);
    }

    /**
 * Returns a new instance with an updated subsequent width.
 *
 * @param subsequentWidth  the width of subsequent non-negative numbers, 0 or greater
 * @return a new updated printer-parser, not null
 */
    override FractionPrinterParser withSubsequentWidth(int subsequentWidth)
    {
        return new FractionPrinterParser(field, minWidth, maxWidth,
                decimalPoint, this.subsequentWidth + subsequentWidth);
    }

    /**
 * For FractionPrinterPrinterParser, the width is fixed if context is sttrict,
 * minWidth equal to maxWidth and decimalpoint is absent.
 * @param context the context
 * @return if the field is fixed width
 * @see DateTimeFormatterBuilder#appendValueFraction(hunt.time.temporal.TemporalField, int, int, bool)
 */
    override bool isFixedWidth(DateTimeParseContext context)
    {
        if (context.isStrict() && minWidth == maxWidth && decimalPoint == false)
        {
            return true;
        }
        return false;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        Long value = context.getValue(field);
        if (value is null)
        {
            return false;
        }
        DecimalStyle decimalStyle = context.getDecimalStyle();
        BigDecimal fraction = convertToFraction(value.longValue());
        if(fraction !is null )
        {
            if (fraction.scale() == 0)
        { // scale is zero if value is zero
            if (minWidth > 0)
            {
                if (decimalPoint)
                {
                    buf.append(decimalStyle.getDecimalSeparator());
                }
                for (int i = 0; i < minWidth; i++)
                {
                    buf.append(decimalStyle.getZeroDigit());
                }
            }
        }
        else
        {
            int outputScale = MathHelper.min(MathHelper.max(fraction.scale(), minWidth), maxWidth);
            fraction = fraction.setScale(outputScale, RoundingMode.FLOOR.mode());
            string str = fraction.toPlainString().substring(2);
            str = decimalStyle.convertNumberToI18N(str);
            if (decimalPoint)
            {
                buf.append(decimalStyle.getDecimalSeparator());
            }
            buf.append(str);
            }
        }
        return true;
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        int effectiveMin = (context.isStrict() || isFixedWidth(context) ? minWidth : 0);
        int effectiveMax = (context.isStrict() || isFixedWidth(context) ? maxWidth : 9);
        int length = cast(int)(text.length);
        if (position == length)
        {
            // valid if whole field is optional, invalid if minimum width
            return (effectiveMin > 0 ? ~position : position);
        }
        if (decimalPoint)
        {
            if (text[position] != context.getDecimalStyle().getDecimalSeparator())
            {
                // valid if whole field is optional, invalid if minimum width
                return (effectiveMin > 0 ? ~position : position);
            }
            position++;
        }
        int minEndPos = position + effectiveMin;
        if (minEndPos > length)
        {
            return ~position; // need at least min width digits
        }
        int maxEndPos = MathHelper.min(position + effectiveMax, length);
        int total = 0; // can use int because we are only parsing up to 9 digits
        int pos = position;
        while (pos < maxEndPos)
        {
            char ch = text[pos++];
            int digit = context.getDecimalStyle().convertToDigit(ch);
            if (digit < 0)
            {
                if (pos < minEndPos)
                {
                    return ~position; // need at least min width digits
                }
                pos--;
                break;
            }
            total = total * 10 + digit;
        }
        BigDecimal fraction = new BigDecimal(total).movePointLeft(pos - position);
        long value = convertFromFraction(fraction);
        return context.setParsedField(field, value, position, pos);
    }

    /**
 * Converts a value for this field to a fraction between 0 and 1.
 * !(p)
 * The fractional value is between 0 (inclusive) and 1 (exclusive).
 * It can only be returned if the {@link hunt.time.temporal.TemporalField#range() value range} is fixed.
 * The fraction is obtained by calculation from the field range using 9 decimal
 * places and a rounding mode of {@link RoundingMode#FLOOR FLOOR}.
 * The calculation is inaccurate if the values do not run continuously from smallest to largest.
 * !(p)
 * For example, the second-of-minute value of 15 would be returned as 0.25,
 * assuming the standard definition of 60 seconds _in a minute.
 *
 * @param value  the value to convert, must be valid for this rule
 * @return the value as a fraction within the range, from 0 to 1, not null
 * @throws DateTimeException if the value cannot be converted to a fraction
 */
    private BigDecimal convertToFraction(long value)
    {
        ///@gxc
        // ValueRange range = field.range();
        // range.checkValidValue(value, field);
        // BigDecimal minBD = BigDecimal.valueOf(range.getMinimum());
        // BigDecimal rangeBD = BigDecimal.valueOf(range.getMaximum()).subtract(minBD).add(BigDecimal.ONE);
        // BigDecimal valueBD = BigDecimal.valueOf(value).subtract(minBD);
        // BigDecimal fraction = valueBD.divide(rangeBD, 9, RoundingMode.FLOOR);
        // // stripTrailingZeros bug
        // return fraction.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ZERO : fraction.stripTrailingZeros();
        implementationMissing();
        return null;
    }

    /**
 * Converts a fraction from 0 to 1 for this field to a value.
 * !(p)
 * The fractional value must be between 0 (inclusive) and 1 (exclusive).
 * It can only be returned if the {@link hunt.time.temporal.TemporalField#range() value range} is fixed.
 * The value is obtained by calculation from the field range and a rounding
 * mode of {@link RoundingMode#FLOOR FLOOR}.
 * The calculation is inaccurate if the values do not run continuously from smallest to largest.
 * !(p)
 * For example, the fractional second-of-minute of 0.25 would be converted to 15,
 * assuming the standard definition of 60 seconds _in a minute.
 *
 * @param fraction  the fraction to convert, not null
 * @return the value of the field, valid for this rule
 * @throws DateTimeException if the value cannot be converted
 */
    private long convertFromFraction(BigDecimal fraction)
    {
        // ValueRange range = field.range();
        // BigDecimal minBD = BigDecimal.valueOf(range.getMinimum());
        // BigDecimal rangeBD = BigDecimal.valueOf(range.getMaximum()).subtract(minBD).add(BigDecimal.ONE);
        // BigDecimal valueBD = fraction.multiply(rangeBD).setScale(0, RoundingMode.FLOOR.mode()).add(minBD);
        // return valueBD.longValueExact();
        implementationMissing();
        return long.init;
    }

    override public string toString()
    {
        string decimal = (decimalPoint ? ",DecimalPoint" : "");
        return "Fraction(" ~ typeid(field)
            .name ~ "," ~ minWidth.to!string ~ "," ~ maxWidth.to!string ~ decimal ~ ")";
    }
}
