module hunt.time.format.ZoneIdPrinterParser;

import hunt.time.Exceptions;

import hunt.time.format.DateTimeParseContext;
import hunt.time.format.DateTimePrinterParser;
import hunt.time.format.DateTimePrintContext;
import hunt.time.format.OffsetIdPrinterParser;
import hunt.time.format.PrefixTree;
import hunt.time.temporal.ChronoField;
import hunt.time.temporal.TemporalField;
import hunt.time.temporal.TemporalQuery;
import hunt.time.text.ParsePosition;
import hunt.time.util.Common;
import hunt.time.ZoneId;
import hunt.time.ZoneOffset;
import hunt.time.zone.Helper;
import hunt.text.StringBuilder;

import hunt.Exceptions;
import hunt.Integer;
import hunt.collection.AbstractMap;
import hunt.collection.Map;
import hunt.collection.Set;

import std.string;


//-----------------------------------------------------------------------
/**
* Prints or parses a zone ID.
*/
static class ZoneIdPrinterParser : DateTimePrinterParser
{
    private TemporalQuery!(ZoneId) query;
    private string description;

    this(TemporalQuery!(ZoneId) query, string description)
    {
        this.query = query;
        this.description = description;
    }

    override public bool format(DateTimePrintContext context, StringBuilder buf)
    {
        ZoneId zone = context.getValue(query);
        if (zone is null)
        {
            return false;
        }
        buf.append(zone.getId());
        return true;
    }

    /**
 * The cached tree to speed up parsing.
 */
    private __gshared MapEntry!(Integer, PrefixTree) cachedPrefixTree;
    private __gshared MapEntry!(Integer, PrefixTree) cachedPrefixTreeCI;

    protected PrefixTree getTree(DateTimeParseContext context)
    {
        // prepare parse tree
        Set!(string) regionIds = ZoneRulesHelper.getAvailableZoneIds();
        int regionIdsSize = regionIds.size();
        MapEntry!(Integer, PrefixTree) cached = context.isCaseSensitive()
            ? cachedPrefixTree : cachedPrefixTreeCI;
        if (cached is null || cached.getKey() != regionIdsSize)
        {
            synchronized (this)
            {
                cached = context.isCaseSensitive() ? cachedPrefixTree : cachedPrefixTreeCI;
                if (cached is null || cached.getKey() != regionIdsSize)
                {
                    cached = new SimpleImmutableEntry!(Integer, PrefixTree)(new Integer(regionIdsSize),
                            PrefixTree.newTree(regionIds, context));
                    if (context.isCaseSensitive())
                    {
                        cachedPrefixTree = cached;
                    }
                    else
                    {
                        cachedPrefixTreeCI = cached;
                    }
                }
            }
        }
        return cached.getValue();
    }

    /**
 * This implementation looks for the longest matching string.
 * For example, parsing Etc/GMT-2 will return Etc/GMC-2 rather than just
 * Etc/GMC although both are valid.
 */
    override public int parse(DateTimeParseContext context, string text, int position)
    {
        int length = cast(int)(text.length);
        if (position > length)
        {
            throw new IndexOutOfBoundsException();
        }
        if (position == length)
        {
            return ~position;
        }

        // handle fixed time-zone IDs
        char nextChar = text[position];
        if (nextChar == '+' || nextChar == '-')
        {
            return parseOffsetBased(context, text, position, position,
                    OffsetIdPrinterParser.INSTANCE_ID_Z);
        }
        else if (length >= position + 2)
        {
            char nextNextChar = text[position + 1];
            if (context.charEquals(nextChar, 'U') && context.charEquals(nextNextChar, 'T'))
            {
                if (length >= position + 3
                        && context.charEquals(text[position + 2], 'C'))
                {
                    return parseOffsetBased(context, text, position,
                            position + 3, OffsetIdPrinterParser.INSTANCE_ID_ZERO);
                }
                return parseOffsetBased(context, text, position,
                        position + 2, OffsetIdPrinterParser.INSTANCE_ID_ZERO);
            }
            else if (context.charEquals(nextChar, 'G') && length >= position + 3
                    && context.charEquals(nextNextChar, 'M')
                    && context.charEquals(text[position + 2], 'T'))
            {
                if (length >= position + 4
                        && context.charEquals(text[position + 3], '0'))
                {
                    context.setParsed(ZoneId.of("GMT0"));
                    return position + 4;
                }
                return parseOffsetBased(context, text, position,
                        position + 3, OffsetIdPrinterParser.INSTANCE_ID_ZERO);
            }
        }

        // parse
        PrefixTree tree = getTree(context);
        ParsePosition ppos = new ParsePosition(position);
        string parsedZoneId = tree.match(text, ppos);
        if (parsedZoneId is null)
        {
            if (context.charEquals(nextChar, 'Z'))
            {
                context.setParsed(ZoneOffset.UTC);
                return position + 1;
            }
            return ~position;
        }
        context.setParsed(ZoneId.of(parsedZoneId));
        return ppos.getIndex();
    }

    /**
 * Parse an offset following a prefix and set the ZoneId if it is valid.
 * To matching the parsing of ZoneId.of the values are not normalized
 * to ZoneOffsets.
 *
 * @param context the parse context
 * @param text the input text
 * @param prefixPos start of the prefix
 * @param position start of text after the prefix
 * @param parser parser for the value after the prefix
 * @return the position after the parse
 */
    private int parseOffsetBased(DateTimeParseContext context, string text,
            int prefixPos, int position, OffsetIdPrinterParser parser)
    {
        string prefix = toUpper(cast(string)(text[prefixPos .. position]));
        if (position >= text.length)
        {
            context.setParsed(ZoneId.of(prefix));
            return position;
        }

        // '0' or 'Z' after prefix is not part of a valid ZoneId; use bare prefix
        if (text[position] == '0' || context.charEquals(text[position], 'Z'))
        {
            context.setParsed(ZoneId.of(prefix));
            return position;
        }

        DateTimeParseContext newContext = context.copy();
        int endPos = parser.parse(newContext, text, position);
        try
        {
            if (endPos < 0)
            {
                if (parser == OffsetIdPrinterParser.INSTANCE_ID_Z)
                {
                    return ~prefixPos;
                }
                context.setParsed(ZoneId.of(prefix));
                return position;
            }
            int offset = cast(int) newContext.getParsed(ChronoField.OFFSET_SECONDS)
                .longValue();
            ZoneOffset zoneOffset = ZoneOffset.ofTotalSeconds(offset);
            context.setParsed(ZoneId.ofOffset(prefix, zoneOffset));
            return endPos;
        }
        catch (DateTimeException dte)
        {
            return ~prefixPos;
        }
    }

    override public string toString()
    {
        return description;
    }
}
