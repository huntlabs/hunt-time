module hunt.time.format.CharLiteralPrinterParser;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.temporal.TemporalField;
import hunt.util.StringBuilder;

import std.string;

//-----------------------------------------------------------------------
/**
 * Prints or parses a character literal.
 */
static final class CharLiteralPrinterParser : DateTimePrinterParser
{
    private char literal;

    this(char literal)
    {
        this.literal = literal;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        buf.append(literal);
        return true;
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        int length = cast(int)(text.length);
        if (position == length)
        {
            return ~position;
        }
        char ch = text[position];
        if (ch != literal)
        {
            if (context.isCaseSensitive() || (toUpper(ch) != toUpper(literal)
                    && toUpper(ch) != toUpper(literal)))
            {
                return ~position;
            }
        }
        return position + 1;
    }

    override public string toString()
    {
        if (literal == '\'')
        {
            return "''";
        }
        return "'" ~ literal ~ "'";
    }
}
