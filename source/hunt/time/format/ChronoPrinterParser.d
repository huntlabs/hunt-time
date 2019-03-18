module hunt.time.format.ChronoPrinterParser;

import hunt.time.chrono.Chronology;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.DateTimeTextProvider;
import hunt.time.format.TextStyle;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQueries;
import hunt.time.util.Locale;

import hunt.collection.Set;
import hunt.text.StringBuilder;
import hunt.Exceptions;

//-----------------------------------------------------------------------
/**
* Prints or parses a chronology.
*/
static final class ChronoPrinterParser : DateTimePrinterParser
{
    /** The text style to output, null means the ID. */
    private TextStyle textStyle;

    this(TextStyle textStyle)
    {
        // validated by caller
        this.textStyle = textStyle;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        Chronology chrono = context.getValue(TemporalQueries.chronology());
        if (chrono is null)
        {
            return false;
        }
        if (textStyle is null)
        {
            buf.append(chrono.getId());
        }
        else
        {
            buf.append(getChronologyName(chrono, context.getLocale()));
        }
        return true;
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        // simple looping parser to find the chronology
        if (position < 0 || position > text.length)
        {
            throw new IndexOutOfBoundsException();
        }
        Set!(Chronology) chronos = Chronology.getAvailableChronologies();
        Chronology bestMatch = null;
        int matchLen = -1;
        foreach (Chronology chrono; chronos)
        {
            string name;
            if (textStyle is null)
            {
                name = chrono.getId();
            }
            else
            {
                name = getChronologyName(chrono, context.getLocale());
            }
            int nameLen = cast(int)(name.length);
            if (nameLen > matchLen && context.subSequenceEquals(text,
                    position, name, 0, nameLen))
            {
                bestMatch = chrono;
                matchLen = nameLen;
            }
        }
        if (bestMatch is null)
        {
            return ~position;
        }
        context.setParsed(bestMatch);
        return position + matchLen;
    }

    /**
 * Returns the chronology name of the given chrono _in the given locale
 * if available, or the chronology Id otherwise. The regular ResourceBundle
 * search path is used for looking up the chronology name.
 *
 * @param chrono  the chronology, not null
 * @param locale  the locale, not null
 * @return the chronology name of chrono _in locale, or the id if no name is available
 * @throws NullPointerException if chrono or locale is null
 */
    private string getChronologyName(Chronology chrono, Locale locale)
    {
        string key = "calendarname." ~ chrono.getCalendarType();
        string name = DateTimeTextProvider.getLocalizedResource!string(key, locale);
        return name /* , () => chrono.getId()) */ ;
    }

    override public string toString()
    {
        return super.toString();
    }
}

