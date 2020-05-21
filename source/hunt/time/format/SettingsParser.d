module hunt.time.format.SettingsParser;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.temporal.TemporalField;
import hunt.util.StringBuilder;

import hunt.time.util.Common;

import hunt.Exceptions;

//-----------------------------------------------------------------------
/**
 * Enumeration to apply simple parse settings.
 */
static class SettingsParser : DateTimePrinterParser
{
    // static SettingsParser SENSITIVE;
    // static SettingsParser INSENSITIVE;
    // static SettingsParser STRICT;
    // static SettingsParser LENIENT;

    private int _ordinal;
    int ordinal()
    {
        return _ordinal;
    }

    // static this()
    // {
        // SENSITIVE = new SettingsParser(0);
        mixin(MakeGlobalVar!(SettingsParser)("SENSITIVE",`new SettingsParser(0)`));
        // INSENSITIVE = new SettingsParser(1);
        mixin(MakeGlobalVar!(SettingsParser)("INSENSITIVE",`new SettingsParser(1)`));
        // STRICT = new SettingsParser(2);
        mixin(MakeGlobalVar!(SettingsParser)("STRICT",`new SettingsParser(2)`));

        // LENIENT = new SettingsParser(3);
        mixin(MakeGlobalVar!(SettingsParser)("LENIENT",`new SettingsParser(3)`));

    // }

    this(int ordinal)
    {
        _ordinal = ordinal;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        return true; // nothing to do here
    }

    override public int parse(DateTimeParseContext context, string text, int position)
    {
        // using ordinals to avoid javac synthetic inner class
        switch (ordinal())
        {
        case 0:
            context.setCaseSensitive(true);
            break;
        case 1:
            context.setCaseSensitive(false);
            break;
        case 2:
            context.setStrict(true);
            break;
        case 3:
            context.setStrict(false);
            break;
        default:
            break;
        }
        return position;
    }

    override public string toString()
    {
        // using ordinals to avoid javac synthetic inner class
        switch (ordinal())
        {
        case 0:
            return "ParseCaseSensitive(true)";
        case 1:
            return "ParseCaseSensitive(false)";
        case 2:
            return "ParseStrict(true)";
        case 3:
            return "ParseStrict(false)";
        default:
            break;
        }
        throw new IllegalStateException("Unreachable");
    }
}

