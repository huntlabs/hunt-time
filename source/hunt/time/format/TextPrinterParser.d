module hunt.time.format.TextPrinterParser;

import hunt.time.chrono.Chronology;
import hunt.time.chrono.Era;
import hunt.time.chrono.IsoChronology;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.DateTimeTextProvider;
import hunt.time.format.NumberPrinterParser;
import hunt.time.format.SignStyle;
import hunt.time.format.TextStyle;

import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.util.QueryHelper;
import hunt.text.StringBuilder;

import hunt.collection.List;
import hunt.collection.Map;
import hunt.Exceptions;
import hunt.Long;
import hunt.util.Common;

import std.conv;

//-----------------------------------------------------------------------
/**
* Prints or parses field text.
*/
static final class TextPrinterParser : DateTimePrinterParser
{
    private TemporalField field;
    private TextStyle textStyle;
    private DateTimeTextProvider provider;
    /**
 * The cached number printer parser.
 * Immutable and volatile, so no synchronization needed.
 */
    private  /* volatile */ NumberPrinterParser _numberPrinterParser;

    /**
 * Constructor.
 *
 * @param field  the field to output, not null
 * @param textStyle  the text style, not null
 * @param provider  the text provider, not null
 */
    this(TemporalField field, TextStyle textStyle, DateTimeTextProvider provider)
    {
        // validated by caller
        this.field = field;
        this.textStyle = textStyle;
        this.provider = provider;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        Long value = context.getValue(field);
        if (value is null)
        {
            return false;
        }
        string text;
        Chronology chrono = QueryHelper.query!Chronology(context.getTemporal(),
                TemporalQueries.chronology());
        if (chrono is null || chrono == IsoChronology.INSTANCE)
        {
            text = provider.getText(field, value.longValue(),
                    textStyle, context.getLocale());
        }
        else
        {
            text = provider.getText(chrono, field, value.longValue(),
                    textStyle, context.getLocale());
        }
        if (text is null)
        {
            return numberPrinterParser().format(context, buf);
        }
        buf.append(text);
        return true;
    }

    override public int parse(DateTimeParseContext context, string parseText, int position)
    {
        int length = cast(int)(parseText.length);
        if (position < 0 || position > length)
        {
            throw new IndexOutOfBoundsException();
        }
        TextStyle style = (context.isStrict() ? textStyle : null);
        Chronology chrono = context.getEffectiveChronology();
        Iterable!(MapEntry!(string, Long)) it;
        if (chrono is null || chrono == IsoChronology.INSTANCE)
        {
            it = provider.getTextIterator(field, style, context.getLocale());
        }
        else
        {
            it = provider.getTextIterator(chrono, field, style, context.getLocale());
        }
        if (it !is null)
        {
            foreach(MapEntry!(string, Long) entry; it)
            {
                string itText = entry.getKey();
                if (context.subSequenceEquals(itText, 0, parseText,
                        position, cast(int)(itText.length)))
                {
                    return context.setParsedField(field, entry.getValue()
                            .longValue(), position, position + cast(int)(itText.length));
                }
            }
            if (field == ChronoField.ERA && !context.isStrict())
            {
                // parse the possible era name from era.toString()
                List!(Era) eras = chrono.eras();
                foreach (Era era; eras)
                {
                    string name = era.toString();
                    if (context.subSequenceEquals(name, 0, parseText,
                            position, cast(int)(name.length)))
                    {
                        return context.setParsedField(field, era.getValue(),
                                position, position + cast(int)(name.length));
                    }
                }
            }
            if (context.isStrict())
            {
                return ~position;
            }
        }
        return numberPrinterParser().parse(context, parseText, position);
    }

    /**
 * Create and cache a number printer parser.
 * @return the number printer parser for this field, not null
 */
    private NumberPrinterParser numberPrinterParser()
    {
        if (_numberPrinterParser is null)
        {
            _numberPrinterParser = new NumberPrinterParser(field, 1, 19, SignStyle.NORMAL);
        }
        return _numberPrinterParser;
    }

    override public string toString()
    {
        if (textStyle == TextStyle.FULL)
        {
            return "Text(" ~ typeid(field).name ~ ")";
        }
        return "Text(" ~ typeid(field).name ~ "," ~ textStyle.ordinal().to!string ~ ")";
    }
}
