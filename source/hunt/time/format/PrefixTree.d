module hunt.time.format.PrefixTree;

import hunt.time.format.DateTimeParseContext;
import hunt.time.text.ParsePosition;

import hunt.collection.Set;
import hunt.text.Common;
import hunt.util.StringBuilder;

import std.string;

//-----------------------------------------------------------------------
/**
* A string based prefix tree for parsing time-zone names.
*/
static class PrefixTree
{
    protected string key;
    protected string value;
    protected dchar c0; // performance optimization to avoid the
    // boundary check cost of key.charat(0)
    protected PrefixTree child;
    protected PrefixTree sibling;

    private this(string k, string v, PrefixTree child)
    {
        this.key = k;
        this.value = v;
        this.child = child;
        if (k.length == 0)
        {
            c0 = 0xffff;
        }
        else
        {
            c0 = key[0];
        }
    }

    /**
 * Creates a new prefix parsing tree based on parse context.
 *
 * @param context  the parse context
 * @return the tree, not null
 */
    public static PrefixTree newTree(DateTimeParseContext context)
    {
        //if (!context.isStrict()) {
        //    return new LENIENT("", null, null);
        //}
        if (context.isCaseSensitive())
        {
            return new PrefixTree("", null, null);
        }
        return new CI("", null, null);
    }

    /**
 * Creates a new prefix parsing tree.
 *
 * @param keys  a set of strings to build the prefix parsing tree, not null
 * @param context  the parse context
 * @return the tree, not null
 */
    public static PrefixTree newTree(Set!(string) keys, DateTimeParseContext context)
    {
        PrefixTree tree = newTree(context);
        foreach (string k; keys)
        {
            tree.add0(k, k);
        }
        return tree;
    }

    /**
 * Clone a copy of this tree
 */
    public PrefixTree copyTree()
    {
        PrefixTree copy = new PrefixTree(key, value, null);
        if (child !is null)
        {
            copy.child = child.copyTree();
        }
        if (sibling !is null)
        {
            copy.sibling = sibling.copyTree();
        }
        return copy;
    }

    /**
 * Adds a pair of {key, value} into the prefix tree.
 *
 * @param k  the key, not null
 * @param v  the value, not null
 * @return  true if the pair is added successfully
 */
    public bool add(string k, string v)
    {
        return add0(k, v);
    }

    private bool add0(string k, string v)
    {
        k = toKey(k);
        int prefixLen = prefixLength(k);
        if (prefixLen == key.length)
        {
            if (prefixLen < k.length)
            { // down the tree
                string subKey = k.substring(prefixLen);
                PrefixTree c = child;
                while (c !is null)
                {
                    if (isEqual(c.c0, subKey[0]))
                    {
                        return c.add0(subKey, v);
                    }
                    c = c.sibling;
                }
                // add the node as the child of the current node
                c = newNode(subKey, v, null);
                c.sibling = child;
                child = c;
                return true;
            }
            // have an existing !(key, value) already, overwrite it
            // if (value !is null) {
            //    return false;
            //}
            value = v;
            return true;
        }
        // split the existing node
        PrefixTree n1 = newNode(key.substring(prefixLen), value, child);
        key = k.substring(0, prefixLen);
        child = n1;
        if (prefixLen < k.length)
        {
            PrefixTree n2 = newNode(k.substring(prefixLen), v, null);
            child.sibling = n2;
            value = null;
        }
        else
        {
            value = v;
        }
        return true;
    }

    /**
 * Match text with the prefix tree.
 *
 * @param text  the input text to parse, not null
 * @param off  the offset position to start parsing at
 * @param end  the end position to stop parsing
 * @return the resulting string, or null if no match found.
 */
    public string match(string text, int off, int end)
    {
        if (!prefixOf(text, off, end))
        {
            return null;
        }
        if (child !is null && (off += key.length) != end)
        {
            PrefixTree c = child;
            do
            {
                if (isEqual(c.c0, text[off]))
                {
                    string found = c.match(text, off, end);
                    if (found !is null)
                    {
                        return found;
                    }
                    return value;
                }
                c = c.sibling;
            }
            while (c !is null);
        }
        return value;
    }

    /**
 * Match text with the prefix tree.
 *
 * @param text  the input text to parse, not null
 * @param pos  the position to start parsing at, from 0 to the text
 *  length. Upon return, position will be updated to the new parse
 *  position, or unchanged, if no match found.
 * @return the resulting string, or null if no match found.
 */
    public string match(string text, ParsePosition pos)
    {
        int off = pos.getIndex();
        int end = cast(int)(text.length);
        if (!prefixOf(text, off, end))
        {
            return null;
        }
        off += key.length;
        if (child !is null && off != end)
        {
            PrefixTree c = child;
            do
            {
                if (isEqual(c.c0, text[off]))
                {
                    pos.setIndex(off);
                    string found = c.match(text, pos);
                    if (found !is null)
                    {
                        return found;
                    }
                    break;
                }
                c = c.sibling;
            }while (c !is null);
        }
        pos.setIndex(off);
        return value;
    }

    protected string toKey(string k)
    {
        return k;
    }

    protected PrefixTree newNode(string k, string v, PrefixTree child)
    {
        return new PrefixTree(k, v, child);
    }

    protected bool isEqual(dchar c1, char c2)
    {
        return cast(char) c1 == c2;
    }

    protected bool isEqual(char c1, char c2)
    {
        return c1 == c2;
    }

    protected bool prefixOf(string text, int off, int end)
    {
        if (cast(string)(text) !is null)
        {
            return (cast(string) text).startsWith(key, off) > 0 ? true : false;
        }
        int len = cast(int)(key.length);
        if (len > end - off)
        {
            return false;
        }
        int off0 = 0;
        while (len-- > 0)
        {
            if (!isEqual(key[off0++], text[off++]))
            {
                return false;
            }
        }
        return true;
    }

    private int prefixLength(string k)
    {
        int off = 0;
        while (off < k.length && off < key.length)
        {
            if (!isEqual(k[off], key[off]))
            {
                return off;
            }
            off++;
        }
        return off;
    }

    /**
 * Case Insensitive prefix tree.
 */
    private static class CI : PrefixTree
    {

        private this(string k, string v, PrefixTree child)
        {
            super(k, v, child);
        }

        override protected CI newNode(string k, string v, PrefixTree child)
        {
            return new CI(k, v, child);
        }

        override protected bool isEqual(char c1, char c2)
        {
            return DateTimeParseContext.charEqualsIgnoreCase(c1, c2);
        }

        override protected bool isEqual(dchar c1, char c2)
        {
            return DateTimeParseContext.charEqualsIgnoreCase(cast(char) c1, c2);
        }

        override protected bool prefixOf(string text, int off, int end)
        {
            int len = cast(int)(key.length);
            if (len > end - off)
            {
                return false;
            }
            int off0 = 0;
            while (len-- > 0)
            {
                if (!isEqual(key[off0++], text[off++]))
                {
                    return false;
                }
            }
            return true;
        }
    }

    /**
 * Lenient prefix tree. Case insensitive and ignores characters
 * like space, underscore and slash.
 */
    private static class LENIENT : CI
    {

        private this(string k, string v, PrefixTree child)
        {
            super(k, v, child);
        }

        override protected CI newNode(string k, string v, PrefixTree child)
        {
            return new LENIENT(k, v, child);
        }

        private bool isLenientChar(char c)
        {
            return c == ' ' || c == '_' || c == '/';
        }

        override protected string toKey(string k)
        {
            for (int i = 0; i < k.length; i++)
            {
                if (isLenientChar(k[i]))
                {
                    StringBuilder sb = new StringBuilder(k.length);
                    sb.append(k, 0, i);
                    i++;
                    while (i < k.length)
                    {
                        if (!isLenientChar(k[i]))
                        {
                            sb.append(k[i]);
                        }
                        i++;
                    }
                    return sb.toString();
                }
            }
            return k;
        }

        override public string match(string text, ParsePosition pos)
        {
            int off = pos.getIndex();
            int end = cast(int)(text.length);
            int len = cast(int)(key.length);
            int koff = 0;
            while (koff < len && off < end)
            {
                if (isLenientChar(text[off]))
                {
                    off++;
                    continue;
                }
                if (!isEqual(key[koff++], text[off++]))
                {
                    return null;
                }
            }
            if (koff != len)
            {
                return null;
            }
            if (child !is null && off != end)
            {
                int off0 = off;
                while (off0 < end && isLenientChar(text[off0]))
                {
                    off0++;
                }
                if (off0 < end)
                {
                    PrefixTree c = child;
                    do
                    {
                        if (isEqual(c.c0, text[off0]))
                        {
                            pos.setIndex(off0);
                            string found = c.match(text, pos);
                            if (found !is null)
                            {
                                return found;
                            }
                            break;
                        }
                        c = c.sibling;
                    }
                    while (c !is null);
                }
            }
            pos.setIndex(off);
            return value;
        }
    }
}