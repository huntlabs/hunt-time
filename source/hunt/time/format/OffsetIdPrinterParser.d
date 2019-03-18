module hunt.time.format.OffsetIdPrinterParser;

import hunt.time.Exceptions;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalField;
import hunt.time.util.Common;
import hunt.text.StringBuilder;

import hunt.Exceptions;
import hunt.Long;
import hunt.math.Helper;

import std.conv;

//-----------------------------------------------------------------------
/**
* Prints or parses an offset ID.
*/
static final class OffsetIdPrinterParser : DateTimePrinterParser
{
    enum string[] PATTERNS = [
            "+HH", "+HHmm", "+HH:mm", "+HHMM", "+HH:MM", "+HHMMss", "+HH:MM:ss", "+HHMMSS", "+HH:MM:SS",
            "+HHmmss", "+HH:mm:ss", "+H", "+Hmm", "+H:mm", "+HMM", "+H:MM", "+HMMss",
            "+H:MM:ss", "+HMMSS", "+H:MM:SS", "+Hmmss", "+H:mm:ss",
        ]; // order used _in pattern builder
    // __gshared OffsetIdPrinterParser INSTANCE_ID_Z;
    // __gshared OffsetIdPrinterParser INSTANCE_ID_ZERO;

    private string noOffsetText;
    private int type;
    private int style;

    // shared static this()
    // {
        // INSTANCE_ID_Z = new OffsetIdPrinterParser("+HH:MM:ss", "Z");
        mixin(MakeGlobalVar!(OffsetIdPrinterParser)("INSTANCE_ID_Z",`new OffsetIdPrinterParser("+HH:MM:ss", "Z")`));
        // INSTANCE_ID_ZERO = new OffsetIdPrinterParser("+HH:MM:ss", "0");
        mixin(MakeGlobalVar!(OffsetIdPrinterParser)("INSTANCE_ID_ZERO",`new OffsetIdPrinterParser("+HH:MM:ss", "0")`));

    // }
    /**
 * Constructor.
 *
 * @param pattern  the pattern
 * @param noOffsetText  the text to use for UTC, not null
 */
    this(string pattern, string noOffsetText)
    {
        assert(pattern, "pattern");
        assert(noOffsetText, "noOffsetText");
        this.type = checkPattern(pattern);
        this.style = type % 11;
        this.noOffsetText = noOffsetText;
    }

    private int checkPattern(string pattern)
    {
        for (int i = 0; i < PATTERNS.length; i++)
        {
            if (PATTERNS[i] == (pattern))
            {
                return i;
            }
        }
        throw new IllegalArgumentException("Invalid zone offset pattern: " ~ pattern);
    }

    private bool isPaddedHour()
    {
        return type < 11;
    }

    private bool isColon()
    {
        return style > 0 && (style % 2) == 0;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        Long offsetSecs = context.getValue(ChronoField.OFFSET_SECONDS);
        if (offsetSecs is null)
        {
            return false;
        }
        int totalSecs = MathHelper.toIntExact(offsetSecs.longValue());
        if (totalSecs == 0)
        {
            buf.append(noOffsetText);
        }
        else
        {
            int absHours = MathHelper.abs((totalSecs / 3600) % 100); // anything larger than 99 silently dropped
            int absMinutes = MathHelper.abs((totalSecs / 60) % 60);
            int absSeconds = MathHelper.abs(totalSecs % 60);
            int bufPos = buf.length();
            int output = absHours;
            buf.append(totalSecs < 0 ? "-" : "+");
            if (isPaddedHour() || absHours >= 10)
            {
                formatZeroPad(false, absHours, buf);
            }
            else
            {
                buf.append( /* cast(char) */ (absHours.to!string ~ '0'));
            }
            if ((style >= 3 && style <= 8) || (style >= 9 && absSeconds > 0)
                    || (style >= 1 && absMinutes > 0))
            {
                formatZeroPad(isColon(), absMinutes, buf);
                output += absMinutes;
                if (style == 7 || style == 8 || (style >= 5 && absSeconds > 0))
                {
                    formatZeroPad(isColon(), absSeconds, buf);
                    output += absSeconds;
                }
            }
            if (output == 0)
            {
                buf.setLength(bufPos);
                buf.append(noOffsetText);
            }
        }
        return true;
    }

    private void formatZeroPad(bool colon, int value, StringBuilder buf)
    {
        buf.append(colon ? ":" : "").append( /* cast(char) */ ((value / 10)
                .to!string ~ '0')).append( /* cast(char) */ ((value % 10).to!string ~ '0'));
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        int length = cast(int)(text.length);
        int noOffsetLen = cast(int)(noOffsetText.length);
        if (noOffsetLen == 0)
        {
            if (position == length)
            {
                return context.setParsedField(ChronoField.OFFSET_SECONDS,
                        0, position, position);
            }
        }
        else
        {
            if (position == length)
            {
                return ~position;
            }
            if (context.subSequenceEquals(text, position, noOffsetText, 0, noOffsetLen))
            {
                return context.setParsedField(ChronoField.OFFSET_SECONDS,
                        0, position, position + noOffsetLen);
            }
        }

        // parse normal plus/minus offset
        char sign = text[position]; // IOOBE if invalid position
        if (sign == '+' || sign == '-')
        {
            // starts
            int negative = (sign == '-' ? -1 : 1);
            bool isColon = isColon();
            bool paddedHour = isPaddedHour();
            int[] array = new int[4];
            array[0] = position + 1;
            int parseType = type;
            // select parse type when lenient
            if (!context.isStrict())
            {
                if (paddedHour)
                {
                    if (isColon || (parseType == 0 && length > position + 3
                            && text[position + 3] == ':'))
                    {
                        isColon = true; // needed _in cases like ("+HH", "+01:01")
                        parseType = 10;
                    }
                    else
                    {
                        parseType = 9;
                    }
                }
                else
                {
                    if (isColon || (parseType == 11 && length > position + 3
                            && (text[position + 2] == ':'
                            || text[position + 3] == ':')))
                    {
                        isColon = true;
                        parseType = 21; // needed _in cases like ("+H", "+1:01")
                    }
                    else
                    {
                        parseType = 20;
                    }
                }
            }
            // parse according to the selected pattern
            switch (parseType)
            {
            case 0: // +HH
            case 11: // +H
                parseHour(text, paddedHour, array);
                break;
            case 1: // +HHmm
            case 2: // +HH:mm
            case 13: // +H:mm
                parseHour(text, paddedHour, array);
                parseMinute(text, isColon, false, array);
                break;
            case 3: // +HHMM
            case 4: // +HH:MM
            case 15: // +H:MM
                parseHour(text, paddedHour, array);
                parseMinute(text, isColon, true, array);
                break;
            case 5: // +HHMMss
            case 6: // +HH:MM:ss
            case 17: // +H:MM:ss
                parseHour(text, paddedHour, array);
                parseMinute(text, isColon, true, array);
                parseSecond(text, isColon, false, array);
                break;
            case 7: // +HHMMSS
            case 8: // +HH:MM:SS
            case 19: // +H:MM:SS
                parseHour(text, paddedHour, array);
                parseMinute(text, isColon, true, array);
                parseSecond(text, isColon, true, array);
                break;
            case 9: // +HHmmss
            case 10: // +HH:mm:ss
            case 21: // +H:mm:ss
                parseHour(text, paddedHour, array);
                parseOptionalMinuteSecond(text, isColon, array);
                break;
            case 12: // +Hmm
                parseVariableWidthDigits(text, 1, 4, array);
                break;
            case 14: // +HMM
                parseVariableWidthDigits(text, 3, 4, array);
                break;
            case 16: // +HMMss
                parseVariableWidthDigits(text, 3, 6, array);
                break;
            case 18: // +HMMSS
                parseVariableWidthDigits(text, 5, 6, array);
                break;
            case 20: // +Hmmss
                parseVariableWidthDigits(text, 1, 6, array);
                break;
            default:
                break;
            }
            if (array[0] > 0)
            {
                if (array[1] > 23 || array[2] > 59 || array[3] > 59)
                {
                    throw new DateTimeException(
                            "Value _out of range: Hour[0-23], Minute[0-59], Second[0-59]");
                }
                long offsetSecs = negative * (array[1] * 3600L + array[2] * 60L + array[3]);
                return context.setParsedField(ChronoField.OFFSET_SECONDS,
                        offsetSecs, position, array[0]);
            }
        }
        // handle special case of empty no offset text
        if (noOffsetLen == 0)
        {
            return context.setParsedField(ChronoField.OFFSET_SECONDS,
                    0, position, position);
        }
        return ~position;
    }

    private void parseHour(string parseText, bool paddedHour, int[] array)
    {
        if (paddedHour)
        {
            // parse two digits
            if (!parseDigits(parseText, false, 1, array))
            {
                array[0] = ~array[0];
            }
        }
        else
        {
            // parse one or two digits
            parseVariableWidthDigits(parseText, 1, 2, array);
        }
    }

    private void parseMinute(string parseText, bool isColon, bool mandatory, int[] array)
    {
        if (!parseDigits(parseText, isColon, 2, array))
        {
            if (mandatory)
            {
                array[0] = ~array[0];
            }
        }
    }

    private void parseSecond(string parseText, bool isColon, bool mandatory, int[] array)
    {
        if (!parseDigits(parseText, isColon, 3, array))
        {
            if (mandatory)
            {
                array[0] = ~array[0];
            }
        }
    }

    private void parseOptionalMinuteSecond(string parseText, bool isColon, int[] array)
    {
        if (parseDigits(parseText, isColon, 2, array))
        {
            parseDigits(parseText, isColon, 3, array);
        }
    }

    private bool parseDigits(string parseText, bool isColon, int arrayIndex, int[] array)
    {
        int pos = array[0];
        if (pos < 0)
        {
            return true;
        }
        if (isColon && arrayIndex != 1)
        { //  ':' will precede only _in case of minute/second
            if (pos + 1 > parseText.length || parseText[pos] != ':')
            {
                return false;
            }
            pos++;
        }
        if (pos + 2 > parseText.length)
        {
            return false;
        }
        char ch1 = parseText[pos++];
        char ch2 = parseText[pos++];
        if (ch1 < '0' || ch1 > '9' || ch2 < '0' || ch2 > '9')
        {
            return false;
        }
        int value = (ch1 - 48) * 10 + (ch2 - 48);
        if (value < 0 || value > 59)
        {
            return false;
        }
        array[arrayIndex] = value;
        array[0] = pos;
        return true;
    }

    private void parseVariableWidthDigits(string parseText,
            int minDigits, int maxDigits, int[] array)
    {
        // scan the text to find the available number of digits up to maxDigits
        // so long as the number available is minDigits or more, the input is valid
        // then parse the number of available digits
        int pos = array[0];
        int available = 0;
        char[] chars = new char[maxDigits];
        for (int i = 0; i < maxDigits; i++)
        {
            if (pos + 1 > parseText.length)
            {
                break;
            }
            char ch = parseText[pos++];
            if (ch < '0' || ch > '9')
            {
                pos--;
                break;
            }
            chars[i] = ch;
            available++;
        }
        if (available < minDigits)
        {
            array[0] = ~array[0];
            return;
        }
        switch (available)
        {
        case 1:
            array[1] = (chars[0] - 48);
            break;
        case 2:
            array[1] = ((chars[0] - 48) * 10 + (chars[1] - 48));
            break;
        case 3:
            array[1] = (chars[0] - 48);
            array[2] = ((chars[1] - 48) * 10 + (chars[2] - 48));
            break;
        case 4:
            array[1] = ((chars[0] - 48) * 10 + (chars[1] - 48));
            array[2] = ((chars[2] - 48) * 10 + (chars[3] - 48));
            break;
        case 5:
            array[1] = (chars[0] - 48);
            array[2] = ((chars[1] - 48) * 10 + (chars[2] - 48));
            array[3] = ((chars[3] - 48) * 10 + (chars[4] - 48));
            break;
        case 6:
            array[1] = ((chars[0] - 48) * 10 + (chars[1] - 48));
            array[2] = ((chars[2] - 48) * 10 + (chars[3] - 48));
            array[3] = ((chars[4] - 48) * 10 + (chars[5] - 48));
            break;
        default:
            break;
        }
        array[0] = pos;
    }

    override public string toString()
    {
        string converted = noOffsetText.replace("'", "''");
        return "Offset(" ~ PATTERNS[type] ~ ",'" ~ converted ~ "')";
    }
}
