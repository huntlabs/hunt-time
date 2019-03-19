module test.TestTimeZone;

import hunt.time;
import hunt.logging;
import std.stdio;
import test.common;


class TestTimeZone {

    static void test()
    {
        test_zoneid();
        test_now();
        test_parse();
    }

    static void test_zoneid()
    {
        mixin(DO_TEST);

        ZoneId id = ZoneRegion.of("Asia/Shanghai");
        ZonedDateTime zoned = ZonedDateTime.of(LocalDateTime.now(), id);
        trace("ZoneRegion.of(\"Asia/Shanghai\") : ", ZoneRegion.of("Asia/Shanghai"));
        trace("ZonedDateTime.of(LocalDateTime.now(), id) : ",ZonedDateTime.of(LocalDateTime.now(), id));
    }


    static void test_now()
    {
        mixin(DO_TEST);

        trace("ZonedDateTime.now() : ",ZonedDateTime.now());
    }

    static void test_parse()
    {
        mixin(DO_TEST);

        // auto zdt  = ZonedDateTime.parse("2007-12-03T10:15:30+08:00[GMT+08:00]");
        // trace("parse : ",zdt);
    }
}