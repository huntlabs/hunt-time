[![Build Status](https://travis-ci.org/huntlabs/hunt-time.svg?branch=master)](https://travis-ci.org/huntlabs/hunt-time)

## About hunt-time
hunt-time is a time library and similar to [Joda-time](https://www.joda.org/joda-time/quickstart.html) and [Java.time](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/time/package-summary.html) api.

## Features

 * LocalDate - date without time
 * LocalTime - time without date
 * Instant - an instantaneous point on the time-line
 * DateTime - full date and time with time-zone
 * DateTimeZone - a better time-zone
 * Duration and Period - amounts of time
 * Interval - the time between two instants
 * A comprehensive and flexible formatter-parser

## LocalDate/LocalTime/LocalDateTime
LocalDate, a date API that represents a date without time; LocalTime, a time representation without a date; and LocalDateTime, which is a combination of the previous two. All of these types represent the local date and/or time for a region, but,they contain zero information about the zone in which it is represented, only a representation of the date and time in your current timezone.

First of all, these APIs support an easy instantiation:

```D
LocalDate date = LocalDate.of(2018,2,13);
// Uses DateTimeformatter.ISO_LOCAL_DATE for which the format is: yyyy-MM-dd
LocalDate date = LocalDate.parse("2018-02-13");
LocalTime time = LocalTime.of(6,30);
// Uses DateTimeFormatter.ISO_LOCAL_TIME for which the format is: HH:mm[:ss[.SSSSSSSSS]]
// this means that both seconds and nanoseconds may optionally be present.
LocalTime time = LocalTime.parse("06:30");
LocalDateTime dateTime = LocalDateTime.of(2018,2,13,6,30);
// Uses DateTimeFormatter.ISO_LOCAL_DATE_TIME for which the format is the
// combination of the ISO date and time format, joined by 'T': yyyy-MM-dd'T'HH:mm[:ss[.SSSSSSSSS]]
LocalDateTime dateTime = LocalDateTime.parse("2018-02-13T06:30");
```

It’s easy to convert between them:

```D
// LocalDate to LocalDateTime
LocalDateTime dateTime = LocalDate.parse("2018-02-13").atTime(LocalTime.parse("06:30"));
// LocalTime to LocalDateTime
LocalDateTime dateTime = LocalTime.parse("06:30").atDate(LocalDate.parse("2018-02-13"));
// LocalDateTime to LocalDate/LocalTime
LocalDate date = LocalDateTime.parse("2018-02-13T06:30").toLocalDate();
LocalTime time = LocalDateTime.parse("2018-02-13T06:30").toLocalTime();
```

Aside from that, it’s incredibly easy to perform operations on our date and time representations, using the `plus` and `minus` methods as well as some utility functions:

```D
LocalDate date = LocalDate.parse("2018-02-13").plusDays(5);
LocalDate date = LocalDate.parse("2018-02-13").plus(3, ChronoUnit.MONTHS);
LocalTime time = LocalTime.parse("06:30").minusMinutes(30);
LocalTime time = LocalTime.parse("06:30").minus(500, ChronoUnit.MILLIS);
LocalDateTime dateTime = LocalDateTime.parse("2018-02-13T06:30").plus(Duration.ofHours(2));
// using TemporalAdjusters, which implements a few useful cases:
LocalDate date = LocalDate.parse("2018-02-13").with(TemporalAdjusters.lastDayOfMonth());
````

### Difference in Time: Duration and Period
As you’ve noticed, in one of the above examples we’ve used a Duration object. Duration and Period are two representations of time between two dates, the former representing the difference of time in seconds and nanoseconds, the latter in days, months and years.

When should you use these? Period when you need to know the difference in time between two LocalDaterepresentations:

```D
Period period = Period.between(LocalDate.parse("2018-01-18"), LocalDate.parse("2018-02-14"));
```

Duration when you’re looking for a difference between a representation that holds time information:

```D
Duration duration = Duration.between(LocalDateTime.parse("2018-01-18T06:30"), LocalDateTime.parse("2018-02-14T22:58"));
```

When outputting Period or Duration using toString(), a special format will be used based on ISO-8601 standard. The pattern used for a Period is PnYnMnD, where n defines the number of years, months or days present within the period. This means that P1Y2M3D defines a period of 1 year, 2 months, and 3 days. The ‘P’ in the pattern is the period designator, which tells us that the following format represents a period. Using the pattern, we can also create a period based on a string using the parse() method.

```D
// represents a period of 27 days
Period period = Period.parse("P27D");
```

When using Durations, we move away slightly from the ISO-8601 standard. The pattern defined by ISO-8601 is PnYnMnDTnHnMn.nS. This is basically the Period pattern, extended with a time representation. In the pattern, T is the time designator, so the part that follows defines a duration specified in hours, minutes and seconds.

Last but not least, we can also retrieve the various parts of a period or duration, by using the corresponding method on a type. However, it’s important to know that the various datetime types also support this through the use of ChronoUnit enumeration type. Let’s take a look at some examples:

```D
// represents PT664H28M
Duration duration = Duration.between(LocalDateTime.parse("2018-01-18T06:30"), LocalDateTime.parse("2018-02-14T22:58"));
// returns 664
long hours = duration.toHours();
// returns 664
long hours = LocalDateTime.parse("2018-01-18T06:30").until(LocalDateTime.parse("2018-02-14T22:58"), ChronoUnit.HOURS);
```

## Working With Zones and Offsets: ZondedDateTime and OffsetDateTime
Thus far, we’ve shown how the new date APIs have made a few things a little easier. What really makes a difference, however, is the ability to easily use date and time in a timezone context. Hunt.time provides us with ZonedDateTime and OffsetDateTime, the first one being a LocalDateTime with information for a specific Zone (e.g. Europe/Paris), the second one being a LocalDateTime with an offset. What’s the difference? OffsetDateTime uses a fixed time difference between UTC/Greenwich and the date that is specified, whilst ZonedDateTime specifies the zone in which the time is represented, and will take daylight saving time into account.

Converting to either of these types is very easy:
```D
OffsetDateTime offsetDateTime = LocalDateTime.parse("2018-02-14T06:30").atOffset(ZoneOffset.ofHours(2));
// Uses DateTimeFormatter.ISO_OFFSET_DATE_TIME for which the default format is
// ISO_LOCAL_DATE_TIME followed by the offset ("+HH:mm:ss").
OffsetDateTime offsetDateTime = OffsetDateTime.parse("2018-02-14T06:30+06:00");
ZonedDateTime zonedDateTime = LocalDateTime.parse("2018-02-14T06:30").atZone(ZoneId.of("Europe/Paris"));
// Uses DateTimeFormatter.ISO_ZONED_DATE_TIME for which the default format is
// ISO_OFFSET_DATE_TIME followed by the the ZoneId in square brackets.
ZonedDateTime zonedDateTime = ZonedDateTime.parse("2018-02-14T06:30+08:00[Asia/Macau]");
// note that the offset does not matter in this case.
// The following example will also return an offset of +08:00
ZonedDateTime zonedDateTime = ZonedDateTime.parse("2018-02-14T06:30+06:00[Asia/Macau]");
```

When switching between them, you have to keep in mind that converting from a ZonedDateTime to OffsetDateTimewill take daylight saving time into account, while converting in the other direction, from OffsetDateTime to ZonedDateTime, means you will not have information about the region of the zone, nor will there be any rules applied for daylight saving time. That is because an offset does not define any time zone rules, nor is it bound to a specific region.
```D
ZonedDateTime winter = LocalDateTime.parse("2018-01-14T06:30").atZone(ZoneId.of("Europe/Paris"));
ZonedDateTime summer = LocalDateTime.parse("2018-08-14T06:30").atZone(ZoneId.of("Europe/Paris"));
// offset will be +01:00
OffsetDateTime offsetDateTime = winter.toOffsetDateTime();
// offset will be +02:00
OffsetDateTime offsetDateTime = summer.toOffsetDateTime();
OffsetDateTime offsetDateTime = zonedDateTime.toOffsetDateTime();
OffsetDateTime offsetDateTime = LocalDateTime.parse("2018-02-14T06:30").atOffset(ZoneOffset.ofHours(5));
ZonedDateTime zonedDateTime = offsetDateTime.toZonedDateTime();
```
### TODO
- [ ] Improve formatter
- [ ] More unit tests