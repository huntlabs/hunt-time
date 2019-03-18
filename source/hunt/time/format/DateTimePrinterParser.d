module hunt.time.format.DateTimePrinterParser;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrintContext;
import hunt.time.temporal.TemporalField;
import hunt.text.StringBuilder;

//-----------------------------------------------------------------------
/**
 * Strategy for formatting/parsing date-time information.
 * !(p)
 * The printer may format any part, or the whole, of the input date-time object.
 * Typically, a complete format is constructed from a number of smaller
 * units, each outputting a single field.
 * !(p)
 * The parser may parse any piece of text from the input, storing the result
 * _in the context. Typically, each individual parser will just parse one
 * field, such as the day-of-month, storing the value _in the context.
 * Once the parse is complete, the caller will then resolve the parsed values
 * to create the desired object, such as a {@code LocalDate}.
 * !(p)
 * The parse position will be updated during the parse. Parsing will start at
 * the specified index and the return value specifies the new parse position
 * for the next parser. If an error occurs, the returned index will be negative
 * and will have the error position encoded using the complement operator.
 *
 * @implSpec
 * This interface must be implemented with care to ensure other classes operate correctly.
 * All implementations that can be instantiated must be final, immutable and thread-safe.
 * !(p)
 * The context is not a thread-safe object and a new instance will be created
 * for each format that occurs. The context must not be stored _in an instance
 * variable or shared with any other threads.
 */
interface DateTimePrinterParser
{

    /**
     * Prints the date-time object to the buffer.
     * !(p)
     * The context holds information to use during the format.
     * It also contains the date-time information to be printed.
     * !(p)
     * The buffer must not be mutated beyond the content controlled by the implementation.
     *
     * @param context  the context to format using, not null
     * @param buf  the buffer to append to, not null
     * @return false if unable to query the value from the date-time, true otherwise
     * @throws DateTimeException if the date-time cannot be printed successfully
     */
    bool format(DateTimePrintContext context, StringBuilder buf);

    /**
     * Parses text into date-time information.
     * !(p)
     * The context holds information to use during the parse.
     * It is also used to store the parsed date-time information.
     *
     * @param context  the context to use and parse into, not null
     * @param text  the input text to parse, not null
     * @param position  the position to start parsing at, from 0 to the text length
     * @return the new parse position, where negative means an error with the
     *  error position encoded using the complement ~ operator
     * @throws NullPointerException if the context or text is null
     * @throws IndexOutOfBoundsException if the position is invalid
     */
    int parse(DateTimeParseContext context, string text, int position);

    string toString();
}


//-----------------------------------------------------------------------
/**
 * Defaults a value into the parse if not currently present.
 */
static class DefaultValueParser : DateTimePrinterParser
{
    private TemporalField field;
    private long value;

    this(TemporalField field, long value)
    {
        this.field = field;
        this.value = value;
    }

    public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        return true;
    }

    public int parse(DateTimeParseContext context, string text, int position)
    {
        if (context.getParsed(field) is null)
        {
            context.setParsedField(field, value, position, position);
        }
        return position;
    }

    override public string toString()
    {
        return super.toString();
    }
} 