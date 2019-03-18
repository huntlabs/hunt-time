module hunt.time.format.NumberPrinterParser;

import hunt.time.Exceptions;
import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.DecimalStyle;
import hunt.time.format.SignStyle;
import hunt.time.temporal.TemporalField;
import hunt.text.StringBuilder;

import hunt.Long;
import hunt.math.BigInteger;
import hunt.math.Helper;

import std.conv;


//-----------------------------------------------------------------------
/**
 * Prints and parses a numeric date-time field with optional padding.
 */
class NumberPrinterParser : DateTimePrinterParser
{

    /**
     * Array of 10 to the power of n.
     */
    enum long[] EXCEED_POINTS = [
        0L, 10L, 100L, 1000L, 10000L, 100000L, 1000000L, 10000000L,
        100000000L, 1000000000L, 10000000000L,
    ];

    TemporalField field;
    int minWidth;
    int maxWidth;
    package SignStyle signStyle;
    int subsequentWidth;

    /**
     * Constructor.
     *
     * @param field  the field to format, not null
     * @param minWidth  the minimum field width, from 1 to 19
     * @param maxWidth  the maximum field width, from minWidth to 19
     * @param signStyle  the positive/negative sign style, not null
     */
    this(TemporalField field, int minWidth, int maxWidth, SignStyle signStyle)
    {
        // validated by caller
        this.field = field;
        this.minWidth = minWidth;
        this.maxWidth = maxWidth;
        this.signStyle = signStyle;
        this.subsequentWidth = 0;
    }

    /**
     * Constructor.
     *
     * @param field  the field to format, not null
     * @param minWidth  the minimum field width, from 1 to 19
     * @param maxWidth  the maximum field width, from minWidth to 19
     * @param signStyle  the positive/negative sign style, not null
     * @param subsequentWidth  the width of subsequent non-negative numbers, 0 or greater,
     *  -1 if fixed width due to active adjacent parsing
     */
    package this(TemporalField field, int minWidth, int maxWidth,
            SignStyle signStyle, int subsequentWidth)
    {
        // validated by caller
        this.field = field;
        this.minWidth = minWidth;
        this.maxWidth = maxWidth;
        this.signStyle = signStyle;
        this.subsequentWidth = subsequentWidth;
    }

    /**
     * Returns a new instance with fixed width flag set.
     *
     * @return a new updated printer-parser, not null
     */
    NumberPrinterParser withFixedWidth()
    {
        if (subsequentWidth == -1)
        {
            return this;
        }
        return new NumberPrinterParser(field, minWidth, maxWidth, signStyle, -1);
    }

    /**
     * Returns a new instance with an updated subsequent width.
     *
     * @param subsequentWidth  the width of subsequent non-negative numbers, 0 or greater
     * @return a new updated printer-parser, not null
     */
    NumberPrinterParser withSubsequentWidth(int subsequentWidth)
    {
        return new NumberPrinterParser(field, minWidth, maxWidth,
                signStyle, this.subsequentWidth + subsequentWidth);
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        Long valueLong = context.getValue(field);
        if (valueLong is null)
        {
            return false;
        }
        long value = getValue(context, valueLong.longValue());
        DecimalStyle decimalStyle = context.getDecimalStyle();
        string str = (value == Long.MIN_VALUE ? "9223372036854775808"
                : to!string(MathHelper.abs(value)));
        if (str.length > maxWidth)
        {
            throw new DateTimeException("Field " ~ typeid(field)
                    .name ~ " cannot be printed as the value " ~ value.to!string
                    ~ " exceeds the maximum print width of " ~ maxWidth.to!string);
        }
        str = decimalStyle.convertNumberToI18N(str);

        if (value >= 0)
        {
            auto name = signStyle.name();
            {
                if (name == SignStyle.EXCEEDS_PAD.name())
                {
                    if (minWidth < 19 && value >= EXCEED_POINTS[minWidth])
                    {
                        buf.append(decimalStyle.getPositiveSign());
                    }
                }

                if (name == SignStyle.ALWAYS.name())
                {
                    buf.append(decimalStyle.getPositiveSign());
                }

            }
        }
        else
        {
            auto name = signStyle.name();
            {
                if (name == SignStyle.NORMAL.name()
                        || name == SignStyle.EXCEEDS_PAD.name()
                        || name == SignStyle.ALWAYS.name())
                {
                    buf.append(decimalStyle.getNegativeSign());
                }
                if (name == SignStyle.NOT_NEGATIVE.name())
                {
                    throw new DateTimeException("Field " ~ typeid(field)
                            .name ~ " cannot be printed as the value " ~ value.to!string
                            ~ " cannot be negative according to the SignStyle");
                }
            }
        }
        for (int i = 0; i < minWidth - str.length; i++)
        {
            buf.append(decimalStyle.getZeroDigit());
        }
        buf.append(str);
        return true;
    }

    /**
     * Gets the value to output.
     *
     * @param context  the context
     * @param value  the value of the field, not null
     * @return the value
     */
    long getValue(DateTimePrintContext context, long value)
    {
        return value;
    }

    /**
     * For NumberPrinterParser, the width is fixed depending on the
     * minWidth, maxWidth, signStyle and whether subsequent fields are fixed.
     * @param context the context
     * @return true if the field is fixed width
     * @see DateTimeFormatterBuilder#appendValue(hunt.time.temporal.TemporalField, int)
     */
    bool isFixedWidth(DateTimeParseContext context)
    {
        return subsequentWidth == -1 || (subsequentWidth > 0
                && minWidth == maxWidth && signStyle == SignStyle.NOT_NEGATIVE);
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        int length = cast(int)(text.length);
        if (position == length)
        {
            return ~position;
        }
        char sign = text[position]; // IOOBE if invalid position
        bool negative = false;
        bool positive = false;
        if (sign == context.getDecimalStyle().getPositiveSign())
        {
            if (signStyle.parse(true, context.isStrict(), minWidth == maxWidth) == false)
            {
                return ~position;
            }
            positive = true;
            position++;
        }
        else if (sign == context.getDecimalStyle().getNegativeSign())
        {
            if (signStyle.parse(false, context.isStrict(), minWidth == maxWidth) == false)
            {
                return ~position;
            }
            negative = true;
            position++;
        }
        else
        {
            if (signStyle == SignStyle.ALWAYS && context.isStrict())
            {
                return ~position;
            }
        }
        int effMinWidth = (context.isStrict() || isFixedWidth(context) ? minWidth : 1);
        int minEndPos = position + effMinWidth;
        if (minEndPos > length)
        {
            return ~position;
        }
        int effMaxWidth = (context.isStrict() || isFixedWidth(context) ? maxWidth : 9) + MathHelper.max(subsequentWidth,
                0);
        long total = 0;
        BigInteger totalBig = null;
        int pos = position;
        for (int pass = 0; pass < 2; pass++)
        {
            int maxEndPos = MathHelper.min(pos + effMaxWidth, length);
            while (pos < maxEndPos)
            {
                char ch = text[pos++];
                int digit = context.getDecimalStyle().convertToDigit(ch);
                if (digit < 0)
                {
                    pos--;
                    if (pos < minEndPos)
                    {
                        return ~position; // need at least min width digits
                    }
                    break;
                }
                if ((pos - position) > 18)
                {
                    if (totalBig is null)
                    {
                        totalBig = BigInteger.valueOf(total);
                    }
                    totalBig = totalBig.multiply(BigInteger.TEN).add(BigInteger.valueOf(digit));
                }
                else
                {
                    total = total * 10 + digit;
                }
            }
            if (subsequentWidth > 0 && pass == 0)
            {
                // re-parse now we know the correct width
                int parseLen = pos - position;
                effMaxWidth = MathHelper.max(effMinWidth, parseLen - subsequentWidth);
                pos = position;
                total = 0;
                totalBig = null;
            }
            else
            {
                break;
            }
        }
        if (negative)
        {
            if (totalBig !is null)
            {
                if (totalBig.equals(BigInteger.ZERO) && context.isStrict())
                {
                    return ~(position - 1); // minus zero not allowed
                }
                totalBig = totalBig.negate();
            }
            else
            {
                if (total == 0 && context.isStrict())
                {
                    return ~(position - 1); // minus zero not allowed
                }
                total = -total;
            }
        }
        else if (signStyle == SignStyle.EXCEEDS_PAD && context.isStrict())
        {
            int parseLen = pos - position;
            if (positive)
            {
                if (parseLen <= minWidth)
                {
                    return ~(position - 1); // '+' only parsed if minWidth exceeded
                }
            }
            else
            {
                if (parseLen > minWidth)
                {
                    return ~position; // '+' must be parsed if minWidth exceeded
                }
            }
        }
        if (totalBig !is null)
        {
            if (totalBig.bitLength() > 63)
            {
                // overflow, parse 1 less digit
                totalBig = totalBig.divide(BigInteger.TEN);
                pos--;
            }
            return setValue(context, totalBig.longValue(), position, pos);
        }
        return setValue(context, total, position, pos);
    }

    /**
     * Stores the value.
     *
     * @param context  the context to store into, not null
     * @param value  the value
     * @param errorPos  the position of the field being parsed
     * @param successPos  the position after the field being parsed
     * @return the new position
     */
    int setValue(DateTimeParseContext context, long value, int errorPos, int successPos)
    {
        return context.setParsedField(field, value, errorPos, successPos);
    }

    override public string toString()
    {
        if (minWidth == 1 && maxWidth == 19 && signStyle.name() == SignStyle.NORMAL.name())
        {
            return "Value(" ~ typeid(field).name ~ ")";
        }
        if (minWidth == maxWidth && signStyle == SignStyle.NOT_NEGATIVE)
        {
            return "Value(" ~ typeid(field).name ~ "," ~ minWidth.to!string ~ ")";
        }
        return "Value(" ~ typeid(field)
            .name ~ "," ~ minWidth.to!string ~ "," ~ maxWidth.to!string ~ "," ~ signStyle.name()
            ~ ")";
    }
}
