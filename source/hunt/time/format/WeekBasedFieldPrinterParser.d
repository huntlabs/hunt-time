module hunt.time.format.WeekBasedFieldPrinterParser;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.NumberPrinterParser;
import hunt.time.format.ReducedPrinterParser;
import hunt.time.format.SignStyle;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.WeekFields;

import hunt.util.StringBuilder;

import hunt.Exceptions;
import hunt.util.Locale;

//-----------------------------------------------------------------------
/**
* Prints or parses a localized pattern from a localized field.
* The specific formatter and parameters is not selected until
* the field is to be printed or parsed.
* The locale is needed to select the proper WeekFields from which
* the field for day-of-week, week-of-month, or week-of-year is selected.
* Hence the inherited field NumberPrinterParser.field is unused.
*/
static final class WeekBasedFieldPrinterParser : NumberPrinterParser
{
    private char chr;
    private int count;

    /**
 * Constructor.
 *
 * @param chr the pattern format letter that added this PrinterParser.
 * @param count the repeat count of the format letter
 * @param minWidth  the minimum field width, from 1 to 19
 * @param maxWidth  the maximum field width, from minWidth to 19
 */
    this(char chr, int count, int minWidth, int maxWidth)
    {
        this(chr, count, minWidth, maxWidth, 0);
    }

    /**
 * Constructor.
 *
 * @param chr the pattern format letter that added this PrinterParser.
 * @param count the repeat count of the format letter
 * @param minWidth  the minimum field width, from 1 to 19
 * @param maxWidth  the maximum field width, from minWidth to 19
 * @param subsequentWidth  the width of subsequent non-negative numbers, 0 or greater,
 * -1 if fixed width due to active adjacent parsing
 */
    this(char chr, int count, int minWidth, int maxWidth, int subsequentWidth)
    {
        super(null, minWidth, maxWidth, SignStyle.NOT_NEGATIVE, subsequentWidth);
        this.chr = chr;
        this.count = count;
    }

    /**
 * Returns a new instance with fixed width flag set.
 *
 * @return a new updated printer-parser, not null
 */
    override WeekBasedFieldPrinterParser withFixedWidth()
    {
        if (subsequentWidth == -1)
        {
            return this;
        }
        return new WeekBasedFieldPrinterParser(chr, count, minWidth, maxWidth, -1);
    }

    /**
 * Returns a new instance with an updated subsequent width.
 *
 * @param subsequentWidth  the width of subsequent non-negative numbers, 0 or greater
 * @return a new updated printer-parser, not null
 */
    override WeekBasedFieldPrinterParser withSubsequentWidth(int subsequentWidth)
    {
        return new WeekBasedFieldPrinterParser(chr, count, minWidth,
                maxWidth, this.subsequentWidth + subsequentWidth);
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        return printerParser(context.getLocale()).format(context, buf);
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        return printerParser(context.getLocale()).parse(context, text, position);
    }

    /**
 * Gets the printerParser to use based on the field and the locale.
 *
 * @param locale  the locale to use, not null
 * @return the formatter, not null
 * @throws IllegalArgumentException if the formatter cannot be found
 */
    private DateTimePrinterParser printerParser(Locale locale)
    {
        WeekFields weekDef = WeekFields.of(locale);
        TemporalField field = null;
        switch (chr)
        {
        case 'Y':
            field = weekDef.weekBasedYear();
            if (count == 2)
            {
                return new ReducedPrinterParser(field, 2, 2, 0,
                        ReducedPrinterParser.BASE_DATE, this.subsequentWidth);
            }
            else
            {
                return new NumberPrinterParser(field, count, 19, (count < 4)
                        ? SignStyle.NORMAL : SignStyle.EXCEEDS_PAD, this.subsequentWidth);
            }
        case 'e':
        case 'c':
            field = weekDef.dayOfWeek();
            break;
        case 'w':
            field = weekDef.weekOfWeekBasedYear();
            break;
        case 'W':
            field = weekDef.weekOfMonth();
            break;
        default:
            throw new IllegalStateException("unreachable");
        }
        return new NumberPrinterParser(field, minWidth, maxWidth,
                SignStyle.NOT_NEGATIVE, this.subsequentWidth);
    }

    override public string toString()
    {
        StringBuilder sb = new StringBuilder(30);
        sb.append("Localized(");
        if (chr == 'Y')
        {
            if (count == 1)
            {
                sb.append("WeekBasedYear");
            }
            else if (count == 2)
            {
                sb.append("ReducedValue(WeekBasedYear,2,2,2000-01-01)");
            }
            else
            {
                sb.append("WeekBasedYear,").append(count).append(",")
                    .append(19).append(",").append((count < 4)
                            ? SignStyle.NORMAL.name() : SignStyle.EXCEEDS_PAD.name());
            }
        }
        else
        {
            switch (chr)
            {
            case 'c':
            case 'e':
                sb.append("DayOfWeek");
                break;
            case 'w':
                sb.append("WeekOfWeekBasedYear");
                break;
            case 'W':
                sb.append("WeekOfMonth");
                break;
            default:
                break;
            }
            sb.append(",");
            sb.append(count);
        }
        sb.append(")");
        return sb.toString();
    }
}
