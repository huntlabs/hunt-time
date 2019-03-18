module hunt.time.format.LocalizedOffsetIdPrinterParser;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.TextStyle;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalField;
import hunt.text.StringBuilder;


import hunt.Long;
import hunt.math.Helper;

import std.conv;



//-----------------------------------------------------------------------
/**
* Prints or parses an offset ID.
*/
static final class LocalizedOffsetIdPrinterParser : DateTimePrinterParser
{
    private TextStyle style;

    /**
 * Constructor.
 *
 * @param style  the style, not null
 */
    this(TextStyle style)
    {
        this.style = style;
    }

    private static StringBuilder appendHMS(StringBuilder buf, int t)
    {
        return buf.append( /* cast(char) */ ((t / 10).to!string ~ '0')).append( /* cast(char) */ ((t % 10)
                .to!string ~ '0'));
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        Long offsetSecs = context.getValue(ChronoField.OFFSET_SECONDS);
        if (offsetSecs is null)
        {
            return false;
        }
        string gmtText = "GMT"; // TODO: get localized version of 'GMT'
        buf.append(gmtText);
        int totalSecs = MathHelper.toIntExact(offsetSecs.longValue());
        if (totalSecs != 0)
        {
            int absHours = MathHelper.abs((totalSecs / 3600) % 100); // anything larger than 99 silently dropped
            int absMinutes = MathHelper.abs((totalSecs / 60) % 60);
            int absSeconds = MathHelper.abs(totalSecs % 60);
            buf.append(totalSecs < 0 ? "-" : "+");
            if (style == TextStyle.FULL)
            {
                appendHMS(buf, absHours);
                buf.append(':');
                appendHMS(buf, absMinutes);
                if (absSeconds != 0)
                {
                    buf.append(':');
                    appendHMS(buf, absSeconds);
                }
            }
            else
            {
                if (absHours >= 10)
                {
                    buf.append( /* cast(char) */ ((absHours / 10).to!string ~ '0'));
                }
                buf.append( /* cast(char) */ ((absHours % 10).to!string ~ '0'));
                if (absMinutes != 0 || absSeconds != 0)
                {
                    buf.append(':');
                    appendHMS(buf, absMinutes);
                    if (absSeconds != 0)
                    {
                        buf.append(':');
                        appendHMS(buf, absSeconds);
                    }
                }
            }
        }
        return true;
    }

    int getDigit(string text, int position)
    {
        char c = text[position];
        if (c < '0' || c > '9')
        {
            return -1;
        }
        return c - '0';
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        int pos = position;
        int end = cast(int)(text.length);
        string gmtText = "GMT"; // TODO: get localized version of 'GMT'
        if (!context.subSequenceEquals(text, pos, gmtText, 0, cast(int)(gmtText.length)))
        {
            return ~position;
        }
        pos += gmtText.length;
        // parse normal plus/minus offset
        int negative = 0;
        if (pos == end)
        {
            return context.setParsedField(ChronoField.OFFSET_SECONDS, 0, position, pos);
        }
        char sign = text[pos]; // IOOBE if invalid position
        if (sign == '+')
        {
            negative = 1;
        }
        else if (sign == '-')
        {
            negative = -1;
        }
        else
        {
            return context.setParsedField(ChronoField.OFFSET_SECONDS, 0, position, pos);
        }
        pos++;
        int h = 0;
        int m = 0;
        int s = 0;
        if (style == TextStyle.FULL)
        {
            int h1 = getDigit(text, pos++);
            int h2 = getDigit(text, pos++);
            if (h1 < 0 || h2 < 0 || text[pos++] != ':')
            {
                return ~position;
            }
            h = h1 * 10 + h2;
            int m1 = getDigit(text, pos++);
            int m2 = getDigit(text, pos++);
            if (m1 < 0 || m2 < 0)
            {
                return ~position;
            }
            m = m1 * 10 + m2;
            if (pos + 2 < end && text[pos] == ':')
            {
                int s1 = getDigit(text, pos + 1);
                int s2 = getDigit(text, pos + 2);
                if (s1 >= 0 && s2 >= 0)
                {
                    s = s1 * 10 + s2;
                    pos += 3;
                }
            }
        }
        else
        {
            h = getDigit(text, pos++);
            if (h < 0)
            {
                return ~position;
            }
            if (pos < end)
            {
                int h2 = getDigit(text, pos);
                if (h2 >= 0)
                {
                    h = h * 10 + h2;
                    pos++;
                }
                if (pos + 2 < end && text[pos] == ':')
                {
                    if (pos + 2 < end && text[pos] == ':')
                    {
                        int m1 = getDigit(text, pos + 1);
                        int m2 = getDigit(text, pos + 2);
                        if (m1 >= 0 && m2 >= 0)
                        {
                            m = m1 * 10 + m2;
                            pos += 3;
                            if (pos + 2 < end && text[pos] == ':')
                            {
                                int s1 = getDigit(text, pos + 1);
                                int s2 = getDigit(text, pos + 2);
                                if (s1 >= 0 && s2 >= 0)
                                {
                                    s = s1 * 10 + s2;
                                    pos += 3;
                                }
                            }
                        }
                    }
                }
            }
        }
        long offsetSecs = negative * (h * 3600L + m * 60L + s);
        return context.setParsedField(ChronoField.OFFSET_SECONDS,
                offsetSecs, position, pos);
    }

    override public string toString()
    {
        return "LocalizedOffset(" ~ typeid(style).name ~ ")";
    }
}

