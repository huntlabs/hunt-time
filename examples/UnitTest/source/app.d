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

	testUnits!DayOfWeekTest();
	testStdTime();
}

void testStdTime() {
	import hunt.time.LocalDateTime;
	import hunt.time.ZoneOffset;
	import hunt.time.Instant;
	import hunt.time.Month;
	import hunt.time.ZoneId;
	import hunt.time.ZoneRegion;
	import hunt.time.ZoneOffset;
	import hunt.time.OffsetDateTime;


	import core.time;
	import std.datetime : Clock, SysTime;
	long t = Clock.currStdTime;
	LocalDateTime ldt;
	trace("std time: ", t);
	SysTime st = SysTime(t);
	long unixTime = st.toUnixTime();
	trace("local time: ", st.toString());
	trace("unix timestamp(seconds): ", unixTime);
	trace("Unix timestamp(milliseconds): ", DateTimeHelper.currentTimeMillis());
	// trace(SysTime(63690574746246*10000).toString());

	import core.stdc.time;
	immutable unixTimeC = core.stdc.time.time(null);
	trace("unix time from system: ", unixTimeC);

	ldt = LocalDateTime.ofEpochMilli(unixTime*1000);
	tracef("EpochMilli from unix timestamp: %d", ldt.toEpochMilli());
	
	// https://stackoverflow.com/questions/41427384/how-to-get-default-zoneoffset-in-java8
	ldt = LocalDateTime.ofEpochSecond(unixTime, 0,  ZoneOffset.of("+8"));
	tracef("EpochMilli from unix timestamp: %d", ldt.toEpochMilli());

	OffsetDateTime odt = OffsetDateTime.now ();
	ZoneOffset zoneOffset = odt.getOffset();
	trace("zoneOffset: ", zoneOffset.toString());
	ldt = LocalDateTime.ofEpochSecond(unixTime, 0, zoneOffset);
	tracef("EpochMilli from unix timestamp: %d", ldt.toEpochMilli());
	info("=======================");



	ldt = LocalDateTime.now();
	tracef("EpochMilli: %d", ldt.toEpochMilli());
	tracef("EpochMilli: %d", ldt.atZone(ZoneOffset.of("+8"))
            .toInstant()
            .toEpochMilli());
	info("=======================");
	long d = 1555315608921L;
	ldt = LocalDateTime.ofEpochMilli(d);
	tracef("%d", ldt.toEpochMilli());
	assert(ldt.toEpochMilli() == d);
	Instant inst = ldt.toInstant(ZoneOffset.UTC);
	trace(inst.getNano());

	LocalDateTime specificDate = LocalDateTime.of(2014, Month.JANUARY, 1, 10, 10, 30);
	trace(specificDate.toString());
	trace(specificDate.toEpochMilli());
	assert(specificDate.toInstant(ZoneOffset.of("+8")).toEpochMilli() == 1388542230000L);

	ZoneId ar = ZoneRegion.systemDefault();
	trace(ar);

	ZoneOffset zid = ZoneOffset.of("+8");
	trace(zid);

	Instant instant = Instant.now(); //can be LocalDateTime
	ZoneId systemZone = ZoneRegion.systemDefault(); // my timezone
	ZoneOffset currentOffsetForMyZone = systemZone.getRules().getOffset(instant);
	trace(currentOffsetForMyZone);

}
