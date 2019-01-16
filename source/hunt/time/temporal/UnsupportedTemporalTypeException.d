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

hunt.time.temporal.UnsupportedTemporalTypeException;

import hunt.time.DateTimeException;

/**
 * UnsupportedTemporalTypeException indicates that a ChronoField or ChronoUnit is
 * not supported for a Temporal class.
 *
 * @implSpec
 * This class is intended for use _in a single thread.
 *
 * @since 1.8
 */
public class UnsupportedTemporalTypeException : DateTimeException {

    /**
     * Serialization version.
     */
    private static const long serialVersionUID = -6158898438688206006L;

    /**
     * Constructs a new UnsupportedTemporalTypeException with the specified message.
     *
     * @param message  the message to use for this exception, may be null
     */
    public this(string message) {
        super(message);
    }

    /**
     * Constructs a new UnsupportedTemporalTypeException with the specified message and cause.
     *
     * @param message  the message to use for this exception, may be null
     * @param cause  the cause of the exception, may be null
     */
    public this(string message, Throwable cause) {
        super(message, cause);
    }

}
