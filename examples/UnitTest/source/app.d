import std.stdio;
import hunt.logging.ConsoleLogger;
import hunt.util.UnitTest;
import hunt.util.DateTime;

import std.string;
import core.thread;

import test.DayOfWeekTest;
import test.TestLocalDateTime;
import test.TestLocalTime;
import test.TestLocalDate;
import test.TestMonthDay;
import test.TestTimeZone;
import test.TestInstant;


void main()
{
	// trace("Test Time.");

	// new Thread({ Thread.sleep(1.seconds); TestLocalTime.test(); }).start();
	// new Thread({ Thread.sleep(1.seconds); TestLocalDate.test(); }).start();
	// new Thread({ Thread.sleep(2.seconds); TestLocalDateTime.test(); }).start();
	// new Thread({ Thread.sleep(3.seconds); testUnits!(TestMonthDay); }).start();

	// TestTimeZone.test();
	// TestInstant.test();

	// testUnits!DayOfWeekTest();
	testStdTime();
}

void testStdTime() {
	import hunt.time.LocalDateTime;
	import hunt.time.ZoneOffset;
	import hunt.time.Instant;

	import core.time;
	import std.datetime;
	long t = Clock.currStdTime;
	LocalDateTime ldt;
	trace("std time: ", t);
	SysTime st = SysTime(t);
	trace("local time: ", st.toString());
	trace("unix timestamp(seconds): ", st.toUnixTime());
	trace("Unix timestamp(milliseconds): ", DateTimeHelper.currentTimeMillis());

	// trace(SysTime(63690574746246*10000).toString());

	import core.stdc.time;
	immutable unixTimeC = core.stdc.time.time(null);
	trace("unix time from system: ", unixTimeC);


	ldt = LocalDateTime.now();
	tracef("%d", ldt.toEpochMilli());
	tracef("%d", ldt.atZone(ZoneOffset.of("+8"))
            .toInstant()
            .toEpochMilli());
	trace("=======================");
	long d = 1555315608921L;
	ldt = LocalDateTime.ofEpochMilli(d);
	tracef("%d", ldt.toEpochMilli());
	assert(ldt.toEpochMilli() == d);
	Instant inst = ldt.toInstant(ZoneOffset.UTC);
	trace(inst.getNano());
}
