module test.DayOfWeekTest;

import hunt.time.DayOfWeek;
import hunt.time.format.TextStyle;
import hunt.time.LocalDate;

import hunt.time.util.Locale;

import std.conv;
import std.stdio;

class DayOfWeekTest {

    void testBasic() {
        // Get DayOfWeek enums value
        DayOfWeek[] dayOfWeeks = DayOfWeek.values();
        for (int i = 0; i < dayOfWeeks.length; i++) {
            DayOfWeek dayOfWeek = dayOfWeeks[i];
            writeln("dayOfWeek[" ~ i.to!string() ~ "] = " ~ dayOfWeek.toString() ~ "; value = " ~ 
                    dayOfWeek.getValue().to!string());
        }

        // Get DayOfWeek from int value
        DayOfWeek dayOfWeek = DayOfWeek.of(1);
        writeln("dayOfWeek = " ~ dayOfWeek.toString());
        assert(dayOfWeek == DayOfWeek.MONDAY);

        // Get DayOfWeek from string value
        dayOfWeek = DayOfWeek.valueOf("SATURDAY");
        writeln("dayOfWeek = " ~ dayOfWeek.toString());
        assert(dayOfWeek == DayOfWeek.SATURDAY);

        // Get DayOfWeek of a date object
        LocalDate date = LocalDate.now();
        DayOfWeek dow = date.getDayOfWeek();

        writeln("Date  = " ~ date.toString());
        writeln("Dow   = " ~ dow.toString() ~ "; value = " ~ dow.getValue().to!string());
        

        // Get DayOfWeek display name in different locale.
        // Locale locale = new Locale("id", "ID");
        // string indonesian = dow.getDisplayName(TextStyle.SHORT, locale);
        // writeln("ID = " ~ indonesian);

        // string germany = dow.getDisplayName(TextStyle.FULL, Locale.GERMANY);
        // writeln("DE = " ~ germany);/

        // Adding number of days to DayOfWeek enum.
        writeln("DayOfWeek.MONDAY.plus(4) = " ~ DayOfWeek.MONDAY.plus(4).toString());

        assert(DayOfWeek.MONDAY.plus(4) == DayOfWeek.FRIDAY);
    }
}