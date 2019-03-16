/*
 * hunt-time: A time library for D programming language.
 *
 * Copyright (C) 2015-2018 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.time.chrono.JapaneseEra;

// import hunt.time.chrono.JapaneseDate;
// import hunt.time.temporal.ChronoField;

// import hunt.io.DataInput;
// import hunt.io.DataOutput;
// import hunt.Exceptions;

// //import hunt.io.ObjectInputStream;
// // import hunt.io.ObjectStreamException;
// import hunt.io.Common;
// import hunt.time.Exceptions;
// import hunt.time.LocalDate;
// import hunt.time.format.DateTimeFormatterBuilder;
// import hunt.time.format.TextStyle;
// import hunt.time.temporal.ChronoField;
// import hunt.time.temporal.TemporalField;
// import hunt.time.Exceptions;
// import hunt.time.temporal.ValueRange;
// //import hunt.concurrent.ConcurrentMap;;
// import hunt.time.util.Locale;
// import hunt.time.chrono.Era;

// // import sun.util.calendar.CalendarDate;

// /**
//  * An era _in the Japanese Imperial calendar system.
//  * !(p)
//  * This class defines the valid eras for the Japanese chronology.
//  * Japan introduced the Gregorian calendar starting with Meiji 6.
//  * Only Meiji and later eras are supported;
//  * dates before Meiji 6, January 1 are not supported.
//  * The number of the valid eras may increase, as new eras may be
//  * defined by the Japanese government. Once an era is defined,
//  * subsequent versions of this class will add a singleton instance
//  * for it. The defined era is expected to have a consecutive integer
//  * associated with it.
//  *
//  * @implSpec
//  * This class is immutable and thread-safe.
//  *
//  * @since 1.8
//  */
// public final class JapaneseEra
//         : Era, Serializable {

//     // The offset value to 0-based index from the era value.
//     // i.e., getValue() + ERA_OFFSET == 0-based index
//     static final int ERA_OFFSET = 2;

//     static final sun.util.calendar.Era[] ERA_CONFIG;

//     /**
//      * The singleton instance for the 'Meiji' era (1868-01-01 - 1912-07-29)
//      * which has the value -1.
//      */
//     public static final JapaneseEra MEIJI = new JapaneseEra(-1, LocalDate.of(1868, 1, 1));
//     /**
//      * The singleton instance for the 'Taisho' era (1912-07-30 - 1926-12-24)
//      * which has the value 0.
//      */
//     public static final JapaneseEra TAISHO = new JapaneseEra(0, LocalDate.of(1912, 7, 30));
//     /**
//      * The singleton instance for the 'Showa' era (1926-12-25 - 1989-01-07)
//      * which has the value 1.
//      */
//     public static final JapaneseEra SHOWA = new JapaneseEra(1, LocalDate.of(1926, 12, 25));
//     /**
//      * The singleton instance for the 'Heisei' era (1989-01-08 - 2019-04-30)
//      * which has the value 2.
//      */
//     public static final JapaneseEra HEISEI = new JapaneseEra(2, LocalDate.of(1989, 1, 8));
//     /**
//      * The singleton instance for the 'NewEra' era (2019-05-01 - current)
//      * which has the value 3.
//      */
//     private static final JapaneseEra NEWERA = new JapaneseEra(3, LocalDate.of(2019, 5, 1));

//     // The number of predefined JapaneseEra constants.
//     // There may be a supplemental era defined by the property.
//     private static final int N_ERA_CONSTANTS = NEWERA.getValue() + ERA_OFFSET;

//     /**
//      * Serialization version.
//      */
//     private static final long serialVersionUID = 1466499369062886794L;

//     // array for the singleton JapaneseEra instances
//     private static final JapaneseEra[] KNOWN_ERAS;

//     static this(){
//         ERA_CONFIG = JapaneseChronology.JCAL.getEras();

//         KNOWN_ERAS = new JapaneseEra[ERA_CONFIG.length];
//         KNOWN_ERAS[0] = MEIJI;
//         KNOWN_ERAS[1] = TAISHO;
//         KNOWN_ERAS[2] = SHOWA;
//         KNOWN_ERAS[3] = HEISEI;
//         KNOWN_ERAS[4] = NEWERA;
//         for (int i = N_ERA_CONSTANTS; i < ERA_CONFIG.length; i++) {
//             CalendarDate date = ERA_CONFIG[i].getSinceDate();
//             LocalDate isoDate = LocalDate.of(date.getYear(), date.getMonth(), date.getDayOfMonth());
//             KNOWN_ERAS[i] = new JapaneseEra(i - ERA_OFFSET + 1, isoDate);
//         }
//     };

//     /**
//      * The era value.
//      * @serial
//      */
//     private final /*transient*/ int eraValue;

//     // the first day of the era
//     private final /*transient*/ LocalDate since;

//     /**
//      * Creates an instance.
//      *
//      * @param eraValue  the era value, validated
//      * @param since  the date representing the first date of the era, validated not null
//      */
//     private this(int eraValue, LocalDate since) {
//         this.eraValue = eraValue;
//         this.since = since;
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Returns the Sun private Era instance corresponding to this {@code JapaneseEra}.
//      *
//      * @return the Sun private Era instance for this {@code JapaneseEra}.
//      */
//     sun.util.calendar.Era getPrivateEra() {
//         return ERA_CONFIG[ordinal(eraValue)];
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Obtains an instance of {@code JapaneseEra} from an {@code int} value.
//      * !(p)
//      * The {@link #SHOWA} era that contains 1970-01-01 (ISO calendar system) has the value 1.
//      * Later era is numbered 2 ({@link #HEISEI}). Earlier eras are numbered 0 ({@link #TAISHO}),
//      * -1 ({@link #MEIJI}), only Meiji and later eras are supported.
//      * !(p)
//      * In addition to the known era singletons, values for additional
//      * eras may be defined. Those values are the {@link Era#getValue()}
//      * of corresponding eras from the {@link #values()} method.
//      *
//      * @param japaneseEra  the era to represent
//      * @return the {@code JapaneseEra} singleton, not null
//      * @throws DateTimeException if the value is invalid
//      */
//     public static JapaneseEra of(int japaneseEra) {
//         int i = ordinal(japaneseEra);
//         if (i < 0 || i >= KNOWN_ERAS.length) {
//             throw new DateTimeException("Invalid era: " ~ japaneseEra);
//         }
//         return KNOWN_ERAS[i];
//     }

//     /**
//      * Returns the {@code JapaneseEra} with the name.
//      * !(p)
//      * The string must match exactly the name of the era.
//      * (Extraneous whitespace characters are not permitted.)
//      * !(p)
//      * Valid era names are the names of eras returned from {@link #values()}.
//      *
//      * @param japaneseEra  the japaneseEra name; non-null
//      * @return the {@code JapaneseEra} singleton, never null
//      * @throws IllegalArgumentException if there is not JapaneseEra with the specified name
//      */
//     public static JapaneseEra valueOf(string japaneseEra) {
//         assert(japaneseEra, "japaneseEra");
//         foreach(JapaneseEra era ; KNOWN_ERAS) {
//             if (era.getName().equals(japaneseEra)) {
//                 return era;
//             }
//         }
//         throw new IllegalArgumentException("japaneseEra is invalid");
//     }

//     /**
//      * Returns an array of JapaneseEras. The array may contain eras defined
//      * by the Japanese government beyond the known era singletons.
//      *
//      * !(p)
//      * This method may be used to iterate over the JapaneseEras as follows:
//      * !(pre)
//      * foreach(JapaneseEra c ; JapaneseEra.values())
//      *     System._out.println(c);
//      * </pre>
//      *
//      * @return an array of JapaneseEras
//      */
//     public static JapaneseEra[] values() {
//         return Arrays.copyOf(KNOWN_ERAS, KNOWN_ERAS.length);
//     }

//     /**
//      * {@inheritDoc}
//      *
//      * @param style {@inheritDoc}
//      * @param locale {@inheritDoc}
//      */
//     override
//     public string getDisplayName(TextStyle style, Locale locale) {
//         // If this JapaneseEra is a supplemental one, obtain the name from
//         // the era definition.
//         if (getValue() > N_ERA_CONSTANTS - ERA_OFFSET) {
//             assert(locale, "locale");
//             return style.asNormal() == TextStyle.NARROW ? getAbbreviation() : getName();
//         }

//         return new DateTimeFormatterBuilder()
//             .appendText(ERA, style)
//             .toFormatter(locale)
//             .withChronology(JapaneseChronology.INSTANCE)
//             .format(this == MEIJI ? MEIJI_6_ISODATE : since);
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Obtains an instance of {@code JapaneseEra} from a date.
//      *
//      * @param date  the date, not null
//      * @return the Era singleton, never null
//      */
//     static JapaneseEra from(LocalDate date) {
//         if (date.isBefore(MEIJI_6_ISODATE)) {
//             throw new DateTimeException("JapaneseDate before Meiji 6 are not supported");
//         }
//         for (int i = KNOWN_ERAS.length - 1; i > 0; i--) {
//             JapaneseEra era = KNOWN_ERAS[i];
//             if (date.compareTo(era.since) >= 0) {
//                 return era;
//             }
//         }
//         return null;
//     }

//     static JapaneseEra toJapaneseEra(sun.util.calendar.Era privateEra) {
//         for (int i = ERA_CONFIG.length - 1; i >= 0; i--) {
//             if (ERA_CONFIG[i].equals(privateEra)) {
//                 return KNOWN_ERAS[i];
//             }
//         }
//         return null;
//     }

//     static sun.util.calendar.Era privateEraFrom(LocalDate isoDate) {
//         for (int i = KNOWN_ERAS.length - 1; i > 0; i--) {
//             JapaneseEra era = KNOWN_ERAS[i];
//             if (isoDate.compareTo(era.since) >= 0) {
//                 return ERA_CONFIG[i];
//             }
//         }
//         return null;
//     }

//     /**
//      * Returns the index into the arrays from the Era value.
//      * the eraValue is a valid Era number, -1..2.
//      *
//      * @param eraValue  the era value to convert to the index
//      * @return the index of the current Era
//      */
//     private static int ordinal(int eraValue) {
//         return eraValue + ERA_OFFSET - 1;
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the numeric era {@code int} value.
//      * !(p)
//      * The {@link #SHOWA} era that contains 1970-01-01 (ISO calendar system) has the value 1.
//      * Later eras are numbered from 2 ({@link #HEISEI}).
//      * Earlier eras are numbered 0 ({@link #TAISHO}), -1 ({@link #MEIJI})).
//      *
//      * @return the era value
//      */
//     override
//     public int getValue() {
//         return eraValue;
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Gets the range of valid values for the specified field.
//      * !(p)
//      * The range object expresses the minimum and maximum valid values for a field.
//      * This era is used to enhance the accuracy of the returned range.
//      * If it is not possible to return the range, because the field is not supported
//      * or for some other reason, an exception is thrown.
//      * !(p)
//      * If the field is a {@link ChronoField} then the query is implemented here.
//      * The {@code ERA} field returns the range.
//      * All other {@code ChronoField} instances will throw an {@code UnsupportedTemporalTypeException}.
//      * !(p)
//      * If the field is not a {@code ChronoField}, then the result of this method
//      * is obtained by invoking {@code TemporalField.rangeRefinedBy(TemporalAccessor)}
//      * passing {@code this} as the argument.
//      * Whether the range can be obtained is determined by the field.
//      * !(p)
//      * The range of valid Japanese eras can change over time due to the nature
//      * of the Japanese calendar system.
//      *
//      * @param field  the field to query the range for, not null
//      * @return the range of valid values for the field, not null
//      * @throws DateTimeException if the range for the field cannot be obtained
//      * @throws UnsupportedTemporalTypeException if the unit is not supported
//      */
//     override  // override as super would return range from 0 to 1
//     public ValueRange range(TemporalField field) {
//         if (field == ERA) {
//             return JapaneseChronology.INSTANCE.range(ERA);
//         }
//         return /* Era. */super.range(field);
//     }

//     //-----------------------------------------------------------------------
//     string getAbbreviation() {
//         return ERA_CONFIG[ordinal(getValue())].getAbbreviation();
//     }

//     string getName() {
//         return ERA_CONFIG[ordinal(getValue())].getName();
//     }

//     override
//     public string toString() {
//         return getName();
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Defend against malicious streams.
//      *
//      * @param s the stream to read
//      * @throws InvalidObjectException always
//      */
//     private void readObject(ObjectInputStream s) /*throws InvalidObjectException*/ {
//         throw new InvalidObjectException("Deserialization via serialization delegate");
//     }

//     //-----------------------------------------------------------------------
//     /**
//      * Writes the object using a
//      * <a href="{@docRoot}/serialized-form.html#hunt.time.chrono.Ser">dedicated serialized form</a>.
//      * @serialData
//      * !(pre)
//      *  _out.writeByte(5);        // identifies a JapaneseEra
//      *  _out.writeInt(getValue());
//      * </pre>
//      *
//      * @return the instance of {@code Ser}, not null
//      */
//     private Object writeReplace() {
//         return new Ser(Ser.JAPANESE_ERA_TYPE, this);
//     }

//     void writeExternal(DataOutput _out) /*throws IOException*/ {
//         _out.writeByte(this.getValue());
//     }

//     static JapaneseEra readExternal(DataInput _in) /*throws IOException*/ {
//         byte eraValue = _in.readByte();
//         return JapaneseEra.of(eraValue);
//     }

// }
