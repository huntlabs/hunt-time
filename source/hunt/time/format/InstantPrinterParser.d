module hunt.time.format.InstantPrinterParser;

import hunt.time.ZoneOffset;
import hunt.time.LocalDateTime;
import hunt.time.format.CompositePrinterParser;
import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalField;
import hunt.util.StringBuilder;

import hunt.Exceptions;
import hunt.Long;
import hunt.math.Helper;
import hunt.util.Common;

import std.conv;

//-----------------------------------------------------------------------
/**
* Prints or parses an ISO-8601 instant.
*/
static final class InstantPrinterParser : DateTimePrinterParser
{
    // days _in a 400 year cycle = 146097
    // days _in a 10,000 year cycle = 146097 * 25
    // seconds per day = 86400
    private enum long SECONDS_PER_10000_YEARS = 146097L * 25L * 86400L;
    private enum long SECONDS_0000_TO_1970 = ((146097L * 5L) - (30L * 365L + 7L)) * 86400L;
    private int fractionalDigits;

    this(int fractionalDigits)
    {
        this.fractionalDigits = fractionalDigits;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        // use INSTANT_SECONDS, thus this code is not bound by Instant.MAX
        Long inSecs = context.getValue(ChronoField.INSTANT_SECONDS);
        Long inNanos = null;
        if (context.getTemporal().isSupported(ChronoField.NANO_OF_SECOND))
        {
            inNanos = new Long(context.getTemporal().getLong(ChronoField.NANO_OF_SECOND));
        }
        if (inSecs is null)
        {
            return false;
        }
        long inSec = inSecs.longValue();
        int inNano = ChronoField.NANO_OF_SECOND.checkValidIntValue(inNanos !is null
                ? inNanos.longValue() : 0);
        // format mostly using LocalDateTime.toString
        if (inSec >= -SECONDS_0000_TO_1970)
        {
            // current era
            long zeroSecs = inSec - SECONDS_PER_10000_YEARS + SECONDS_0000_TO_1970;
            long hi = MathHelper.floorDiv(zeroSecs, SECONDS_PER_10000_YEARS) + 1;
            long lo = MathHelper.floorMod(zeroSecs, SECONDS_PER_10000_YEARS);
            LocalDateTime ldt = LocalDateTime.ofEpochSecond(lo - SECONDS_0000_TO_1970,
                    0, ZoneOffset.UTC);
            if (hi > 0)
            {
                buf.append('+').append(hi);
            }
            buf.append(ldt.toString);
            if (ldt.getSecond() == 0)
            {
                buf.append(":00");
            }
        }
        else
        {
            // before current era
            long zeroSecs = inSec + SECONDS_0000_TO_1970;
            long hi = zeroSecs / SECONDS_PER_10000_YEARS;
            long lo = zeroSecs % SECONDS_PER_10000_YEARS;
            LocalDateTime ldt = LocalDateTime.ofEpochSecond(lo - SECONDS_0000_TO_1970,
                    0, ZoneOffset.UTC);
            int pos = buf.length();
            buf.append(ldt.toString);
            if (ldt.getSecond() == 0)
            {
                buf.append(":00");
            }
            if (hi < 0)
            {
                if (ldt.getYear() == -10_000)
                {
                    buf.replace(pos, pos + 2, to!string(hi - 1));
                }
                else if (lo == 0)
                {
                    buf.insert(pos, hi);
                }
                else
                {
                    buf.insert(pos + 1, (MathHelper.abs(hi)));
                }
            }
        }
        // add fraction
        if ((fractionalDigits < 0 && inNano > 0) || fractionalDigits > 0)
        {
            buf.append('.');
            int div = 100_000_000;
            for (int i = 0; ((fractionalDigits == -1 && inNano > 0)
                    || (fractionalDigits == -2 && (inNano > 0 || (i % 3) != 0))
                    || i < fractionalDigits); i++)
            {
                int digit = inNano / div;
                buf.append( /* cast(char) */ (digit.to!string ~ '0'));
                inNano = inNano - (digit * div);
                div = div / 10;
            }
        }
        buf.append('Z');
        return true;
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        implementationMissing(false);
        return 0;
        // new context to avoid overwriting fields like year/month/day
        // int minDigits = (fractionalDigits < 0 ? 0 : fractionalDigits);
        // int maxDigits = (fractionalDigits < 0 ? 9 : fractionalDigits);
        // CompositePrinterParser parser = new DateTimeFormatterBuilder().append(
        //         DateTimeFormatter.ISO_LOCAL_DATE).appendLiteral('T')
        //     .appendValue(ChronoField.HOUR_OF_DAY,
        //             2).appendLiteral(':').appendValue(ChronoField.MINUTE_OF_HOUR, 2).appendLiteral(':')
        //     .appendValue(ChronoField.SECOND_OF_MINUTE, 2).appendFraction(
        //             ChronoField.NANO_OF_SECOND, minDigits, maxDigits,
        //             true).appendOffsetId().toFormatter().toPrinterParser(false);
        // DateTimeParseContext newContext = context.copy();
        // int pos = parser.parse(newContext, text, position);
        // if (pos < 0)
        // {
        //     return pos;
        // }
        // // parser restricts most fields to 2 digits, so definitely int
        // // correctly parsed nano is also guaranteed to be valid
        // long yearParsed = newContext.getParsed(ChronoField.YEAR).longValue();
        // int month = newContext.getParsed(ChronoField.MONTH_OF_YEAR).intValue();
        // int day = newContext.getParsed(ChronoField.DAY_OF_MONTH).intValue();
        // int hour = newContext.getParsed(ChronoField.HOUR_OF_DAY).intValue();
        // int min = newContext.getParsed(ChronoField.MINUTE_OF_HOUR).intValue();
        // Long secVal = newContext.getParsed(ChronoField.SECOND_OF_MINUTE);
        // Long nanoVal = newContext.getParsed(ChronoField.NANO_OF_SECOND);
        // int sec = (secVal !is null ? secVal.intValue() : 0);
        // int nano = (nanoVal !is null ? nanoVal.intValue() : 0);
        // int offset = newContext.getParsed(ChronoField.OFFSET_SECONDS).intValue();
        // int days = 0;
        // if (hour == 24 && min == 0 && sec == 0 && nano == 0)
        // {
        //     hour = 0;
        //     days = 1;
        // }
        // else if (hour == 23 && min == 59 && sec == 60)
        // {
        //     context.setParsedLeapSecond();
        //     sec = 59;
        // }
        // int year = cast(int) yearParsed % 10_000;
        // long instantSecs;
        // try
        // {
        //     LocalDateTime ldt = LocalDateTime.of(year, month, day,
        //             hour, min, sec, 0).plusDays(days);
        //     instantSecs = ldt.toEpochSecond(ZoneOffset.ofTotalSeconds(offset));
        //     instantSecs += MathHelper.multiplyExact(yearParsed / 10_000L, SECONDS_PER_10000_YEARS);
        // }
        // catch (RuntimeException ex)
        // {
        //     return ~position;
        // }
        // int successPos = pos;
        // successPos = context.setParsedField(ChronoField.INSTANT_SECONDS,
        //         instantSecs, position, successPos);
        // return context.setParsedField(ChronoField.NANO_OF_SECOND, nano,
        //         position, successPos);
    }

    override public string toString()
    {
        return "Instant()";
    }
}