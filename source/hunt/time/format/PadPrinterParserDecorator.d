module hunt.time.format.PadPrinterParserDecorator;

import hunt.time.Exceptions;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.temporal.TemporalField;
import hunt.util.StringBuilder;

import hunt.Exceptions;

import std.conv;

//-----------------------------------------------------------------------
/**
 * Pads the output to a fixed width.
 */
static final class PadPrinterParserDecorator : DateTimePrinterParser
{
    private DateTimePrinterParser printerParser;
    private int padWidth;
    private char padChar;

    /**
     * Constructor.
     *
     * @param printerParser  the printer, not null
     * @param padWidth  the width to pad to, 1 or greater
     * @param padChar  the pad character
     */
    this(DateTimePrinterParser printerParser, int padWidth, char padChar)
    {
        // input checked by DateTimeFormatterBuilder
        this.printerParser = printerParser;
        this.padWidth = padWidth;
        this.padChar = padChar;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        int preLen = buf.length();
        if (printerParser.format(context, buf) == false)
        {
            return false;
        }
        int len = buf.length() - preLen;
        if (len > padWidth)
        {
            throw new DateTimeException("Cannot print as output of " ~ len.to!string
                    ~ " characters exceeds pad width of " ~ padWidth.to!string);
        }
        for (int i = 0; i < padWidth - len; i++)
        {
            buf.insert(preLen, padChar);
        }
        return true;
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        // cache context before changed by decorated parser
        bool strict = context.isStrict();
        // parse
        if (position > text.length)
        {
            throw new IndexOutOfBoundsException();
        }
        if (position == text.length)
        {
            return ~position; // no more characters _in the string
        }
        int endPos = position + padWidth;
        if (endPos > text.length)
        {
            if (strict)
            {
                return ~position; // not enough characters _in the string to meet the parse width
            }
            endPos = cast(int)(text.length);
        }
        int pos = position;
        while (pos < endPos && context.charEquals(text[pos], padChar))
        {
            pos++;
        }
        text = text[0 .. endPos];
        int resultPos = printerParser.parse(context, text, pos);
        if (resultPos != endPos && strict)
        {
            return ~(position + pos); // parse of decorated field didn't parse to the end
        }
        return resultPos;
    }

    override public string toString()
    {
        return "Pad(" ~ printerParser.toString ~ "," ~ padWidth.to!string ~ (padChar == ' '
                ? ")" : ",'" ~ padChar ~ "')");
    }
}
