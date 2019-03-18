module hunt.time.format.StringLiteralPrinterParser;

import hunt.time.chrono.Chronology;
import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.DateTimeTextProvider;
import hunt.time.format.TextStyle;
import hunt.time.temporal.TemporalField;

import hunt.text.Common;
import hunt.text.StringBuilder;

import hunt.Exceptions;
import hunt.Long;

import std.string;

//-----------------------------------------------------------------------
/**
 * Prints or parses a string literal.
 */
static final class StringLiteralPrinterParser : DateTimePrinterParser
{
    private string literal;

    this(string literal)
    {
        this.literal = literal; // validated by caller
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        buf.append(literal);
        return true;
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        int length = cast(int)(text.length);
        if (position > length || position < 0)
        {
            throw new IndexOutOfBoundsException();
        }
        if (context.subSequenceEquals(text, position, literal, 0,
                cast(int)(literal.length)) == false)
        {
            return ~position;
        }
        return position + cast(int)(literal.length);
    }

    override public string toString()
    {
        string converted = literal.replace("'", "''");
        return "'" ~ converted ~ "'";
    }
}

