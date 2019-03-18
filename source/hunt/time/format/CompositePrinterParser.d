module hunt.time.format.CompositePrinterParser;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.temporal.TemporalField;
import hunt.text.StringBuilder;

import hunt.collection.List;

//-----------------------------------------------------------------------
/**
 * Composite printer and parser.
 */
static final class CompositePrinterParser : DateTimePrinterParser
{
    private DateTimePrinterParser[] printerParsers;
    private bool optional;

    this(List!(DateTimePrinterParser) printerParsers, bool optional)
    {
        auto a = printerParsers.toArray()/* new DateTimePrinterParser[printerParsers.size()] */;
        // foreach (l; printerParsers)
        // {
        //     if(l is null)
        //     {
        //         version(HUNT_DEBUG) trace("is null");
        //     }
        //     version(HUNT_DEBUG) trace("----> :",(cast(Object)(l)).toString);
        //     a ~= l;
        // }
        // foreach(p ; a)
        // {
        //     if(p is null)
        //     {
        //         import hunt.logging;
        //         version(HUNT_DEBUG) trace("is null");
        //     }
        // }
        this(a, optional);
    }

    this(DateTimePrinterParser[] printerParsers, bool optional)
    {
        this.printerParsers = printerParsers;
        // foreach(p ; this.printerParsers)
        // {
        //     if(p is null)
        //     {
        //         import hunt.logging;
        //         version(HUNT_DEBUG) trace("is null");
        //     }
        // }
        this.optional = optional;
    }

    /**
     * Returns a copy of this printer-parser with the optional flag changed.
     *
     * @param optional  the optional flag to set _in the copy
     * @return the new printer-parser, not null
     */
    public CompositePrinterParser withOptional(bool optional)
    {
        if (optional == this.optional)
        {
            return this;
        }
        return new CompositePrinterParser(printerParsers, optional);
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        int length = buf.length();
        if (optional)
        {
            context.startOptional();
        }
        try
        {
            foreach (DateTimePrinterParser pp; printerParsers)
            {
                if (pp.format(context, buf) == false)
                {
                    buf.setLength(length); // reset buffer
                    return true;
                }
            }
        }
        finally
        {
            if (optional)
            {
                context.endOptional();
            }
        }
        return true;
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        if (optional)
        {
            context.startOptional();
            int pos = position;
            foreach (DateTimePrinterParser pp; printerParsers)
            {
                pos = pp.parse(context, text, pos);
                if (pos < 0)
                {
                    context.endOptional(false);
                    return position; // return original position
                }
            }
            context.endOptional(true);
            return pos;
        }
        else
        {
            foreach (DateTimePrinterParser pp; printerParsers)
            {
                position = pp.parse(context, text, position);
                if (position < 0)
                {
                    break;
                }
            }
            return position;
        }
    }

    override public string toString()
    {
        StringBuilder buf = new StringBuilder();
        if (printerParsers !is null)
        {
            buf.append(optional ? "[" : "(");
            foreach (DateTimePrinterParser pp; printerParsers)
            {
                buf.append(pp.toString);
            }
            buf.append(optional ? "]" : ")");
        }
        return buf.toString();
    }
}
